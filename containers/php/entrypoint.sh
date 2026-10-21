#!/bin/sh
set -eu

storage_dir="${NETARIUM_STORAGE_DIR:-/var/lib/netarium}"

mkdir -p \
    "$storage_dir/db/csv-import" \
    "$storage_dir/uploads/floorplans" \
    "$storage_dir/uploads/device_images" \
    "$storage_dir/cache/thumbnails" \
    "$storage_dir/temp/backup-export" \
    "$storage_dir/temp/backup-restore" \
    "$storage_dir/backups/auto" \
    "$storage_dir/logs/audit" \
    "$storage_dir/sessions"

exec "$@"
