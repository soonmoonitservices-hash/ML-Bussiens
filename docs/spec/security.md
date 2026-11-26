# Sicherheit (einfach, aber sicher)

Ersetzt Abschnitt 6 in `docs/SPEC.md` und vereinfacht die Sicherheitsregeln in `docs/spec/backend.md`. Die App ist privat (nur Chef + Verwaltung, wenige Benutzer). Sicherheit so einfach wie möglich halten, aber Daten dürfen nicht öffentlich erreichbar sein.

## Pflicht (Minimum)
- Öffentliche Registrierung in Supabase AUSSCHALTEN (Auth → Sign-ups disabled). Benutzer legt nur der Chef im Supabase-Dashboard an (oder per Einladung).
- RLS auf JEDER Tabelle, mit EINER einfachen Policy pro Tabelle: „Zugriff nur für angemeldete Benutzer“ (`auth.role() = 'authenticated'`) → per Hilfsfunktion in einer einzigen Migration für alle Tabellen anlegen
- Storage-Buckets privat, eine Policy: nur angemeldete Benutzer
- Service-Role-Key NIEMALS in der App, nur der anon key über `--dart-define`
- `config/dev.json` und `config/prod.json` nicht ins Git (`.gitignore`)
- Festgeschriebene Rechnungen nicht änderbar/löschbar, nur Storno (rechtliche Pflicht)
- Nächtliches Backup bleibt

## Einfache Rollen
- Nur eine Prüfung in der App (nicht in jeder Policy): Rolle „chef“ sieht zusätzlich Benutzerverwaltung, Firmendaten und Storno-Button
- Die Rolle steht in `profiles.role` und wird beim Login geladen

## Weglassen
- Keine rollenbasierten Policies pro Tabelle
- Keine pgTAP-Tests für RLS
- Kein Datei-Typ-/Größenlimit per Storage-Policy (nur in der App prüfen)
- Kein `audit_log`-Trigger auf allen Tabellen: nur `created_by`/`updated_by` und Änderungsverlauf bei Rechnungen und Touren
- Kein Sentry (optional später)
- Edge Function `invite-user` weglassen: Benutzer legt der Chef im Supabase-Dashboard an. Nur `delete-account` bleibt (Pflicht für den App Store).

## Umsetzung im Backend (Abweichungen bewusst klein gehalten)
- „Angemeldet“ heißt hier „angemeldet UND aktiv“ (`is_active_user()`), damit deaktivierte Benutzer sofort gesperrt sind (die App meldet sie beim Start ab).
- Zusätzlich schützt ein Trigger `profiles`: nur der Chef ändert Rolle/aktiv. Sonst könnte sich ein Verwaltungs-Benutzer selbst zum Chef machen und damit die Chef-Funktionen (Storno, Tour wieder öffnen) nutzen. Das ist keine Policy pro Tabelle, sondern ein einzelner Schutz.
- Änderungsverlauf: Tabelle `change_log` (Trigger nur auf `tours` und `invoices`).
