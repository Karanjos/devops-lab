#! /usr/bin/env bash
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; }
success() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

DB_USER="${DB_USER:-orders}"
DB_NAME="${DB_NAME:-orders}"

if [[ $# -ne 1 ]]; then
    error "Usage: $0 <path-to-backup.sql.gz>"
    exit 1
fi

backup_file="$1"

if [[ ! -f "$backup_file" ]]; then
    error "file not found: $backup_file"
    exit 1
fi

log "This will REPLACE all data in database '$DB_NAME'. Conitnuing in 5 seconds, Ctrl + C to cancel."
sleep 5

log "Stopping backend to release database connections..."
docker compose stop backend

log "Dropping and recreating database: '$DB_NAME'..."
docker compose exec -T postgres psql -U "$DB_USER" -d postgres -c "
    SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();"

docker compose exec -T postgres psql -U "$DB_USER" -d postgres \
    -c "DROP DATABASE IF EXISTS $DB_NAME" \
    -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

log "restoring from file '$backup_file'..."

gunzip -c "$backup_file" | docker compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME"

log "Restarting backend..."
docker compose start backend

success "Restore complete."