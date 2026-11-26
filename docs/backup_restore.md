# Backup und Wiederherstellung

Der Free-Plan von Supabase hat keine automatischen Backups. Darum sichert GitHub Actions nachts selbst.

## Was gesichert wird
- Datenbank (Schema + Daten) per `supabase db dump`
- alle Storage-Dateien (Belege, Unterschriften, PDFs, Logos, Produktfotos)
- alles zusammen verschlüsselt mit gpg (AES256) als `warenbestand-YYYY-MM-DD.tar.gz.gpg`

Nicht enthalten: Passwörter der Benutzer (sie liegen im Auth-Bereich). Nach einer Wiederherstellung die Benutzer im Dashboard neu anlegen.

## Aufbewahrung
- Tagesbackups: 30 Tage als Artifact des Workflows „Backup“ (02:30 UTC)
- Backup am letzten Tag des Monats: zusätzlich in ein privates Archiv-Repository (`monthly/`), dort 10 Jahre (GoBD)
- Der nächtliche Lauf erzeugt Datenbank-Aktivität und verhindert so die Pause des Free-Projekts nach 7 Tagen Inaktivität

## Einrichtung (einmalig, GitHub → Settings → Secrets → Actions)
| Secret | Inhalt |
|---|---|
| `SUPABASE_DB_URL` | Datenbank-Verbindung (Dashboard → Project Settings → Database → Connection string, Session pooler) |
| `SUPABASE_URL` | `https://<ref>.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service-Role-Key (nur hier, nie in der App) |
| `BACKUP_PASSPHRASE` | langes Passwort für die Verschlüsselung. Sicher aufbewahren, ohne sie ist kein Backup lesbar |
| `BACKUP_ARCHIVE_REPO` | privates Repository `owner/name` für die Monatsend-Backups |
| `BACKUP_ARCHIVE_TOKEN` | Token mit Schreibrecht auf dieses Repository |

Testlauf: Actions → Backup → „Run workflow“.

## Wiederherstellen
1. Neues (leeres) Supabase-Projekt anlegen oder lokal `npx supabase db reset` ohne Seed.
2. Backup herunterladen (Artifact bzw. aus dem Archiv-Repository).
3. Mit den Variablen `SUPABASE_DB_URL`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `BACKUP_PASSPHRASE`:
   ```bash
   bash scripts/restore.sh backups/warenbestand-2026-11-30.tar.gz.gpg
   ```
4. Benutzer im Dashboard neu anlegen. Der erste angelegte Benutzer wird Chef; danach in `profiles` Rollen prüfen.
5. Edge Function neu ausrollen: `supabase functions deploy delete-account`.

Das Skript spielt das Schema ein. Auf einem Projekt, in dem die Migrationen schon laufen, vorher die Tabellen leeren oder ein frisches Projekt verwenden.

## Wechsel auf Supabase Pro
Kein Code-Umbau. Im Dashboard den Plan wechseln (Billing). Danach gibt es tägliche automatische Backups, mehr Speicher und keine Pause bei Inaktivität. Das GitHub-Backup kann zusätzlich weiterlaufen.
