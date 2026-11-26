# Warenbestand

Flutter-App (iOS + Android) mit Supabase-Backend für einen deutschen Lebensmittel-Großhändler. Nutzer: nur Chef und Verwaltung, Fahrer haben keinen Zugang.

## Pflichtlektüre vor jeder Arbeit
- [docs/SPEC.md](docs/SPEC.md): Gesamtspezifikation, Vorgehen in 10 Schritten (Abschnitt 15), Ordnerstruktur (Abschnitt 16)
- [docs/spec/](docs/spec/): **neuere Festlegungen, gehen SPEC.md vor**: `backend.md`, `technical.md` (Routen, Auth, Offline, Zahlen, Bilder, E-Rechnung, „Fertig“-Definition), `security.md`, `tests.md`, `pdf.md`
- [docs/CLEAN_CODE.md](docs/CLEAN_CODE.md): verbindliche Code-Regeln und Review-Checkliste (Abschnitt 16)
- [docs/backend_api.md](docs/backend_api.md): alle RPC-Funktionen mit Fehlermeldungen und Dart-Beispielen
- [docs/testing_checklist.md](docs/testing_checklist.md): manuelle Tests vor jeder Auslieferung
- Kundenvorlagen (PDFs) in `docs/`

## Stand
- **Backend fertig, getestet und in der Cloud eingespielt** (`supabase/migrations` 01–15, `seed.sql`, Edge Function `delete-account`, Backup-Skripte/-Workflow). `make test-backend` muss grün sein.
- **Cloud-Projekt:** noch keines. Eigenes Supabase-Projekt anlegen, dann `supabase link` und `config/prod.json` (Vorlage: `config/prod.example.json`). Änderungen an der Cloud brauchen die Bestätigung des Nutzers.
- **Flutter-App: in Arbeit (2026-11-22).** App-Gerüst, Theme, Router, Supabase-Initialisierung, Auth und das Referenz-Feature Fahrer sind implementiert. Kernlogik und gemeinsamer PDF-Baukasten sind getestet; `flutter analyze` ist ohne Hinweise und 72 Tests sind grün. Weitere Fachfeatures sind noch offen. Maßgeblicher Abgleich: `docs/implementation_status.md`.

## Harte Regeln
- Geld als bigint in Cent, Gewicht als integer in Gramm, nie float/double.
- Kritische Logik (Tour start/close, Nummern, Rechnung festschreiben, Löschen) liegt in der Datenbank. Seit 2026-11-23 gibt es keinen Lagerbestand mehr (Produkte sind nur eine Liste) und keine Mehrwertsteuer außer bei der Rechnung (Satz je Position). Alles darf gelöscht werden (Funktionen `delete_tour`, `delete_delivery_note`, `delete_invoice`), auch festgeschriebene Rechnungen; die App warnt davor. Das DB-Ergebnis ist maßgeblich; Dart rechnet nur für die Live-Anzeige (mit Unit-Tests).
- DB-Änderungen nur über neue Migrationen (nummeriert, nur vorwärts, alte nie ändern, eine Sache pro Migration). Neue Funktionen sind standardmäßig nicht von der App aufrufbar, daher ausdrückliches `grant execute`.
- Service-Role-Key nie in der App. `config/dev.json` und `config/prod.json` nie ins Git (Vorlagen: `config/*.example.json`).
- UI greift nur über Repositories auf Supabase zu, keine Logik in Widgets. Features importieren sich nicht gegenseitig.
- Keine Kundenverwaltung (Kunden des Großhändlers), kein Fahrer-Zugang. Edge Functions: `delete-account`, `create-user` (Benutzer anlegen, kein Einladungs-Ablauf: in der eigenen Firma, oder mit `mode: new_company` in einer eigenen neuen Firma, das nur der Superadmin) und `superadmin-delete-firm` (nur Superadmin DEINE-SUPERADMIN-EMAIL, Tabelle `platform_admins`). Chef und Verwaltung haben gleiche Rechte.
- Texte nur über ARB (Deutsch + Arabisch, beide vollständig), RTL-sicher bauen (start/end). Code Englisch. Design nach [docs/spec/design.md](docs/spec/design.md) (Stand 2026-11-22, ersetzt die Plex-Fassung): Inter (Arabisch Plex Sans Arabic), Schwarz-Weiß, nur Phosphor-Icons über `AppIcons`, jeder Screen ein `AppScreen`, Hauptbutton klebt unten (`StickyAction`), sonst nichts außer der unteren Navigation.
- PDFs nur über den gemeinsamen Baukasten `lib/core/pdf/`; Summen kommen aus der Datenbank, das PDF rechnet nicht.
- Keine Pakete außerhalb der Spezifikation ohne Rückfrage.

## Tests
Nur Berechnungen automatisch (Dart: Money, Quantity, Settlement-, Load-, Invoice-Calculator; SQL: `start_tour`, `close_tour`). Keine Widget-, Integrations- oder RLS-Tests. CI: nur `flutter analyze` + `flutter test`.

## Befehle (Backend)
`make db-start | db-stop | db-reset | db-push | db-lint | test-backend`. Lokales Supabase `warenbestand` auf Ports 54420–54429.

## Vorgehen
Schrittweise nach SPEC.md Abschnitt 15. Vor jedem Schritt kurzer Plan. „Fertig“-Definition: technical.md Abschnitt 16. Bei Unklarheit nachfragen statt raten. Nicht committen oder pushen ohne Aufforderung.

## Umgebung (Windows)
Docker, Node, Git vorhanden; Supabase CLI über `npx`. Flutter in `D:/dev/flutter` installiert. `make` fehlt unter Windows: `bash scripts/test_backend.sh`. iOS-Builds nur über GitHub Actions (Mac-Runner). Repo: github.com/soonmoonitservices-hash/ML-Bussiens, Branch `main`.
