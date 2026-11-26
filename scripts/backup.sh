#!/usr/bin/env bash
# Sichert Datenbank (Schema + Daten) und alle Storage-Dateien, verschlüsselt mit gpg (AES256).
# Benötigt: SUPABASE_DB_URL, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, BACKUP_PASSPHRASE
# Aufruf:   scripts/backup.sh [Zielordner]   (Standard: ./backups)
# Ergebnis: <Zielordner>/warenbestand-YYYY-MM-DD.tar.gz.gpg
set -euo pipefail

: "${SUPABASE_DB_URL:?SUPABASE_DB_URL fehlt}"
: "${SUPABASE_URL:?SUPABASE_URL fehlt}"
: "${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY fehlt}"
: "${BACKUP_PASSPHRASE:?BACKUP_PASSPHRASE fehlt}"

target_dir="${1:-backups}"
date_stamp="$(date -u +%Y-%m-%d)"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$target_dir" "$work_dir/storage"

echo "Datenbank sichern …"
npx --yes supabase db dump --db-url "$SUPABASE_DB_URL" -f "$work_dir/schema.sql"
npx --yes supabase db dump --db-url "$SUPABASE_DB_URL" --data-only -f "$work_dir/data.sql"

api="$SUPABASE_URL/storage/v1"
auth=(-H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "apikey: $SUPABASE_SERVICE_ROLE_KEY")

# Listet Dateien eines Buckets unterhalb eines Präfixes (Ordner haben keine id) und lädt sie herunter.
download_prefix() {
  local bucket="$1" prefix="$2" entries name
  entries="$(curl -fsS "${auth[@]}" -H 'Content-Type: application/json' \
    -d "{\"prefix\":\"$prefix\",\"limit\":1000,\"offset\":0}" "$api/object/list/$bucket")"
  echo "$entries" | jq -c '.[]' | while read -r entry; do
    name="$(echo "$entry" | jq -r '.name')"
    if [ "$(echo "$entry" | jq -r '.id')" = "null" ]; then
      download_prefix "$bucket" "${prefix}${name}/"
    else
      mkdir -p "$work_dir/storage/$bucket/$prefix"
      curl -fsS "${auth[@]}" -o "$work_dir/storage/$bucket/${prefix}${name}" "$api/object/$bucket/${prefix}${name}"
    fi
  done
}

echo "Storage-Dateien sichern …"
for bucket in $(curl -fsS "${auth[@]}" "$api/bucket" | jq -r '.[].id'); do
  download_prefix "$bucket" ""
done

echo "Verschlüsseln …"
tar -czf "$work_dir/backup.tar.gz" -C "$work_dir" schema.sql data.sql storage
gpg --batch --yes --pinentry-mode loopback --passphrase "$BACKUP_PASSPHRASE" \
  --symmetric --cipher-algo AES256 \
  -o "$target_dir/warenbestand-$date_stamp.tar.gz.gpg" "$work_dir/backup.tar.gz"

echo "Fertig: $target_dir/warenbestand-$date_stamp.tar.gz.gpg"
