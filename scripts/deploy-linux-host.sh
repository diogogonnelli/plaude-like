#!/usr/bin/env bash
set -Eeuo pipefail

APP_ROOT="${APP_ROOT:-/storage-apps/www/sonora}"
REPO_URL="${REPO_URL:?REPO_URL is required}"
BRANCH="${BRANCH:-main}"
BACKEND_ARCHIVE="${BACKEND_ARCHIVE:?BACKEND_ARCHIVE is required}"
APP_ARCHIVE="${APP_ARCHIVE:?APP_ARCHIVE is required}"
APP_DOMAIN="${APP_DOMAIN:-}"
RELOAD_NGINX="${RELOAD_NGINX:-0}"
PHP_FPM_SERVICE="${PHP_FPM_SERVICE:-php8.2-fpm}"
POST_HOOK="${POST_HOOK:-/home/spotti/post-deploy.sh}"

CURRENT_DIR="$APP_ROOT/current"
SHARED_DIR="$APP_ROOT/shared"
DIST_APP_DIR="$APP_ROOT/dist-app"
BACKEND_DIR="$CURRENT_DIR/backend-laravel"
SHARED_ENV_FILE="$SHARED_DIR/.env"
STORAGE_DIR="$SHARED_DIR/storage"
LOGS_DIR="$SHARED_DIR/logs"

log() {
  printf '[%s] %s\n' "$(date +%F' '%T)" "$*"
}

run_systemctl() {
  local output="" systemctl_bin=""

  if output="$(systemctl "$@" 2>&1)"; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    for systemctl_bin in /bin/systemctl /usr/bin/systemctl; do
      if [ -x "$systemctl_bin" ] && sudo -n "$systemctl_bin" "$@" >/dev/null 2>&1; then
        return 0
      fi
    done
  fi

  return 1
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
      exit 10
    fi
  fi

  if [ ! -w "$path" ]; then
    log "ERROR: ${label} is not writable: $path"
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

# ── Prepare directories ──
ensure_dir_ready "$APP_ROOT" "app root"
ensure_dir_ready "$SHARED_DIR" "shared directory"
ensure_dir_ready "$DIST_APP_DIR" "app dist directory"
ensure_dir_ready "$LOGS_DIR" "logs directory"
ensure_dir_ready "$STORAGE_DIR" "shared storage"
ensure_dir_ready "$STORAGE_DIR/app/recordings" "recordings storage"
ensure_dir_ready "$STORAGE_DIR/framework/cache" "framework cache"
ensure_dir_ready "$STORAGE_DIR/framework/sessions" "framework sessions"
ensure_dir_ready "$STORAGE_DIR/framework/views" "framework views"
ensure_dir_ready "$STORAGE_DIR/logs" "storage logs"

# ── Sync repo ──
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

# ── Backend (Laravel) ──
require_file "$BACKEND_ARCHIVE"

log "Publishing Laravel backend artifact"
rm -rf "$BACKEND_DIR/vendor" "$BACKEND_DIR/bootstrap/cache"
tar -xzf "$BACKEND_ARCHIVE" -C "$BACKEND_DIR"
rm -f "$BACKEND_ARCHIVE"

# Shared .env
require_file "$BACKEND_DIR/.env.example"

if [ ! -f "$SHARED_ENV_FILE" ]; then
  log "Creating shared .env from .env.example"
  cp "$BACKEND_DIR/.env.example" "$SHARED_ENV_FILE"
fi

if [ -n "$APP_DOMAIN" ]; then
  upsert_env "$SHARED_ENV_FILE" "APP_URL" "https://${APP_DOMAIN}"
fi
upsert_env "$SHARED_ENV_FILE" "APP_ENV" "production"
upsert_env "$SHARED_ENV_FILE" "APP_DEBUG" "false"

ln -sfn "$SHARED_ENV_FILE" "$BACKEND_DIR/.env"

# Symlink shared storage
rm -rf "$BACKEND_DIR/storage"
ln -sfn "$STORAGE_DIR" "$BACKEND_DIR/storage"

# Storage link for public access
cd "$BACKEND_DIR"
php artisan storage:link 2>/dev/null || true

# Run migrations
log "Running database migrations"
php artisan migrate --force --no-interaction

# Cache config, routes, views
log "Caching Laravel config/routes/views"
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Seed profiles if needed
php artisan db:seed --class=ProfileSeeder --force --no-interaction 2>/dev/null || true

# ── Frontend (Flutter web) ──
require_file "$APP_ARCHIVE"

log "Publishing frontend artifact"
rm -rf "$DIST_APP_DIR"/*
tar -xzf "$APP_ARCHIVE" -C "$DIST_APP_DIR"
rm -f "$APP_ARCHIVE"
require_file "$DIST_APP_DIR/index.html"

# ── Restart services ──
SERVICE_RESTARTED=0

if [ -x "$POST_HOOK" ]; then
  log "Running post-deploy hook"
  if "$POST_HOOK" "$APP_ROOT"; then
    SERVICE_RESTARTED=1
  else
    log "Warning: post-deploy hook failed."
  fi
else
  log "Restarting PHP-FPM ($PHP_FPM_SERVICE)"
  if run_systemctl restart "$PHP_FPM_SERVICE"; then
    SERVICE_RESTARTED=1
    log "PHP-FPM restarted."
  else
    log "Warning: could not restart PHP-FPM automatically."
  fi

  if [ "$RELOAD_NGINX" = "1" ]; then
    log "Reloading nginx"
    run_systemctl reload nginx 2>/dev/null || log "Warning: could not reload nginx."
  fi
fi

# ── Smoke check ──
log "Running smoke checks"
test -f "$DIST_APP_DIR/index.html"
require_file "$BACKEND_DIR/artisan"

if [ -n "$APP_DOMAIN" ]; then
  log "Deploy finished successfully for ${APP_DOMAIN}"
else
  log "Deploy finished successfully."
fi
