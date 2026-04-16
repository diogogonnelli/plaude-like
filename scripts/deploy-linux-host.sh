#!/usr/bin/env bash
set -Eeuo pipefail

APP_ROOT="${APP_ROOT:-/storage-apps/www/sonora}"
REPO_URL="${REPO_URL:?REPO_URL is required}"
BRANCH="${BRANCH:-main}"
BACKEND_ARCHIVE="${BACKEND_ARCHIVE:?BACKEND_ARCHIVE is required}"
APP_ARCHIVE="${APP_ARCHIVE:?APP_ARCHIVE is required}"
ADMIN_ARCHIVE="${ADMIN_ARCHIVE:?ADMIN_ARCHIVE is required}"
APP_DOMAIN="${APP_DOMAIN:-}"
ADMIN_DOMAIN="${ADMIN_DOMAIN:-}"
BACKEND_SERVICE_NAME="${BACKEND_SERVICE_NAME:-plaude-like-backend}"
BACKEND_PORT="${BACKEND_PORT:-8787}"
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"
RELOAD_NGINX="${RELOAD_NGINX:-0}"

CURRENT_DIR="$APP_ROOT/current"
SHARED_DIR="$APP_ROOT/shared"
DIST_APP_DIR="$APP_ROOT/dist-app"
DIST_ADMIN_DIR="$APP_ROOT/dist-admin"
SHARED_ENV_FILE="$SHARED_DIR/backend.env"
UPLOADS_DIR="$SHARED_DIR/uploads"
LOGS_DIR="$SHARED_DIR/logs"
BACKEND_DIR="$CURRENT_DIR/backend"

log() {
  printf '[%s] %s\n' "$(date +%F' '%T)" "$*"
}

ensure_dir_ready() {
  local path="$1"
  local label="$2"
  local current_user current_group

  current_user="$(id -un)"
  current_group="$(id -gn)"

  if [ ! -d "$path" ]; then
    if ! mkdir -p "$path"; then
      log "ERROR: cannot create ${label} at $path."
      log "Ensure $(dirname "$path") exists and is writable by ${current_user}:${current_group}."
      exit 10
    fi
  fi

  if [ ! -w "$path" ]; then
    log "ERROR: ${label} is not writable: $path"
    log "Fix on server with: sudo chown -R ${current_user}:${current_group} '$APP_ROOT'"
    exit 11
  fi
}

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    log "ERROR: expected file not found: $path"
    exit 1
  fi
}

require_node_runtime() {
  local node_bin node_version node_major

  if command -v node >/dev/null 2>&1; then
    node_bin="$(command -v node)"
  else
    for candidate in /usr/local/bin/node /usr/bin/node; do
      if [ -x "$candidate" ]; then
        export PATH="$(dirname "$candidate"):$PATH"
        node_bin="$candidate"
        break
      fi
    done
  fi

  if [ -z "${node_bin:-}" ]; then
    log "ERROR: node not found on host."
    log "Install Node.js 20+ on the server and ensure it is available to systemd and the deploy user."
    exit 20
  fi

  node_version="$("$node_bin" --version)"
  node_major="$("$node_bin" -p "process.versions.node.split('.')[0]")"
  log "Using node: $node_bin ($node_version)"

  if [ "$node_major" -lt 20 ]; then
    log "ERROR: Node.js $node_version found, but backend requires Node.js >=20."
    log "Update the host runtime and the systemd service to use Node.js 20+ before deploying."
    exit 21
  fi
}

run_systemctl() {
  if systemctl "$@" >/dev/null 2>&1; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    sudo -n systemctl "$@"
    return $?
  fi

  if [ "$(id -u)" -eq 0 ]; then
    systemctl "$@"
    return $?
  fi

  return 1
}

upsert_env() {
  local file="$1"
  local key="$2"
  local value="$3"

  if grep -q "^${key}=" "$file"; then
    sed -i "s#^${key}=.*#${key}=${value}#" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

ensure_dir_ready "$APP_ROOT" "app root"
ensure_dir_ready "$SHARED_DIR" "shared directory"
ensure_dir_ready "$DIST_APP_DIR" "app dist directory"
ensure_dir_ready "$DIST_ADMIN_DIR" "admin dist directory"
ensure_dir_ready "$UPLOADS_DIR" "uploads directory"
ensure_dir_ready "$LOGS_DIR" "logs directory"

if [ ! -d "$CURRENT_DIR/.git" ]; then
  log "Initializing repository in $CURRENT_DIR"
  rm -rf "$CURRENT_DIR"
  git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$CURRENT_DIR"
else
  log "Syncing repository to origin/$BRANCH"
  git -C "$CURRENT_DIR" fetch origin "$BRANCH" --prune
  git -C "$CURRENT_DIR" checkout -B "$BRANCH" "origin/$BRANCH"
  git -C "$CURRENT_DIR" reset --hard "origin/$BRANCH"
  git -C "$CURRENT_DIR" clean -fd
fi

require_file "$CURRENT_DIR/backend/.env.example"

if [ ! -f "$SHARED_ENV_FILE" ]; then
  log "Creating shared backend environment from backend/.env.example"
  cp "$CURRENT_DIR/backend/.env.example" "$SHARED_ENV_FILE"
fi

upsert_env "$SHARED_ENV_FILE" "HOST" "$BACKEND_HOST"
upsert_env "$SHARED_ENV_FILE" "PORT" "$BACKEND_PORT"
if [ -n "$APP_DOMAIN" ]; then
  upsert_env "$SHARED_ENV_FILE" "APP_BASE_URL" "https://${APP_DOMAIN}/api"
else
  log "APP_DOMAIN not provided. Preserving existing APP_BASE_URL in shared/backend.env."
fi
upsert_env "$SHARED_ENV_FILE" "TRUST_PROXY" "true"

ln -sfn "$SHARED_ENV_FILE" "$BACKEND_DIR/.env"

require_file "$BACKEND_ARCHIVE"
require_node_runtime

log "Publishing backend runtime artifact"
rm -rf "$BACKEND_DIR/dist" "$BACKEND_DIR/node_modules"
tar -xzf "$BACKEND_ARCHIVE" -C "$BACKEND_DIR"
rm -f "$BACKEND_ARCHIVE"
require_file "$BACKEND_DIR/dist/server.js"
test -d "$BACKEND_DIR/node_modules"

require_file "$APP_ARCHIVE"
require_file "$ADMIN_ARCHIVE"

log "Publishing frontend artifacts"
rm -rf "$DIST_APP_DIR"/*
rm -rf "$DIST_ADMIN_DIR"/*
tar -xzf "$APP_ARCHIVE" -C "$DIST_APP_DIR"
tar -xzf "$ADMIN_ARCHIVE" -C "$DIST_ADMIN_DIR"
rm -f "$APP_ARCHIVE" "$ADMIN_ARCHIVE"
require_file "$DIST_APP_DIR/index.html"
require_file "$DIST_ADMIN_DIR/index.html"

log "Restarting backend service"
if ! run_systemctl restart "$BACKEND_SERVICE_NAME"; then
  log "ERROR: cannot restart backend service '$BACKEND_SERVICE_NAME' without interactive sudo."
  log "Allow passwordless sudo for 'systemctl restart $BACKEND_SERVICE_NAME' or run the deploy as a privileged user."
  exit 30
fi

if [ "$RELOAD_NGINX" = "1" ]; then
  log "Reloading nginx"
  if ! run_systemctl reload nginx; then
    log "ERROR: cannot reload nginx without interactive sudo."
    log "Allow passwordless sudo for 'systemctl reload nginx' or set RELOAD_NGINX=0."
    exit 31
  fi
fi

log "Running smoke checks"
curl --fail --silent --show-error "http://${BACKEND_HOST}:${BACKEND_PORT}/health" >/dev/null
test -f "$DIST_APP_DIR/index.html"
test -f "$DIST_ADMIN_DIR/index.html"

if [ -n "$APP_DOMAIN" ] || [ -n "$ADMIN_DOMAIN" ]; then
  log "Deploy finished successfully for ${APP_DOMAIN:-app-domain-not-set} and ${ADMIN_DOMAIN:-admin-domain-not-set}"
else
  log "Deploy finished successfully."
fi
