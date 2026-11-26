# Backend (Supabase) – einmal sauber bauen, nicht mehr anfassen

Ersetzt die Backend-Abschnitte 4–7 in `docs/SPEC.md`, wo sie sich widersprechen. Ergänzungen: `docs/spec/technical.md`.
Ziel: Alle Regeln, Berechnungen und Sperren liegen in der Datenbank. Die App zeigt nur an und ruft Funktionen auf. Auch bei einem App-Fehler dürfen die Daten nie falsch werden.

## Allgemein
- Supabase Free-Plan, Region Frankfurt (eu-central-1)
- Alles als SQL-Migrationen in `supabase/migrations`, nummeriert, nur vorwärts
- Alle Funktionen mit `set search_path = public`
- Fehlermeldungen in der Datenbank auf DEUTSCH und verständlich (z. B. „Nicht genug Bestand für ‚Grüne Oliven‘ (es fehlen 8).“), die App zeigt sie 1:1 an
- Öffentliche Registrierung aus; Benutzer legt der Chef an
- Erster angelegter Benutzer wird automatisch Chef, alle weiteren Verwaltung
- Es bleibt immer mindestens ein aktiver Chef (Trigger verhindert Löschen, Deaktivieren, Herabstufen des letzten Chefs)

## Datentypen
- Geld: bigint in Cent. Gewicht: bigint in Gramm; Preis bei kg-Produkten = Cent pro Kilogramm. Stück/Gläser/Kartons: bigint.
- Zentrale Funktion `line_value_cents(unit, qty, price)` für ALLE Wertberechnungen (bei kg: qty × price / 1000, kaufmännisch gerundet)
- Zentrale Funktion `gross_cents(net, vat_rate)` für Brutto
- Datum immer Europe/Berlin (`berlin_today()`)
- Jede Tabelle hat created_at, created_by, updated_at, updated_by (Trigger setzt sie; created_* nicht überschreibbar)

## Tabellen
- profiles (id = auth.users.id, name, email, role chef|office, active)
- company_settings (genau 1 Zeile): Firmendaten, Bank, Steuernummer, USt-IdNr., Logo, Zahlungsziel in Tagen (Standard 14), Rechnungs-Fußtext, `cash_includes_vat` (true = Fahrer kassiert Bruttopreise → Soll-Bargeld brutto), Kleinunternehmer-Schalter
- drivers (name, phone, vehicle, active) – kein Login
- products (sku automatisch ART-001, name, category, unit carton|piece|jar|kg, units_per_carton nur bei piece/jar, buy/sell price netto, vat_rate 0|7|19, min_stock, stock, image_path, active)
- stock_movements (product_id, type, qty ±, stock_after, reason, ref_table, ref_id); type: intake | tour_out | tour_return | tour_undo | invoice | invoice_cancel | correction
- tours (number T-2026-001, driver_id, driver_name als Kopie, planned_at, status draft|active|closed, started_at/by, closed_at/by, cash_received_cents, difference_reason; beim Abschluss eingefroren: revenue_net, revenue_gross, cost, expenses_gross, expenses_net, expected_cash, difference, profit)
- tour_items (tour_id, product_id, Kopie Name/Einheit/Inhalt pro Karton/Preise/USt, loaded_qty, returned_qty, sold_qty als generierte Spalte, unique (tour_id, product_id), returned_qty ≤ loaded_qty)
- expenses = EINE Tabelle für alle Ausgaben und Belege (mit/ohne Foto): date, year_month (generiert „2026-11“), title, category, gross_cents, vat_rate, net_cents + vat_cents (generiert), image_path, tour_id (optional), note. Tour-Ausgaben sind Ausgaben mit tour_id. Keine zweite Tabelle.
- delivery_notes (number LS-2026-001, date, recipient_name, recipient_address, tour_id, note, signature_path, signer_name, signed_at, pdf_path)
- delivery_note_items (product_id, Kopie Name/Einheit, qty, position)
- invoices (number RE-2026-001 erst beim Festschreiben, date, service_date, due_date, recipient, note, net, vat7, vat19, gross, cost (Wareneinsatz), status draft|open|paid|overdue|cancelled, finalized_at/by, paid_at, cancels_invoice_id, cancelled_by_invoice_id, tour_id, delivery_note_id, stock_booked, pdf_path)
- invoice_items (product_id oder null = freie Position, Kopie Name/Einheit/USt/EK, qty (negativ nur bei Storno), price_net_cents, line_net_cents)
- number_counters (type, year, last_value)
- Sinnvolle Indizes auf allen Fremdschlüsseln, Status- und Datumsfeldern

## Kopien (Snapshots)
- Beim Hinzufügen einer Position (Tour, Lieferschein, Rechnung) kopiert ein Trigger Name, Einheit, Inhalt pro Karton, Preise und USt vom Produkt. Die App schickt nur product_id + Menge.
- Beim Tourstart werden die Preise der Tour-Positionen noch einmal aktualisiert, danach eingefroren.
- Bei Rechnungen darf der Verkaufspreis abweichen (Rabatt), sonst Preis vom Produkt.
- Spätere Preisänderungen am Produkt verändern NIE alte Touren oder Rechnungen.

## Sperren (Trigger, nicht nur in der App)
- products.stock nur über Funktionen änderbar; Anlegen mit Bestand > 0 erzeugt automatisch eine Lagerbewegung „Anfangsbestand“
- Lagerbestand nie negativ (verständliche Fehlermeldung)
- tours: Status nur über Funktionen. Entwurf frei bearbeitbar; unterwegs nur Name und Notiz; abgeschlossen gar nicht. Löschen nur als Entwurf.
- tour_items nur änderbar, solange die Tour Entwurf ist
- expenses einer abgeschlossenen Tour: nicht änderbar oder löschbar
- delivery_notes: nach der Unterschrift nur noch pdf_path änderbar, nicht löschbar. Unterschreiben nur mit Positionen, Namen des Unterzeichners und Unterschriftsbild.
- invoices: Entwurf frei bearbeitbar (aber nicht Nummer, Status, Summen); festgeschrieben nur noch pdf_path; löschen nur als Entwurf
- invoice_items: nur bei Entwurf; Summen werden bei jeder Änderung neu berechnet (Netto, USt 7 % und 19 % getrennt gerundet, Brutto, Wareneinsatz)
- Interne Funktionen ändern geschützte Felder über einen Transaktions-Schalter (`set_config 'app.bypass'`, vorherigen Wert sichern und wiederherstellen, nie dauerhaft an)

## Funktionen (RPC, security definer)
Prüfen zuerst „angemeldet und aktiv“, alles in einer Transaktion, Produkte immer in fester Reihenfolge sperren (keine Deadlocks).
- `next_number(type)`: fortlaufend pro Jahr, lückenlos, nie doppelt (Upsert mit Zeilensperre)
- `stock_intake(product_id, qty, reason)`, `stock_correct(product_id, new_stock, reason)` (Begründung Pflicht)
- `start_tour(tour_id)`: nur Entwurf mit Positionen und aktivem Fahrer; Preise aktualisieren; Ware abbuchen; Status unterwegs
- `undo_start_tour(tour_id)`: unterwegs → Entwurf, Ware zurück ins Lager
- `close_tour(tour_id, returns json [{product_id, returned_qty}], cash_received_cents, difference_reason)`: nicht genannte Produkte = 0 zurück; 0 ≤ zurück ≤ geladen; Rückgaben ins Lager; berechnet und speichert:
  - Umsatz netto = Σ line_value(verkauft, VK); Umsatz brutto = Σ gross(line_value(verkauft, VK), USt)
  - Wareneinsatz = Σ line_value(verkauft, EK)
  - Ausgaben brutto/netto = Σ expenses der Tour
  - Soll-Bargeld = (cash_includes_vat ? Umsatz brutto : Umsatz netto) − Ausgaben brutto
  - Differenz = Bargeld − Soll-Bargeld; Gewinn = Umsatz netto − Wareneinsatz − Ausgaben netto
  - Differenz ≠ 0 ohne Begründung → Fehler; Status abgeschlossen
- `reopen_tour(tour_id)`: nur Chef; abgeschlossen → unterwegs, Rückgaben wieder aus dem Lager, eingefrorene Werte löschen
- `finalize_invoice(invoice_id)`: nur Entwurf mit Positionen und Empfänger; Nummer vergeben; Fälligkeit setzen; Summen neu berechnen; ohne Tour → Ware abbuchen; Status offen
- `cancel_invoice(invoice_id)`: nur Chef; Stornorechnung mit negativen Mengen und eigener Nummer, beide „storniert“, Ware zurück ins Lager falls abgebucht; Storno einer Stornorechnung nicht möglich
- `mark_invoice_paid(invoice_id, paid_at)` / `mark_invoice_unpaid(invoice_id)`
- `invoice_from_delivery_note(delivery_note_id)` → neue Entwurfsrechnung mit Empfänger und Positionen
- `mark_overdue_invoices()`: täglich per pg_cron (01:00 UTC): offen + fällig → überfällig

## Auswertungen (Views mit security_invoker + Funktionen, nur lesen)
- v_stock_overview: Bestand, Warenwert EK, „unter Mindestbestand“, Bestand als Kartons + Rest
- v_tour_overview: pro Tour Anzahl Positionen, Ladungswert EK/VK, erwarteter Gewinn (Entwurf/unterwegs) oder eingefrorene Werte (abgeschlossen), Ausgaben live
- v_expenses_by_month: Anzahl, brutto, netto, USt pro Monat
- v_open_invoices: Summe offen, Anzahl überfällig
- `report_kpis(from, to)`: Umsatz netto, Wareneinsatz, Ausgaben netto, Gewinn, Anzahl Touren und Rechnungen, Lagerwert. Umsatz = abgeschlossene Touren (nach closed_at) + festgeschriebene Rechnungen OHNE Tour (sonst doppelt). Storno + Original heben sich auf.
- `report_timeseries(from, to, 'day'|'week'|'month')`: Umsatz, Ausgaben, Gewinn
- `report_driver_stats(from, to)`: Touren, Umsatz, Ø pro Tour, Rücklaufquote nach WERT (zurück ÷ geladen zum VK), Summe Differenzen, Summe Fehlbeträge
- `report_top_products(from, to, limit)`, `report_expenses_by_category(from, to)`

## Sicherheit
- RLS auf allen Tabellen: nur angemeldete, aktive Benutzer
- profiles: alle Aktiven lesen; nur Chef ändert Rolle/aktiv, jeder seinen Namen
- company_settings: nur Chef ändert
- stock_movements und number_counters: nur lesen, schreiben nur Funktionen
- anon hat auf nichts Zugriff
- Interne Hilfsfunktionen (mit `_` am Anfang) nicht von der App aufrufbar
- Storage: private Buckets receipts, signatures, documents, logos (+ products); nur angemeldete, aktive Benutzer
- Edge Function `delete-account` (Pflicht für App Store): Konto löschen, aber nicht den letzten Chef

## Backup & Betrieb
- GitHub Actions nachts: Datenbank-Dump + Storage-Dateien, verschlüsselt, 30 Tage + Monatsende 10 Jahre
- README: Einrichtung, Wiederherstellung, Wechsel auf Supabase Pro
- seed.sql: 2 Fahrer, 3 Produkte (Oliven Glas 4 pro Karton, Baladi-Käse kg, Olivenöl Stück 12 pro Karton) mit Anfangsbestand

## Tests (SQL-Skript gegen lokales Supabase, Ende mit rollback)
- 13 Kartons × 4 + 3 = 55 Gläser geladen, 7 zurück → 48 verkauft, Lager stimmt
- cash_includes_vat = false: Umsatz 903,00 €, Ausgaben 35,00 € → Soll 868,00 €, Bargeld 860,00 € → Differenz −8,00 €, ohne Begründung Fehler
- Zu wenig Bestand beim Tourstart → Fehler, nichts abgebucht
- Rechnung 7 % + 19 % gemischt, Rundung korrekt, Nummer RE-…-001, danach gesperrt
- Storno: Gegenrechnung mit negativen Werten, Lager zurück, Umsatz-Summe 0
- Nicht angemeldet / deaktiviert → sieht keine Daten

## API-Doku
`docs/backend_api.md`: jede RPC-Funktion mit Parametern, Rückgabe, möglichen Fehlermeldungen und einem Dart-Beispiel (`supabase.rpc('close_tour', params: {...})`).
