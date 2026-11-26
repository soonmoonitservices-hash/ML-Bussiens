# Backend-API (Supabase RPC)

Die App ruft für wichtige Aktionen NUR diese Funktionen auf. Alle prüfen zuerst „angemeldet und aktiv“, laufen in einer Transaktion und liefern deutsche Fehlermeldungen. Die App zeigt `PostgrestException.message` 1:1 an.

- Geld: Cent (`bigint`). Gewicht: Gramm. Mengen immer in der Basiseinheit (Stück/Glas/Karton, bei kg in Gramm). Preise bei kg: Cent pro Kilogramm.
- Fehler kommen als `PostgrestException` (`e.message` ist der deutsche Text).
- Nicht aufrufbar (nur intern): `next_number`, `mark_overdue_invoices` und alle Funktionen mit `_` am Anfang.
- Ohne Login aufrufbar: nur `get_app_config`.

```dart
try {
  await supabase.rpc('start_tour', params: {'p_tour_id': tourId});
} on PostgrestException catch (e) {
  showError(e.message); // z. B. „Nicht genug Bestand für ‚Grüne Oliven‘ (es fehlen 8).“
}
```

## Lager

### `stock_intake(p_product_id uuid, p_qty bigint, p_reason text default null)` → `bigint`
Wareneingang. Gibt den neuen Bestand zurück.
Fehler: „Die Menge muss größer als 0 sein.“ · „Produkt nicht gefunden.“ · „Das Produkt ist deaktiviert.“
```dart
final newStock = await supabase.rpc('stock_intake',
    params: {'p_product_id': id, 'p_qty': 48, 'p_reason': 'Lieferung'}) as int;
```

### `stock_correct(p_product_id uuid, p_new_stock bigint, p_reason text)` → `bigint`
Bestand auf einen gezählten Wert setzen. Begründung ist Pflicht.
Fehler: „Bitte eine Begründung für die Korrektur angeben.“ · „Der Bestand darf nicht negativ sein.“ · „Der Bestand ist bereits N.“
```dart
await supabase.rpc('stock_correct',
    params: {'p_product_id': id, 'p_new_stock': 396, 'p_reason': 'Bruch'});
```

### `import_products(p_rows jsonb)` → `integer`
CSV-Import in EINER Transaktion; bei einem Fehler wird nichts angelegt. Zeilen: `name, category, unit (carton|piece|jar|kg), units_per_carton, buy_price_net_cents, sell_price_net_cents, vat_rate, min_stock, stock`. Bestand > 0 erzeugt die Lagerbewegung „Anfangsbestand“.
Fehler: „Die Importliste ist leer.“ · „Zeile N: <Grund>“ (N = Position in der Liste, beginnend bei 1)
```dart
final count = await supabase.rpc('import_products', params: {'p_rows': rows}) as int;
```

## Touren

Tour und Positionen legt die App direkt per `insert` an (nur `driver_id`, `product_id` und `loaded_qty`; Name, Einheit und Preise kopiert die Datenbank). Status ändern nur diese Funktionen.

### `start_tour(p_tour_id uuid)` → `void`
Nur Entwurf mit Positionen und aktivem Fahrer. Aktualisiert die Preise, bucht die Ware ab, vergibt die Nummer (T-2026-001), Status „unterwegs“.
Fehler: „Nur Entwürfe können gestartet werden.“ · „Der Fahrer ist deaktiviert.“ · „Bitte zuerst die Ware für die Tour auswählen.“ · „Nicht genug Bestand für ‚…‘ (es fehlen N).“
```dart
await supabase.rpc('start_tour', params: {'p_tour_id': tourId});
```

### `undo_start_tour(p_tour_id uuid)` → `void`
Unterwegs → Entwurf, Ware zurück ins Lager (Nummer bleibt).
Fehler: „Nur Touren, die unterwegs sind, können zurückgenommen werden.“

### `close_tour(p_tour_id uuid, p_returns jsonb, p_cash_received_cents bigint, p_difference_reason text default null)` → `void`
Rückgabe prüfen und einbuchen, Abrechnung berechnen und einfrieren. `p_returns`: `[{"product_id": "...", "returned_qty": 7}]`; nicht genannte Produkte = 0 zurück. Optional `"gift_qty"` je Produkt (verschenkte Menge in Basiseinheit): kein Umsatz, kein Rücklauf ins Lager, Einkaufspreis zählt als Wareneinsatz; zurück + geschenkt höchstens geladen.
Formeln: siehe `docs/calculations.md`.
Fehler: „Nur Touren, die unterwegs sind, können abgeschlossen werden.“ · „Bitte den vom Fahrer übergebenen Geldbetrag eintragen.“ · „Zurückgebracht für ‚…‘ muss zwischen 0 und N liegen.“ · „Ein Produkt wurde mehrfach angegeben.“ · „Ein Produkt in der Rückgabe gehört nicht zu dieser Tour.“ · „Die Kasse stimmt nicht (Differenz -8,00 €). Bitte eine Begründung angeben.“
```dart
await supabase.rpc('close_tour', params: {
  'p_tour_id': tourId,
  'p_returns': [
    {'product_id': olivesId, 'returned_qty': 7},
    {'product_id': cheeseId, 'returned_qty': 2000}, // 2 kg
  ],
  'p_cash_received_cents': 86000,
  'p_difference_reason': 'Zwei Kisten beim Kunden vergessen',
});
```

### `reopen_tour(p_tour_id uuid)` → `void`
Nur Chef. Abgeschlossen → unterwegs, Rückgaben wieder aus dem Lager, eingefrorene Werte gelöscht.
Fehler: „Dafür ist die Rolle Chef nötig.“ · „Nur abgeschlossene Touren können wieder geöffnet werden.“ · „Nicht genug Bestand für ‚…‘ (es fehlen N).“

## Rechnungen

Entwurf und Positionen legt die App per `insert` an (Positionen: `invoice_id`, `product_id`, `qty`, optional `price_net_cents` für Rabatt; freie Position: `product_name`, `unit`, `vat_rate`, `qty`, `price_net_cents`). Summen berechnet die Datenbank.

### `finalize_invoice(p_invoice_id uuid)` → `text`
Festschreiben: Nummer (RE-2026-001), Fälligkeit, Summen; ohne Tour wird die Ware abgebucht. Gibt die Nummer zurück. Danach nur noch `pdf_path` änderbar.
Fehler: „Nur Entwürfe können festgeschrieben werden.“ · „Bitte Name und Adresse des Empfängers eintragen.“ · „Bitte mindestens eine Position hinzufügen.“ · „Bitte zuerst in den Firmendaten ergänzen: Firmenname, Adresse, Steuernummer oder USt-IdNr..“ · „Nicht genug Bestand für ‚…‘ (es fehlen N).“
```dart
final number = await supabase.rpc('finalize_invoice', params: {'p_invoice_id': id}) as String;
```

### `cancel_invoice(p_invoice_id uuid)` → `uuid`
Nur Chef. Erzeugt die Stornorechnung (negative Werte, eigene Nummer), beide „storniert“, Ware zurück ins Lager. Gibt die ID der Stornorechnung zurück.
Fehler: „Dafür ist die Rolle Chef nötig.“ · „Entwürfe werden gelöscht, nicht storniert.“ · „Eine Stornorechnung kann nicht storniert werden.“ · „Diese Rechnung ist bereits storniert.“

### `mark_invoice_paid(p_invoice_id uuid, p_paid_at date default null)` → `void`
Fehler: „Nur offene Rechnungen können als bezahlt markiert werden.“ · „Das Zahlungsdatum darf nicht in der Zukunft liegen.“

### `mark_invoice_unpaid(p_invoice_id uuid)` → `void`
Fehler: „Nur bezahlte Rechnungen können wieder auf offen gesetzt werden.“

### `invoice_from_delivery_note(p_delivery_note_id uuid)` → `uuid`
Neue Entwurfsrechnung mit Empfänger und Positionen. Gibt die Rechnungs-ID zurück.
Fehler: „Lieferschein nicht gefunden.“ · „Für diesen Lieferschein gibt es bereits eine Rechnung.“

## Lieferscheine

Kein RPC nötig. Nummer (LS-2026-001) vergibt die Datenbank beim `insert`. Unterschreiben = `update` mit `signature_path`, `signer_name`, `signed_at`.
Fehler: „Zum Unterschreiben braucht der Lieferschein mindestens eine Position.“ · „Bitte den Namen des Unterzeichners eintragen.“ · „Das Unterschriftsbild fehlt.“ · „Ein unterschriebener Lieferschein kann nicht mehr geändert werden.“ · „Ein unterschriebener Lieferschein kann nicht gelöscht werden.“

## Auswertungen (nur lesen)

```dart
final kpis = await supabase.rpc('report_kpis',
    params: {'p_from': '2026-11-01', 'p_to': '2026-11-30'});
```
| Funktion | Parameter | Spalten |
|---|---|---|
| `report_kpis` | `p_from`, `p_to` (date) | `revenue_net_cents, cost_cents, expenses_net_cents, profit_cents, tour_count, invoice_count, stock_value_cents` |
| `report_timeseries` | `p_from`, `p_to`, `p_granularity` (`day`/`week`/`month`) | `period_start, revenue_net_cents, expenses_net_cents, profit_cents` |
| `report_driver_stats` | `p_from`, `p_to` | `driver_id, driver_name, tour_count, revenue_net_cents, avg_revenue_per_tour_cents, return_rate, difference_sum_cents, shortage_sum_cents` |
| `report_top_products` | `p_from`, `p_to`, `p_limit` (Standard 10) | `product_id, product_name, unit, sold_qty, revenue_net_cents` |
| `report_expenses_by_category` | `p_from`, `p_to` | `category, expense_count, gross_cents, net_cents` |

Views (per `from('…').select()`): `v_stock_overview`, `v_tour_overview`, `v_expenses_by_month`, `v_open_invoices`.

Fehler bei `report_timeseries`: „Unbekannte Gruppierung ‚…‘ (erlaubt: day, week, month).“

## App-Konfiguration

### `get_app_config()` → `app_config` (auch ohne Login)
`min_version_ios, min_version_android, message, ios_store_url, android_store_url`. Beim Start prüfen; ist die App älter → Vollbild „Bitte aktualisieren“.
```dart
final config = await supabase.rpc('get_app_config');
```

## Interne Funktionen (nicht für die App)
`next_number(type)` (lückenlose Nummernkreise `tour`, `delivery_note`, `invoice`), `mark_overdue_invoices()` (täglich 01:00 UTC per pg_cron: offen + fällig → überfällig), `_move_stock`, `_recalc_invoice` u. a.
`next_number` ist absichtlich nicht aufrufbar: würde die App Nummern abrufen, entstünden Lücken.

## Direkte Tabellenzugriffe und ihre Sperren
Die App darf per `insert/update/delete` auf Fahrer, Produkte, Touren (Entwurf), Positionen, Ausgaben, Lieferscheine und Rechnungs-Entwürfe zugreifen. Die Datenbank sperrt per Trigger: Lagerbestand (`products.stock`), Status/Nummern/Summen, abgeschlossene Touren und deren Ausgaben, unterschriebene Lieferscheine, festgeschriebene Rechnungen. `stock_movements` und `number_counters` sind nur lesbar.

## Änderungen vom 2026-11-23
- **Kein Lagerbestand mehr** (Migration 29): `stock_intake`, `stock_correct`, die Tabelle `stock_movements`, die Sicht `v_stock_overview` und die Spalten `products.stock` und `min_stock` sind entfernt. `start_tour`, `close_tour`, `finalize_invoice` und `cancel_invoice` buchen nichts mehr vom Lager. `report_kpis` liefert keinen `stock_value_cents` mehr. „Zurück“ und „geschenkt“ bei einer Tour bleiben (sie bestimmen den Umsatz).
- **Alles löschbar** (Migration 30): `delete_tour(p_tour_id)` (mit Positionen und Tour-Ausgaben), `delete_delivery_note(p_delivery_note_id)` (auch unterschrieben), `delete_invoice(p_invoice_id)` (auch festgeschrieben). Der Aufruf löst Verweise anderer Datensätze (`tour_id`, `delivery_note_id`, Storno-Verweise werden leer). Direktes `delete` auf den Tabellen bleibt für Nicht-Entwürfe gesperrt. Dart: `await supabase.rpc('delete_invoice', params: {'p_invoice_id': id});`
- Mehrwertsteuer: wird nur noch bei Rechnungen gewählt; Produkte, Touren und Ausgaben rechnen mit 0 %.
