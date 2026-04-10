#!/usr/bin/env bash
set -Eeuo pipefail

APP_ROOT="${APP_ROOT:-/srv/plaude-like}"
REPO_URL="${REPO_URL:?REPO_URL is required}"
BRANCH="${BRANCH:-main}"
APP_ARCHIVE="${APP_ARCHIVE:?APP_ARCHIVE is required}"
ADMIN_ARCHIVE="${ADMIN_ARCHIVE:?ADMIN_ARCHIVE is required}"
APP_DOMAIN="${APP_DOMAIN:-}"
ADMIN_DOMAIN="${ADMIN_DOMAIN:-}"
BACKEND_SERVICE_NAME="${BACKEND_SERVICE_NAME:-plaude-like-backend}"
BACKEND_PORT="${BACKEND_PORT:-8787}"
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"

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

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    log "ERROR: expected file not found: $path"
    exit 1
  fi
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

mkdir -p "$APP_ROOT" "$SHARED_DIR" "$DIST_APP_DIR" "$DIST_ADMIN_DIR" "$UPLOADS_DIR" "$LOGS_DIR"

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

log "Installing backend dependencies"
cd "$BACKEND_DIR"
npm ci
npm run build
npm prune --omit=dev
require_file "$BACKEND_DIR/dist/server.js"

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
sudo systemctl enable "$BACKEND_SERVICE_NAME" >/dev/null 2>&1 || true
sudo systemctl restart "$BACKEND_SERVICE_NAME"
sudo systemctl reload nginx

log "Running smoke checks"
curl --fail --silent --show-error "http://${BACKEND_HOST}:${BACKEND_PORT}/health" >/dev/null
test -f "$DIST_APP_DIR/index.html"
test -f "$DIST_ADMIN_DIR/index.html"

if [ -n "$APP_DOMAIN" ] || [ -n "$ADMIN_DOMAIN" ]; then
  log "Deploy finished successfully for ${APP_DOMAIN:-app-domain-not-set} and ${ADMIN_DOMAIN:-admin-domain-not-set}"
else
  log "Deploy finished successfully."
fi
