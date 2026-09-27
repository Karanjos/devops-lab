#! /usr/bin/env bash

set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; }
success() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

BACKUP_DIR="${BACKUP_DIR:-$HOME/devops-lab-backups}"
KEEP="${KEEP:-5}"
DB_USER="${DB_USER:-orders}"
DB_NAME="${DB_NAME:-orders}"

mkdir -p "$BACKUP_DIR"

timestamp=$(date +%d%m%Y-%H%M%S)
final_file="$BACKUP_DIR/orders-$timestamp.sql.gz"
tmpfile="$(mktemp)"

trap 'rm -f "$tmpfile"' EXIT

log "Dumping database '$DB_NAME' to '$final_file'...."

docker compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$tmpfile"

mv "$tmpfile" "$final_file"

success "Database dump completed successfully: $final_file"
log "Backup written : $final_file ($(du -h "$final_file" | cut -f1))"

log "Removing backups older than the newest $KEEP backups..."

backup_count=$(ls -1 "$BACKUP_DIR"/orders-*.sql.gz 2>/dev/null | wc -l)

if [[ "$backup_count" -gt "$KEEP" ]]; then
    ls -1t "$BACKUP_DIR"/orders-*.sql.gz | tail -n +$((KEEP + 1)) | xargs -r rm --
    error "Removed $((backup_count - KEEP)) old backup(s)."
else
    log "Only '$backup_count' backup(s) found. No old backups to remove."
fi

log "Current backups:"
ls -lh "$BACKUP_DIR"/orders-*.sql.gz