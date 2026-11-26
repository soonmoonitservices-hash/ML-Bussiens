# Performance

Verbindlich. Gemessen wird im Profile-Modus auf dem langsamsten Testgerät (Mittelklasse-Android), nie nur im Simulator. Wird ein Ziel nicht erreicht, wird das Release nicht freigegeben.

## Budget
| Was | Ziel | Maximum |
|---|---|---|
| Kaltstart bis Startbildschirm | < 1,5 s | 2,5 s |
| Warmstart | < 0,5 s | 1 s |
| Screen öffnen (mit Cache) | < 150 ms | 300 ms |
| Liste laden (25 Einträge, online) | < 500 ms | 1 s |
| Live-Berechnung nach Eingabe | < 16 ms | 50 ms |
| Scrollen | 60 fps | kein Ruckler > 32 ms |
| Lieferschein / Rechnung PDF erzeugen | < 400 ms | 800 ms |
| PDF-Vorschau sichtbar | < 700 ms | 1,2 s |
| Gespeichertes PDF öffnen (2. Mal) | < 200 ms | 400 ms |
| Monats-PDF mit 30 Belegen | < 4 s | 8 s |
| Beleg-Foto aufnehmen bis gespeichert | < 2 s | 3 s |
| App-Größe (Download) | < 25 MB | 35 MB |

## Stand der Umsetzung (2026-11-23)
Umgesetzt:
- PDFs entstehen im Hintergrund-Isolate (`PdfService.generate`), Schriften werden pro Sitzung einmal geladen.
- Festgeschriebene Rechnungen und unterschriebene Lieferscheine liegen lokal im Cache (`PdfFileCache`, max. 200 MB, älteste zuerst gelöscht); beim zweiten Öffnen kein Download. Sie werden nie neu erzeugt.
- Listen laden 25 Einträge je Seite mit festen Spaltenlisten (kein `select('*')`), Suche mit Verzögerung, Skeleton statt Spinner.
- Auswertungen rechnet die Datenbank (`report_*`), mehrere Anfragen laufen mit `Future.wait` parallel.
- Fotos werden beim Aufnehmen auf 1600 px und Qualität 80 verkleinert.
- Kein Realtime, kein Polling.

Offen (jeweils mit Grund):
- Startbildschirm über eine einzige Funktion `home_overview()` (braucht neue Migration, Cloud-Änderung nur mit Bestätigung). Heute: zwei Anfragen.
- Lokaler Datenbank-Cache (Drift) für sofortige Anzeige: noch nicht gebaut.
- Keyset-Paginierung statt Offset, `createSignedUrls` gesammelt, Thumbnails in Listen.
- Langlebiger PDF-Worker, Vorab-Erzeugung auf der Detailseite, Fortschritt beim Monats-PDF, Vorschau seitenweise.
- Firmendaten und Logo im Speicher halten (heute wird `company_settings` bei jedem PDF neu gelesen).
- `keepAlive` für Stammdaten, `select` auf einzelne Felder, `itemExtent` in Listen.
- Messwerte: noch keine, da kein Gerät angeschlossen war.

## Release-Build (Android)
`flutter build appbundle --release --split-debug-info=build/symbols --obfuscate`. Symbole aufbewahren. Nur die benötigten Schriftschnitte sind eingebunden (Inter 4 Schnitte, Plex Arabic 3, Plex Mono 1, Plex Sans 3 für PDFs); falls die App über 25 MB liegt, zuerst Schnitte prüfen.

## Messen vor jedem Release
Kaltstart, Tourliste scrollen, Tour abschließen mit 30 Produkten, Rechnungs-PDF, Monats-PDF mit 30 Belegen. DevTools: Performance (keine roten Frames) und Speicher (keine Lecks beim Hin- und Herwechseln). Testdaten: 2.000 Touren, 300 Produkte, 1.000 Rechnungen, 2.000 Belege (nur lokal).

## Messwerte
| Datum | Gerät | Messung | Ergebnis |
|---|---|---|---|
| – | – | – | noch nicht gemessen |

## Backend (Stand 2026-11-23, nur lokal eingespielt)
Neue Migrationen 16–21, lokal mit `bash scripts/test_backend.sh` grün, **noch nicht in der Cloud**:
- 16 `rls_select_wrap`: alle Policies mit `(select is_active_user())`, Funktion wird einmal je Abfrage ausgewertet.
- 17 `role_timeouts`: `statement_timeout 5s`, `idle_in_transaction_session_timeout 10s` für `authenticated`.
- 18 `search_and_missing_indexes`: Trigram-Indizes auf Produktname und Empfänger, dazu `invoices(cancelled_by_invoice_id)`, `tours(closed_at)`, `products(active, name)`. Damit hat jeder Fremdschlüssel einen Index.
- 19 `rate_limits`: `_rate_limit()`, eingesetzt in `start_tour`, `close_tour`, `finalize_invoice`, `cancel_invoice` (je 30/Minute) und `import_products` (5/Stunde); Aufräumen täglich 01:10 UTC. Getestet: der 31. Aufruf in einer Minute liefert „Zu viele Anfragen. Bitte kurz warten.“
- 20 `data_versions()`: letzter Änderungszeitpunkt von Produkten, Fahrern, Firmendaten für den App-Cache.
- 21 `storage_limits`: Buckets höchstens 10 MB, nur JPG, PNG, PDF.
- `config.toml`: `max_rows = 200` (gilt in der Cloud erst nach `supabase config push`).

Wichtig: Wer `start_tour`, `close_tour`, `finalize_invoice`, `cancel_invoice` oder `import_products` später mit `create or replace` neu schreibt, muss die Zeile `perform public._rate_limit(...)` wieder einsetzen.

Offen:
- Rate-Limit für `report_*` (reine SQL-Funktionen, bräuchten eine Neufassung) und Zeitraum-Obergrenze 3 Jahre.
- Idempotenz mit `request_id` und Tabelle `processed_requests` (ändert die Signatur der kritischen Funktionen und die App).
- `home_overview()`, Keyset-Paginierung, `comment on` für alle Tabellen, `EXPLAIN ANALYZE` mit Testdaten (2.000 Touren, 300 Produkte, 1.000 Rechnungen, 2.000 Belege), Advisor-Prüfung in der Cloud.
- App: Wiederholen bei Netzwerkfehlern, Pull-to-Refresh-Drossel, `cacheControl` beim Upload, Warnung ab 80 % Free-Plan.
