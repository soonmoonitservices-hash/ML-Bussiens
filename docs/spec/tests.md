# Tests (nur das Wichtigste)

Ersetzt Abschnitt 13 in `docs/SPEC.md`. Nur die Geld- und Mengenberechnungen werden automatisch getestet. Alles andere wird manuell getestet (`docs/testing_checklist.md`).

## Pflicht – Dart Unit-Tests (reine Logik, schnell, kein Supabase)
- `test/core/value_objects/money_test.dart`
  - „12,50“ → 1250 Cent, 1250 Cent → „12,50 €“
  - Addieren, Subtrahieren, Multiplizieren ohne Rundungsfehler
- `test/core/value_objects/quantity_test.dart`
  - 13 Kartons × 4 + 3 Gläser = 55 Gläser
  - 55 Gläser → „13 Kartons + 3 Gläser“
  - „12,5“ kg → 12500 g
- `test/features/tours/domain/settlement_calculator_test.dart`
  - 55 geladen − 7 zurück = 48 verkauft
  - zurück > geladen → Fehler
  - Umsatz 903,00 € − Ausgaben 35,00 € = Soll 868,00 €
  - Bargeld 860,00 € → Fehlbetrag −8,00 €
  - Bargeld 870,00 € → Überschuss +2,00 €
  - Bargeld 868,00 € → Kasse stimmt
  - Tourgewinn = Umsatz − Wareneinsatz − Ausgaben
- `test/features/tours/domain/load_calculator_test.dart`
  - Warenwert EK, Warenwert VK, erwarteter Gewinn
- `test/features/invoices/domain/invoice_calculator_test.dart`
  - nur 7 %, nur 19 %, gemischt 7 % + 19 %
  - USt getrennt ausgewiesen, kaufmännisch gerundet
  - Netto + USt = Brutto (Cent-genau)

## Pflicht – 2 Datenbank-Tests (SQL, gegen lokales Supabase)
- `supabase/tests/start_tour.test.sql`: zu wenig Bestand → Fehler, nichts wird gebucht
- `supabase/tests/close_tour.test.sql`: Rückgaben gehen korrekt ins Lager zurück

## Weglassen
- Keine Widget-Tests
- Keine Integrationstests (der Ordner `integration_test/` entfällt)
- Keine RLS-Tests
- Keine Mindest-Testabdeckung

## CI (GitHub Actions) bei jedem Push
- `flutter analyze`
- `flutter test`
- Datenbank-Tests nur lokal vor einem Release ausführen (`make test-backend`)

## Manuelle Test-Checkliste
`docs/testing_checklist.md`, vor jeder Auslieferung auf 1 iPhone und 1 Android-Handy durchklicken.

## PDF-Tests (aus `docs/spec/pdf.md`)
- Ein Unit-Test pro Dokument: PDF wird ohne Fehler erzeugt, mit 1 Position und mit 60 Positionen (Mehrseitigkeit)
- Dateinamen-Funktion testen (Umlaute, Sonderzeichen)
- Kein Golden-Test
