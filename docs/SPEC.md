# Warenbestand – Spezifikation

> **Vorrang:** Die neueren Dateien in `docs/spec/` gehen dieser Datei vor, wenn sie sich widersprechen: [backend.md](spec/backend.md) (Backend), [technical.md](spec/technical.md) (Routen, Auth, Offline, Zahlen, E-Rechnung), [security.md](spec/security.md), [tests.md](spec/tests.md), [pdf.md](spec/pdf.md). Code-Regeln: [CLEAN_CODE.md](CLEAN_CODE.md).

Quelle der Wahrheit für die App. Kundenvorlagen: `App-Anforderungen-Arabisch-Deutsch.pdf` (Anforderungen) und `Warenbestand-Dashboard.pdf` (Design der Startseite: 4 Kacheln Touren / Bestand / Ausgaben / Lieferschein, Grün/Gold/Creme).

## 0. Worum geht es

Kleiner deutscher Lebensmittel-Großhändler (Oliven, Käse, Öl). Fahrer liefern mit dem Lieferwagen aus und verkaufen unterwegs. Die App verwaltet Produkte, Lager, Touren, Fahrerabrechnung, Lieferscheine, Rechnungen mit USt, Ausgabenbelege und Auswertungen.

- Plattformen: iOS und Android (eine Codebasis)
- Nutzer: NUR Chef und Verwaltung. Fahrer haben KEINEN Zugang.
- Ziel: 0 € laufende Serverkosten (Supabase Free), später ohne Umbau auf Pro erweiterbar.

**Wichtigste Regel:** Der Fahrer benutzt die App nicht. Chef/Verwaltung tragen vor der Abfahrt die Ladung ein und nach der Rückkehr die übrige Ware. Die App rechnet alles andere automatisch.

**Nicht einbauen:** keine Kundenverwaltung (Empfänger immer frei eintippen), kein Zugang/keine Ansicht für Fahrer.

## 1. Tech-Stack

Frontend: Flutter (aktuelle stabile Version), Dart null-safe, jeweils aktuelle kompatible Paketversionen.

Backend: Supabase (Free), Region eu-central-1 Frankfurt (DSGVO)
- Supabase Auth (E-Mail + Passwort)
- PostgreSQL, Geschäftslogik als SQL-Funktionen (RPC)
- Row Level Security auf ALLEN Tabellen
- Storage: private Buckets (Belegfotos, Unterschriften, PDFs, Logo)
- Edge Functions (Deno/TS) NUR für Aufgaben mit Service-Role-Key (Benutzer einladen, Konto löschen)
- pg_cron für geplante Aufgaben
- Supabase CLI für Migrationen und lokale Entwicklung (`supabase start`, Docker)

Umgebungen: lokal (CLI/Docker) und Produktion (ein Projekt in Frankfurt). DB-Änderungen NUR über Migrationsdateien in `supabase/migrations`, nie per Hand im Dashboard.

Flutter-Pakete: supabase_flutter, flutter_riverpod + riverpod_annotation + riverpod_generator, go_router, freezed + freezed_annotation + json_serializable + build_runner, pdf + printing, share_plus, signature, cunning_document_scanner, image_picker, flutter_image_compress, cached_network_image, fl_chart, drift, connectivity_plus, intl + flutter_localizations, flutter_native_splash, flutter_launcher_icons, sentry_flutter, very_good_analysis, mocktail, integration_test.

## 2. Architektur

Feature-first Clean Architecture:

```
lib/
  core/     Theme, Router, Supabase-Client, Fehlerbehandlung, Formatierung, Money, Quantity, Konstanten
  shared/   wiederverwendbare Widgets
  features/ auth users drivers products stock tours delivery_notes invoices receipts reports company home
            je Feature: data/ (Repositories, DTOs), domain/ (Modelle, Berechnung, Interfaces), presentation/ (Screens, Widgets, Controller)
  l10n/     ARB-Dateien
supabase/
  migrations/  functions/ (invite-user, delete-account)  seed.sql  tests/ (pgTAP)
```

Regeln:
- Kritische Logik (Lager buchen, Tour abschließen, Nummern vergeben, Rechnung festschreiben) als SQL-Funktion in EINER Transaktion.
- Dieselben Berechnungen zusätzlich in reinem Dart (Live-Anzeige); das Ergebnis der Datenbank ist maßgeblich.
- UI greift nie direkt auf Supabase zu, nur über Repositories. Keine Logik in Widgets.

## 3. Daten und Geld

- Geld IMMER bigint in Cent (12,50 € → 1250). Nie float/double.
- Gewicht IMMER integer in Gramm (12,5 kg → 12500). Stück/Gläser integer.
- Dart-Value-Klassen: Money, Quantity (Basiseinheit + Einheitstyp).
- Menge: gesamt = kartons × inhalt_pro_karton + einzelne.
- Preise werden beim Erstellen von Tour/Rechnung in die Positionen KOPIERT.
- USt kaufmännisch gerundet, pro Rechnung je Steuersatz.
- Zeitstempel timestamptz, Anzeige Europe/Berlin.
- Jede Tabelle: id uuid (gen_random_uuid()), created_at, created_by, updated_at, updated_by (Trigger).

## 4. Datenbank

Enums: `user_role` chef|office · `product_unit` carton|piece|jar|kg · `tour_status` draft|active|closed · `invoice_status` draft|open|paid|overdue|cancelled · `movement_type` intake|tour_out|tour_return|invoice|correction

Tabellen:
- profiles: id (= auth.users.id), name, email, role, active
- drivers: id, name, phone, vehicle, active
- company_settings (eine Zeile): name, address, phone, email, tax_number, vat_id, iban, bic, bank_name, managing_director, logo_path
- products: id, sku (unique), name, category, unit, units_per_carton null, buy_price_net_cents, sell_price_net_cents, vat_rate (7|19), min_stock, stock, image_path, active
- stock_movements: id, product_id, type, qty (+/−), reason, ref_table, ref_id
- tours: id, number (unique), driver_id, driver_name (Kopie), name, planned_at, status, cash_received_cents, difference_reason, started_at, started_by, closed_at, closed_by
- tour_items: id, tour_id, product_id, product_name, unit, units_per_carton, buy_cents, sell_cents, vat_rate, loaded_qty, returned_qty
- tour_expenses: id, tour_id, type, amount_cents, receipt_id null
- delivery_notes: id, number (unique), date, recipient_name, recipient_address, tour_id null, signature_path, signer_name, signed_at, pdf_path
- delivery_note_items: id, delivery_note_id, product_id, product_name, unit, qty
- invoices: id, number (unique, null im Entwurf), date, service_date, due_date, recipient_name, recipient_address, note, net_cents, vat7_cents, vat19_cents, gross_cents, status, paid_at, cancels_invoice_id null, tour_id null, delivery_note_id null, pdf_path
- invoice_items: id, invoice_id, product_id, product_name, unit, qty, price_net_cents, vat_rate
- receipts: id, date, year_month ('2026-11'), title, category, gross_cents, vat_rate, net_cents, image_path, tour_id null, note
- number_counters: type, year, last_value (PK type+year)
- audit_log: id, user_id, action, table_name, record_id, old_data jsonb, new_data jsonb, created_at

Constraints/Indizes:
- CHECK: Preise ≥ 0, Mengen ≥ 0, returned_qty ≤ loaded_qty, products.stock ≥ 0, units_per_carton > 0 wenn gesetzt, vat_rate in (0,7,19)
- Fremdschlüssel überall, ON DELETE RESTRICT für Belege/Rechnungen
- Indizes: tours(status, planned_at), tours(driver_id, planned_at), receipts(year_month), invoices(status, due_date), stock_movements(product_id, created_at)

Views (security_invoker = true): v_tour_summary, v_stock_overview, v_monthly_report, v_driver_stats, v_top_products.

## 5. SQL-Funktionen (RPC, security definer, mit Rollenprüfung)

- `next_number(type)` → T-2026-001 / LS-2026-001 / RE-2026-001, SELECT … FOR UPDATE, nie doppelt, lückenlos
- `start_tour(tour_id)`: prüft Bestand, bucht Ladung ab, schreibt stock_movements, vergibt Nummer, Status active (eine Transaktion; Fehler bei zu wenig Bestand)
- `close_tour(tour_id, returns jsonb, cash_received_cents, expenses jsonb, reason)`: prüft returned ≤ loaded, bucht Rückgaben ins Lager, speichert Ausgaben, berechnet Differenz, verlangt reason bei Differenz ≠ 0, Status closed
- `book_stock_intake(product_id, qty, note)`, `correct_stock(product_id, new_qty, reason)` (reason Pflicht)
- `finalize_invoice(invoice_id)`: Nummer, Summen neu berechnen, Status open, Direktverkauf vom Lager (wenn ohne Tour), danach unveränderbar
- `cancel_invoice(invoice_id)`: nur chef, Stornorechnung mit negativen Beträgen
- `mark_invoice_paid(invoice_id)`, `invoice_from_delivery_note(delivery_note_id)`
- `current_role()` für RLS

Trigger: updated_at/updated_by; audit_log auf tours, invoices, products, stock_movements, receipts, company_settings; neuer auth.users → profiles.
pg_cron: täglich 02:00 offene Rechnungen mit due_date < heute → overdue.

## 6. Sicherheit (RLS)

- RLS auf JEDER Tabelle, standardmäßig alles verboten.
- Lesen: nur angemeldete Benutzer mit profiles.active = true.
- Schreiben normale Tabellen: chef und office.
- Nur chef: profiles (Rollen/aktiv), company_settings, cancel_invoice, Änderungen an abgeschlossenen Touren.
- stock_movements, number_counters, audit_log: KEIN Client-Schreiben, nur über SQL-Funktionen.
- invoices mit status ≠ draft: kein UPDATE/DELETE vom Client. tours mit status = closed: kein UPDATE vom Client.
- Storage: private Buckets receipts, signatures, documents, logos; Policies nur für aktive Benutzer; nur image/jpeg, image/png, application/pdf; max. 10 MB; Zugriff nur über Signed URLs.
- Edge Functions: `invite-user` (nur chef, Einladung per E-Mail, Rolle setzen), `delete-account` (Pflicht für Apple).
- Service-Role-Key NIE in der App, nur in Edge Functions / GitHub Secrets. In der App nur SUPABASE_URL und anon key über `--dart-define`.
- Passwort mindestens 8 Zeichen, E-Mail-Bestätigung an.
- RLS und Funktionen mit pgTAP testen.

## 7. Free-Plan-Regeln

Grenzen: 500 MB DB, 1 GB Dateien, keine automatischen Backups, Pause nach 7 Tagen Inaktivität.
- Fotos vor Upload auf ca. 200 KB / max. 1600 px komprimieren, Thumbnails in Listen.
- PDFs nur speichern, wenn signiert bzw. festgeschrieben; sonst bei Bedarf neu erzeugen.
- Kein Realtime, keine unnötigen Abfragen, Pagination (20–30).
- Speicherverbrauch in den Einstellungen anzeigen.
- Nächtliches Backup per GitHub Actions: `supabase db dump` verschlüsselt (gpg) + Storage-Dateien über die Storage-API; 30 Tage aufbewahren, Monatsende-Backups 10 Jahre; README zur Wiederherstellung. Der Job hält das Projekt nebenbei aktiv.
- Hinweis in der Admin-Ansicht, falls das Projekt pausiert war.
- Wechsel auf Supabase Pro nur Plan-Wechsel, kein Code-Umbau.

## 8. Offline

Supabase hat keinen eingebauten Offline-Modus:
- Zuletzt geladene Daten (Produkte, Touren, Fahrer) per drift cachen.
- Entwürfe (Tour, Lieferschein, Rechnung, Beleg) lokal speichern und bei Verbindung hochladen.
- Aktionen mit SQL-Funktion (Tour starten/abschließen, Rechnung festschreiben) offline sperren mit klarem Hinweis, nie halb ausführen.
- Banner „Keine Internetverbindung“.

## 9. Design

- Gleiches Aussehen auf iOS und Android, plattformtypisches Verhalten (iOS-Wischgeste, Android-Zurück, Safe Areas).
- Farben: Dunkelgrün `#0B4A2E`, Beige `#F7F3EA` (Hintergrund), Gold `#E8B931` (Akzent), Orange/Hellgelb (Warnung), Rot (Fehlbetrag).
- Schrift Inter (als Asset), Karten-Radius 16, Abstände 4/8/12/16/24/32, Tokens zentral im Theme.
- Untere Navigation: Start · Touren · Bestand · Auswertungen · Mehr (Mehr: Ausgaben, Lieferscheine, Rechnungen, Fahrer, Benutzer, Firmendaten, Konto).
- Start: Begrüßung + Datum, Karte „Heute unterwegs“, 4 Kacheln (Touren, Bestand, Ausgaben, Lieferschein) mit Icons, Monatsübersicht (Umsatz, Ausgaben, Gewinn), letzte Touren.
- Widgets: AppCard, PrimaryButton, SecondaryButton, MoneyText, QuantityInput (Kartons + Einzelstück ODER kg), StatusChip, EmptyState, ConfirmDialog, SectionHeader, OfflineBanner.
- Barrierefreiheit: Touch-Ziele ≥ 48 px, Kontrast WCAG AA, große Systemschrift.
- Sprache Deutsch, alle Texte in ARB; RTL-sicher (EdgeInsetsDirectional, start/end), damit Arabisch später ergänzbar ist.
- Währung 1.234,56 €, Datum 16.11.2026.

## 10. Funktionen

**10.1 Benutzer:** Anmelden, Passwort vergessen, Abmelden, Konto löschen. Rollen: chef (alles inkl. Benutzer, Firmendaten, Stornos, Korrektur abgeschlossener Touren), office (tägliche Arbeit, keine Benutzerverwaltung). Chef lädt per E-Mail ein, ändert Rolle, deaktiviert. Überall „erstellt/geändert von“.

**10.2 Fahrer (nur Liste, kein Login):** Name (Pflicht), Telefon, Fahrzeug/Kennzeichen, aktiv. Anlegen, bearbeiten, deaktivieren (alte Touren bleiben).

**10.3 Produkte:** Name, Artikelnummer (auto ART-001, änderbar), Kategorie, EK netto, VK netto, USt 7/19 %, Einheit (Karton|Stück|Glas|kg), Inhalt pro Karton, Mindestbestand, optional Foto. Preise pro Basiseinheit. Anlegen, bearbeiten, deaktivieren, suchen.
Seed-Beispiele:
- Grüne Oliven · Glas · 1 Karton = 4 Gläser · EK 3,00 € · VK 4,50 € · 7 %
- Baladi-Käse · kg · EK 6,00 € · VK 9,00 € · 7 %
- Olivenöl 1 l · Stück · 1 Karton = 12 Stück · EK 7,20 € · VK 12,50 € · 7 %

**10.4 Lagerbestand:** Liste mit Menge (bei Karton zusätzlich „= X Kartons + Y Stück“); oben Warenwert EK und Anzahl Produkte; Filter Alle · Knapp · Kategorien; Suche nach Name/Artikelnummer; orange Warnung + Banner unter Mindestbestand; Wareneingang buchen; Bestand korrigieren mit Pflicht-Begründung; automatisch: Tour starten −, Tour abschließen + Rückgabe, Rechnung ohne Tour −; Produktdetail mit Bewegungsverlauf; Bestand nie negativ.

**10.5 Tour planen/beladen:** Schritt 1 Fahrer, Datum/Uhrzeit, optional Name. Schritt 2 Produkte wählen, nur Menge eintragen, Bestand daneben. Karton-Produkte: zwei Felder „Kartons“ + „einzelne Stück/Gläser“; kg-Produkte ein Feld mit Komma (600 oder 12,5). Sofortige Umrechnung: 13 Kartons + 3 Gläser, 1 Karton = 4 → 55 Gläser. Wert live: Warenwert EK, Warenwert VK, erwarteter Gewinn. Buttons „Tour speichern & starten“, „Als Entwurf speichern“. Status Entwurf → Unterwegs → Abgeschlossen.

**10.6 Tour abschließen:** Pro Produkt „zurückgebracht“. Anzeige geladen/zurück/verkauft; verkauft = geladen − zurück (55 − 7 = 48). Fehler wenn zurück > geladen. „Vom Fahrer übergebenes Bargeld“. Ausgaben („+ Ausgabe“: Art Diesel/Essen/Parken/Sonstiges oder frei, Betrag, optional Belegfoto). Live:
- Verkaufswert = Σ verkauft × VK
- Ausgaben = Σ Ausgaben
- Soll-Bargeld = Verkaufswert − Ausgaben
- Differenz = Bargeld − Soll-Bargeld: < 0 rot „Fehlbetrag −X €“, > 0 grün „Überschuss +X €“, = 0 „Kasse stimmt ✓“
- Wareneinsatz = Σ verkauft × EK; Tourgewinn = Verkaufswert − Wareneinsatz − Ausgaben
Differenz ≠ 0 → Pflichtfeld Begründung. „Abschluss prüfen & bestätigen“ → `close_tour()`, Tour gesperrt.

**10.7 Lieferschein:** Firmendaten einmalig (nur chef). Empfänger Name + Adresse frei. Nummer LS-2026-001, Datum, optional Tour (Positionen übernehmen), Produkte + Mengen. A4-Vorschau (Firmenkopf, Empfänger, Tabelle Produkt/Menge/Einheit). Unterschrift mit Finger, „Löschen“; im PDF mit Name, Datum, Uhrzeit. PDF speichern/teilen; Liste mit Suche; „Rechnung aus Lieferschein erstellen“.

**10.8 Rechnungen (USt):** Liste Alle · Offen · Bezahlt · Überfällig · Entwürfe, Summe offen oben. Empfänger frei. Rechnungsdatum, Leistungsdatum, Zahlungsziel → Fälligkeit. Positionen: Menge × Netto-Einzelpreis; optional aus Tour/Lieferschein. Netto, USt 7 % und 19 % getrennt, Brutto. PDF mit Pflichtangaben nach § 14 UStG. Entwurf → festschreiben → Offen → Bezahlt; Überfällig per Cron. Festgeschriebene nicht änderbar/löschbar, nur Storno (chef).

**10.9 Ausgabenbelege:** Scan oder Galerie. Bezeichnung, Brutto, USt 0/7/19 % (Netto automatisch), Kategorie (Fahrzeug & Kraftstoff, Miete, Wartung, Verpflegung, Sonstiges), Datum, optional Tour, Notiz. Automatische Monatsordner („November 2026“), Wechsel mit Pfeilen. Monatssumme oben, Filter Alle · Tourkosten · Sonstige. Ansehen, bearbeiten, löschen. Export einzeln oder ganzer Monat als ein PDF (Deckblatt: Monat, Anzahl, Summen netto/USt/brutto) zum Teilen an den Steuerberater. Tour-Ausgaben erscheinen automatisch hier.

**10.10 Tourübersicht:** Filter Unterwegs · Geplant · Abgeschlossen, Suche nach Fahrer/Datum. Karte „Heute unterwegs“. Detail: mitgenommen, zurück, verkauft + Wert, Ausgaben, Bargeld, Differenz + Begründung, Lieferschein/Rechnung, erstellt/abgeschlossen von. „Tour als PDF teilen“.

**10.11 Auswertungen:** Zeitraum Tag · Woche · Monat · Jahr · eigen. Karten: Umsatz netto, Wareneinsatz, Ausgaben, Gewinn, % zum Vorzeitraum, Lagerwert EK. Diagramme: Umsatz vs. Ausgaben, Top-Produkte, Ausgaben nach Kategorie. Warenbewegung verkauft/zurück. Fahrerstatistik: Touren, Umsatz, Ø pro Tour, Rücklaufquote, Kassendifferenzen. Filter Fahrer/Produkt, Bericht als PDF.

**10.12 Weitere Screens:** Leerzustände, Löschbestätigung, Offline-Banner, Ladezustand, Fehlerseite, Benutzerverwaltung, Fahrerliste, Firmendaten, Speicherverbrauch, Impressum & Datenschutz.

## 11. Recht (Deutschland)

- DSGVO: Daten in Frankfurt, Datenschutzerklärung + Impressum in der App, Konto-Löschung, kein Tracking.
- § 14 UStG: Pflichtangaben, fortlaufende Rechnungsnummern.
- GoBD: festgeschriebene Rechnungen unveränderbar, Storno statt Löschen, audit_log, 10 Jahre Aufbewahrung (Backups).
- Datenmodell E-Rechnung-fähig (ZUGFeRD/XRechnung später).

## 12. Performance

App-Start < 2 s, 60 fps; PDF-Erstellung in einem Isolate (`compute`); nur benötigte Spalten abfragen, Pagination; Bilder komprimiert, Thumbnails, Signed URLs cachen.

## 13. Tests

Dart Unit-Tests (Geschäftslogik ≥ 90 %):
- 13 Kartons × 4 + 3 = 55 Gläser
- 55 geladen − 7 zurück = 48 verkauft
- Umsatz 903,00 € − Ausgaben 35,00 € = Soll 868,00 €; übergeben 860,00 € → Fehlbetrag −8,00 €
- Rechnung mit 7 % und 19 % gemischt, Rundung korrekt
- 12,5 kg → 12500 g
- zurück > geladen → Fehler

pgTAP: RLS (office darf keine Benutzer ändern; inaktive Benutzer sehen nichts; festgeschriebene Rechnung nicht änderbar); start_tour bei zu wenig Bestand → Fehler, nichts gebucht; close_tour bucht Rückgaben korrekt; next_number parallel → keine Duplikate.
Widget-Tests: QuantityInput, Formulare.
Integrationstest: Anmelden → Produkt → Tour planen → starten → abschließen → Lieferschein unterschreiben → PDF → Rechnung festschreiben.

## 14. Build, CI/CD, Veröffentlichung

- Flavors dev (lokales Supabase) und prod (Frankfurt), eigene Bundle-ID/Package-Name, `--dart-define-from-file`.
- Git + GitHub, Branches main / develop / feature/*.
- GitHub Actions: bei Push `flutter analyze`, `dart format --set-exit-if-changed`, Tests, `supabase db lint`, pgTAP gegen lokales Supabase; bei Release-Tag Migrationen auf prod (`supabase db push`), iOS → TestFlight, Android AAB → Play Interner Test (fastlane); nächtlich Backup.
- iOS: deutsche Berechtigungstexte (Kamera, Fotos), Konto-Löschung, App-Privacy-Angaben. Android: aktuelles Ziel-SDK, AAB, Play App Signing, Data Safety.
- App-Icon, Splash, Store-Beschreibung Deutsch, Screenshots. Semantic Versioning, automatische Build-Nummer.
- README: Einrichtung, `supabase start`, Migrationen, Flavors, Build, Release, Backup wiederherstellen, Wechsel auf Pro.

## 15. Vorgehen (Reihenfolge)

Nach jedem Schritt: lauffähiger Code, Tests grün, kurze Erklärung, auszuführende Befehle. Bei Unklarheit nachfragen statt raten.

1. Projekt-Setup: Flutter, Flavors, Theme, Router, Lints, Supabase CLI, erste Migration, CI, Backup-Workflow
2. Auth, profiles, Rollen, RLS-Grundgerüst, Benutzer- und Fahrerverwaltung, Edge Functions invite-user / delete-account
3. Produkte + Lager + Wareneingang + Korrektur + Bewegungen
4. Tour planen + Beladung + Wert + start_tour
5. Tour abschließen + Rückgabe + Geld + Ausgaben + close_tour
6. Lieferschein + Unterschrift + PDF + Teilen
7. Ausgabenbelege + Scan + Monatsordner + Sammel-PDF
8. Rechnungen + Nummernkreis + finalize/cancel + PDF + Cron überfällig
9. Auswertungen + Views + Diagramme + Fahrerstatistik + PDF-Bericht
10. Offline-Cache + Entwürfe, Leerzustände, Barrierefreiheit, Speicheranzeige, Store-Vorbereitung

## 16. Projektstruktur: Tests, Skripte, Workflows, Doku

```
test/                                          # spiegelt lib/
├── core/value_objects/money_test.dart
├── core/value_objects/quantity_test.dart      # 13 × 4 + 3 = 55
├── core/value_objects/vat_rate_test.dart
├── core/formatting/money_formatter_test.dart
├── features/tours/domain/load_calculator_test.dart
├── features/tours/domain/settlement_calculator_test.dart   # 903 − 35 = 868, −8 €
├── features/invoices/domain/invoice_calculator_test.dart   # 7 % + 19 % gemischt
├── shared/widgets/inputs/quantity_input_test.dart
├── shared/widgets/display/difference_banner_test.dart
└── helpers/
    ├── fakes.dart                             # Fake-Repositories
    ├── fixtures.dart                          # Beispiel-Produkte, -Touren
    └── pump_app.dart                          # Widget mit Theme + Providern starten

integration_test/
└── full_tour_flow_test.dart                   # Login → Tour → Abschluss → Lieferschein → Rechnung

scripts/
├── setup.sh                                   # flutter pub get, supabase start, codegen
├── codegen.sh                                 # build_runner + gen-l10n
├── reset_local_db.sh                          # supabase db reset (Migrationen + seed)
├── backup.sh                                  # db dump + Storage-Download, gpg-verschlüsselt
└── restore.sh                                 # Backup zurückspielen

.github/workflows/
├── ci.yml                                     # analyze, format, Tests, pgTAP, db lint
├── release.yml                                # db push prod, TestFlight, Play Intern
└── backup.yml                                 # nächtlich 02:30, Aufbewahrung 30 Tage / 10 Jahre

docs/
├── SPEC.md                                    # diese Spezifikation
├── architecture.md                            # Schichten, Regeln, Ablauf
├── database.md                                # Tabellen, Funktionen, RLS erklärt
├── calculations.md                            # alle Formeln mit Beispielen
├── release.md                                 # Store-Veröffentlichung Schritt für Schritt
└── backup_restore.md                          # Wiederherstellung + Wechsel zu Supabase Pro
```

Hinweise:
- `shared/widgets/` ist gegliedert in `inputs/` (z. B. QuantityInput) und `display/` (z. B. DifferenceBanner); die Widgets aus Abschnitt 9 werden dort einsortiert.
- Berechnungs-Klassen liegen je Feature in `domain/` (LoadCalculator, SettlementCalculator, InvoiceCalculator), Value Objects (Money, Quantity, VatRate) in `core/value_objects/`.
- Skripte sind Bash (`.sh`); unter Windows über Git Bash oder WSL ausführen.
- Die Backup-Aufbewahrung (30 Tage / 10 Jahre) gilt für `backup.yml` (Abschnitt 7).

### Änderungen durch `docs/spec/` (Stand 2026-11-22)
- Tests (Abschnitt 13): nur Dart-Unit-Tests der Berechnungen + 2 DB-Tests; **kein** `integration_test/`, keine Widget-/RLS-Tests, keine Mindestabdeckung (`spec/tests.md`). Im Baum oben entfallen `integration_test/`, `test/helpers/`, `test/shared/`, `vat_rate_test`, `money_formatter_test`.
- CI (`ci.yml`): nur `flutter analyze` und `flutter test`. Datenbank-Tests lokal (`make test-backend`).
- Sicherheit (Abschnitt 6): einfache RLS, kein `audit_log`, kein Sentry, keine Edge Function `invite-user` (`spec/security.md`).
- PDF-Baukasten unter `lib/core/pdf/` und `lib/features/*/pdf/` (`spec/pdf.md`).
