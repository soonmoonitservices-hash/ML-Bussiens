#!/usr/bin/env bash
# Spielt ein Backup in ein LEERES Supabase-Projekt zurück (neues Projekt oder `supabase db reset`).
# Benötigt: SUPABASE_DB_URL, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, BACKUP_PASSPHRASE
# Aufruf:   scripts/restore.sh backups/warenbestand-2026-11-30.tar.gz.gpg
# Danach die Auth-Benutzer im Dashboard neu anlegen (Passwörter sind nicht Teil des Backups).
set -euo pipefail

backup_file="${1:?Backup-Datei angeben}"
: "${SUPABASE_DB_URL:?SUPABASE_DB_URL fehlt}"
: "${SUPABASE_URL:?SUPABASE_URL fehlt}"
: "${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY fehlt}"
: "${BACKUP_PASSPHRASE:?BACKUP_PASSPHRASE fehlt}"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

echo "Entschlüsseln …"
gpg --batch --yes --pinentry-mode loopback --passphrase "$BACKUP_PASSPHRASE" \
  -o "$work_dir/backup.tar.gz" --decrypt "$backup_file"
tar -xzf "$work_dir/backup.tar.gz" -C "$work_dir"

echo "Datenbank zurückspielen …"
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$work_dir/schema.sql"
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$work_dir/data.sql"

echo "Storage-Dateien hochladen …"
api="$SUPABASE_URL/storage/v1"
find "$work_dir/storage" -type f | while read -r file; do
  relative="${file#"$work_dir"/storage/}"
  bucket="${relative%%/*}"
  object_path="${relative#*/}"
  curl -fsS -X POST \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "x-upsert: true" -H "Content-Type: application/octet-stream" \
    --data-binary "@$file" "$api/object/$bucket/$object_path" > /dev/null
done

echo "Fertig. Bitte die Benutzer im Dashboard neu anlegen und die Rollen in profiles prüfen."
