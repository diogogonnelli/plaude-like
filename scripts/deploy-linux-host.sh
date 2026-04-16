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
BACKEND_SERVICE_NAME="${BACKEND_SERVICE_NAME:-sonora-backend}"
BACKEND_PORT="${BACKEND_PORT:-8787}"
BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"
RELOAD_NGINX="${RELOAD_NGINX:-0}"
DEFAULT_SERVICE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
POST_HOOK="${POST_HOOK:-/home/spotti/post-deploy.sh}"

CURRENT_DIR="$APP_ROOT/current"
SHARED_DIR="$APP_ROOT/shared"
DIST_APP_DIR="$APP_ROOT/dist-app"
DIST_ADMIN_DIR="$APP_ROOT/dist-admin"
SHARED_ENV_FILE="$SHARED_DIR/backend.env"
UPLOADS_DIR="$SHARED_DIR/uploads"
LOGS_DIR="$SHARED_DIR/logs"
PIDFILE="$SHARED_DIR/backend.pid"
BACKEND_DIR="$CURRENT_DIR/backend"
LOCAL_NODE_BIN="$BACKEND_DIR/.runtime/node/bin/node"

log() {
  printf '[%s] %s\n' "$(date +%F' '%T)" "$*"
}

check_backend_health() {
  curl --fail --silent --show-error "http://${BACKEND_HOST}:${BACKEND_PORT}/health" >/dev/null
}

wait_for_backend_health() {
  local attempts="${1:-10}" sleep_seconds="${2:-3}" try=1

  while [ "$try" -le "$attempts" ]; do
    if check_backend_health; then
      return 0
    fi

    if [ "$try" -lt "$attempts" ]; then
      sleep "$sleep_seconds"
    fi

    try=$((try + 1))
  done

  return 1
}

print_service_diagnostics() {
  log "Collecting backend service diagnostics for '$BACKEND_SERVICE_NAME'."

  systemctl status --no-pager "$BACKEND_SERVICE_NAME" 2>&1 || true
  systemctl --user status --no-pager "$BACKEND_SERVICE_NAME" 2>&1 || true

  if command -v sudo >/dev/null 2>&1; then
    sudo -n /bin/systemctl status --no-pager "$BACKEND_SERVICE_NAME" 2>&1 || true
    sudo -n /usr/bin/systemctl status --no-pager "$BACKEND_SERVICE_NAME" 2>&1 || true
  fi
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

require_bundled_node_runtime() {
  local node_version node_major

  require_file "$LOCAL_NODE_BIN"
  chmod +x "$LOCAL_NODE_BIN"

  node_version="$("$LOCAL_NODE_BIN" --version)"
  node_major="$("$LOCAL_NODE_BIN" -p "process.versions.node.split('.')[0]")"
  log "Using bundled node: $LOCAL_NODE_BIN ($node_version)"

  if [ "$node_major" -lt 20 ]; then
    log "ERROR: bundled Node.js $node_version is below the required major version."
    exit 20
  fi
}

run_systemctl() {
  local output="" systemctl_bin=""

  if output="$(systemctl "$@" 2>&1)"; then
    return 0
  fi

  if output="$(systemctl --user "$@" 2>&1)"; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    for systemctl_bin in /bin/systemctl /usr/bin/systemctl; do
      if [ -x "$systemctl_bin" ] && sudo -n "$systemctl_bin" "$@" >/dev/null 2>&1; then
        return 0
      fi
    done

    if sudo -n systemctl "$@" >/dev/null 2>&1; then
      return 0
    fi
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

provision_user_service() {
  local user_service_dir="$HOME/.config/systemd/user"
  local service_file="$user_service_dir/${BACKEND_SERVICE_NAME}.service"

  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

  mkdir -p "$user_service_dir" 2>/dev/null || return 1

  cat > "$service_file" <<UNIT
[Unit]
Description=Sonora backend API
After=network.target

[Service]
Type=simple
WorkingDirectory=$BACKEND_DIR
EnvironmentFile=$SHARED_ENV_FILE
ExecStart=/bin/bash -c 'exec $LOCAL_NODE_BIN $BACKEND_DIR/dist/server.js'
Restart=always
RestartSec=3
StandardOutput=append:$LOGS_DIR/backend.log
StandardError=append:$LOGS_DIR/backend.log

[Install]
WantedBy=default.target
UNIT

  if ! systemctl --user daemon-reload 2>/dev/null; then
    log "Warning: user systemd daemon-reload failed."
    rm -f "$service_file"
    return 1
  fi

  systemctl --user enable "$BACKEND_SERVICE_NAME" 2>/dev/null || true
  loginctl enable-linger "$(whoami)" 2>/dev/null || true

  if ! systemctl --user restart "$BACKEND_SERVICE_NAME" 2>/dev/null; then
    log "Warning: user systemd restart failed."
    return 1
  fi

  log "Backend started via user systemd service. Verifying..."
  sleep 3

  if systemctl --user is-active --quiet "$BACKEND_SERVICE_NAME" 2>/dev/null; then
    log "User systemd service is active."
    return 0
  fi

  log "Warning: user systemd service exited immediately. Checking logs..."
  systemctl --user status --no-pager "$BACKEND_SERVICE_NAME" 2>&1 || true
  systemctl --user stop "$BACKEND_SERVICE_NAME" 2>/dev/null || true
  return 1
}

stop_backend_process() {
  if [ -f "$PIDFILE" ]; then
    local old_pid
    old_pid=$(cat "$PIDFILE" 2>/dev/null || echo "")
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      kill "$old_pid" 2>/dev/null || true
      local i=0
      while [ "$i" -lt 10 ] && kill -0 "$old_pid" 2>/dev/null; do
        sleep 0.5
        i=$((i + 1))
      done
      if kill -0 "$old_pid" 2>/dev/null; then
        kill -9 "$old_pid" 2>/dev/null || true
      fi
    fi
    rm -f "$PIDFILE"
  fi

  if command -v fuser >/dev/null 2>&1; then
    fuser -k "${BACKEND_PORT}/tcp" 2>/dev/null || true
    sleep 1
  fi
}

start_backend_direct() {
  stop_backend_process
  log "Starting backend as detached process (PID file: $PIDFILE)."

  set -a
  . "$SHARED_ENV_FILE"
  set +a

  pushd "$BACKEND_DIR" > /dev/null
  nohup "$LOCAL_NODE_BIN" dist/server.js >> "$LOGS_DIR/backend.log" 2>&1 &
  echo $! > "$PIDFILE"
  disown $! 2>/dev/null || true
  popd > /dev/null
}

restart_backend() {
  if run_systemctl restart "$BACKEND_SERVICE_NAME" 2>/dev/null; then
    log "Backend restarted via systemctl."
    return 0
  fi

  log "System service not available. Trying user-level systemd service."
  if provision_user_service; then
    return 0
  fi

  log "User systemd not available. Starting backend as detached process."
  start_backend_direct
  return 0
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
upsert_env "$SHARED_ENV_FILE" "PATH" "$BACKEND_DIR/.runtime/node/bin:$DEFAULT_SERVICE_PATH"
if [ -n "$APP_DOMAIN" ]; then
  upsert_env "$SHARED_ENV_FILE" "APP_BASE_URL" "https://${APP_DOMAIN}/api"
else
  log "APP_DOMAIN not provided. Preserving existing APP_BASE_URL in shared/backend.env."
fi
upsert_env "$SHARED_ENV_FILE" "TRUST_PROXY" "true"

ln -sfn "$SHARED_ENV_FILE" "$BACKEND_DIR/.env"

require_file "$BACKEND_ARCHIVE"

log "Publishing backend runtime artifact"
rm -rf "$BACKEND_DIR/.runtime" "$BACKEND_DIR/dist" "$BACKEND_DIR/node_modules"
tar -xzf "$BACKEND_ARCHIVE" -C "$BACKEND_DIR"
rm -f "$BACKEND_ARCHIVE"
require_bundled_node_runtime
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

SERVICE_RESTARTED=0
HOOK_EXECUTED=0

if [ -x "$POST_HOOK" ]; then
  log "Running post-deploy hook"
  HOOK_EXECUTED=1
  if "$POST_HOOK" "$APP_ROOT"; then
    SERVICE_RESTARTED=1
  else
    log "Warning: post-deploy hook failed."
    log "Check $POST_HOOK on the host."
  fi
else
  log "Post-deploy hook not found at $POST_HOOK."
  log "Trying direct service restart for '$BACKEND_SERVICE_NAME'."
  if restart_backend; then
    SERVICE_RESTARTED=1
  else
    log "Warning: could not restart backend service automatically."
  fi

  if [ "$RELOAD_NGINX" = "1" ]; then
    log "Reloading nginx"
    if ! run_systemctl reload nginx; then
      log "Warning: could not reload nginx automatically."
      log "Reload nginx manually or handle it inside $POST_HOOK."
    fi
  fi
fi

log "Running smoke checks"
test -f "$DIST_APP_DIR/index.html"
test -f "$DIST_ADMIN_DIR/index.html"

if wait_for_backend_health 5 2; then
  log "Backend health check passed."
elif [ "$HOOK_EXECUTED" = "1" ]; then
  log "Backend is still down after post-deploy hook. Trying alternative restart strategies."
  if restart_backend; then
    SERVICE_RESTARTED=1
    if [ "$RELOAD_NGINX" = "1" ]; then
      log "Reloading nginx"
      run_systemctl reload nginx 2>/dev/null || true
    fi
  else
    log "Warning: all restart strategies failed."
  fi

  if ! wait_for_backend_health 10 3; then
    print_service_diagnostics
    log "ERROR: backend health check failed after deploy."
    exit 40
  fi
elif [ "$SERVICE_RESTARTED" = "1" ]; then
  print_service_diagnostics
  log "ERROR: backend health check failed after automatic restart."
  exit 41
else
  log "Skipping backend health check because no automatic restart was performed."
fi

if [ -n "$APP_DOMAIN" ] || [ -n "$ADMIN_DOMAIN" ]; then
  log "Deploy finished successfully for ${APP_DOMAIN:-app-domain-not-set} and ${ADMIN_DOMAIN:-admin-domain-not-set}"
else
  log "Deploy finished successfully."
fi
