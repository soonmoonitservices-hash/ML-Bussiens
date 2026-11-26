# Warenbestand

App (Flutter, iOS und Android) mit Supabase-Backend für einen Lebensmittel-Großhändler. Nur Chef und Verwaltung nutzen die App, Fahrer haben keinen Zugang.

Spezifikation: [docs/SPEC.md](docs/SPEC.md), [docs/spec/](docs/spec/). Code-Regeln: [docs/CLEAN_CODE.md](docs/CLEAN_CODE.md).

**Stand:** Backend, Kernberechnungen, PDF-Baukasten, Flutter-Grundgerüst, Auth und das Referenz-Feature Fahrer sind vorhanden. Produkte, Lager, Touren und weitere Oberflächen sind noch nicht vollständig umgesetzt. Der genaue, geprüfte Stand steht in [docs/implementation_status.md](docs/implementation_status.md); Festlegungen liegen unter [docs/spec/](docs/spec/).

## Backend lokal starten
Voraussetzungen: Docker, Node.js.
```bash
npx supabase start        # startet ein eigenes lokales Supabase (Ports 54420–54429)
make test-backend         # db reset (Migrationen + Seed) + Backend-Tests
```
Das Projekt heißt `warenbestand` und hat eigene Ports (Standard + 100), damit es neben anderen lokalen Supabase-Projekten läuft. Studio: http://127.0.0.1:54423, API: http://127.0.0.1:54421, Mails: http://127.0.0.1:54424.

Befehle: `make db-start | db-stop | db-reset | db-push | db-lint | test-backend`.

## Datenbank ändern
Nur über neue Migrationsdateien in `supabase/migrations` (nummeriert, nur vorwärts, alte nie ändern, eine Sache pro Migration). Neue Funktionen sind standardmäßig nicht von der App aufrufbar. Wer sie aufrufen darf, bekommt ein ausdrückliches `grant execute`. API-Beschreibung: [docs/backend_api.md](docs/backend_api.md).

## Produktion (Supabase, Frankfurt)
1. Auf supabase.com ein neues Projekt anlegen, Region **eu-central-1 (Frankfurt)**.
2. `npx supabase login`, dann `npx supabase link --project-ref <ref>` und `npx supabase db push`.
3. `npx supabase functions deploy delete-account`.
4. Dashboard → Authentication: „Allow new users to sign up“ aus lassen, Mindestlänge Passwort 8, E-Mail-Bestätigung an.
5. Firmendaten in der App (Chef) oder Tabelle `company_settings` eintragen.
6. GitHub-Secrets für Backup und Release setzen (siehe [docs/backup_restore.md](docs/backup_restore.md)).

## Benutzer anlegen
Der Chef legt Benutzer im Supabase-Dashboard an (Authentication → Users → Add user, E-Mail-Adresse und Passwort, „Auto Confirm User“ ankreuzen). Optional kann ein Anzeigename als User Metadata `{"name": "Vorname Nachname"}` mitgegeben werden.
- Der **erste** angelegte Benutzer wird automatisch **Chef**, alle weiteren **Verwaltung**.
- Rolle ändern oder deaktivieren: in der App (Chef) oder Tabelle `profiles`. Es bleibt immer mindestens ein aktiver Chef.
- Der Benutzer setzt beim ersten Login sein eigenes Passwort („Passwort vergessen“, 6-stelliger Code per E-Mail).

## Backup
Nächtlich per GitHub Actions, verschlüsselt, 30 Tage plus Monatsend-Backups 10 Jahre: [docs/backup_restore.md](docs/backup_restore.md).
