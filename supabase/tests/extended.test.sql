-- ---------------------------------------------------------------- 1. Tour: 55 Gläser, 48 verkauft, Kasse −8,00 €
do $$
declare
  v_tour uuid;
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
  v_cheese uuid := (select id from products where name = 'Baladi-Käse');
  v_oil uuid := (select id from products where name = 'Olivenöl 1 l');
  v_row tours;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');

  insert into tours (driver_id) values ((select id from drivers where name = 'Ahmad Khalil'))
  returning id into v_tour;
  -- 13 Kartons × 4 + 3 Gläser = 55 Gläser; 70 kg Käse = 70000 g; 10 Öl
  insert into tour_items (tour_id, product_id, loaded_qty) values
    (v_tour, v_olives, 13 * 4 + 3), (v_tour, v_cheese, 70000), (v_tour, v_oil, 10);

  assert (select product_name from tour_items where tour_id = v_tour and product_id = v_olives) = 'Grüne Oliven',
    'Name wird vom Produkt kopiert';
  assert (select sell_price_cents from tour_items where tour_id = v_tour and product_id = v_oil) = 1250,
    'Preis wird vom Produkt kopiert';

  perform start_tour(v_tour);
  select * into v_row from tours where id = v_tour;
  assert v_row.status = 'active', 'Tour ist unterwegs';
  assert v_row.number ~ '^T-[0-9]{4}-001$', format('Tournummer: %s', v_row.number);

  -- Ausgaben der Tour: 15,00 + 20,00 = 35,00 €
  insert into expenses (title, category, gross_cents, tour_id) values
    ('Diesel', 'Fahrzeug & Kraftstoff', 1500, v_tour),
    ('Essen', 'Verpflegung', 2000, v_tour);

  -- Rückgabe: 7 Gläser, 2 kg Käse, 4 Öl → verkauft 48 / 68 kg / 6 = 903,00 €
  perform _t_fails(
    format($f$select close_tour(%L, %L::jsonb, 86000, 'x')$f$, v_tour,
      format('[{"product_id":"%s","returned_qty":56}]', v_olives)),
    'Zurückgebracht für ‚Grüne Oliven‘ muss zwischen 0 und 55 liegen.');

  perform close_tour(v_tour,
    format('[{"product_id":"%s","returned_qty":7},{"product_id":"%s","returned_qty":2000},{"product_id":"%s","returned_qty":4}]',
      v_olives, v_cheese, v_oil)::jsonb,
    86000, 'Zwei Kisten beim Kunden vergessen');

  select * into v_row from tours where id = v_tour;
  assert v_row.status = 'closed', 'Tour abgeschlossen';
  assert v_row.revenue_net_cents = 90300, format('Umsatz %s', v_row.revenue_net_cents);
  assert v_row.expenses_gross_cents = 3500, 'Ausgaben 35,00 €';
  assert v_row.expected_cash_cents = 86800, 'Soll-Bargeld 868,00 €';
  assert v_row.difference_cents = -800, 'Differenz −8,00 €';
  assert v_row.cost_cents = 59520, format('Wareneinsatz %s', v_row.cost_cents);
  assert v_row.profit_cents = 26480, format('Gewinn %s (inkl. Differenz −8,00 €)', v_row.profit_cents);
  assert (select sold_qty from tour_items where tour_id = v_tour and product_id = v_olives) = 48, '48 Gläser verkauft';

  -- Gesperrt nach Abschluss
  perform _t_fails(format($f$update tours set name = 'x' where id = %L$f$, v_tour),
    'Abgeschlossene Touren können nicht geändert werden.');
  perform _t_fails(format($f$update tour_items set loaded_qty = 1 where tour_id = %L$f$, v_tour),
    'Die Ware einer Tour kann nur im Entwurf geändert werden.');
  perform _t_fails(format($f$update expenses set gross_cents = 1 where tour_id = %L$f$, v_tour),
    'Ausgaben einer abgeschlossenen Tour können nicht geändert werden.');
  perform _t_fails(format($f$delete from expenses where tour_id = %L$f$, v_tour),
    'Ausgaben einer abgeschlossenen Tour können nicht geändert werden.');
  perform _t_fails(format($f$delete from tours where id = %L$f$, v_tour),
    'Nur Entwürfe können gelöscht werden.');
  perform _t_fails(format($f$insert into expenses (title, gross_cents, tour_id) values ('Spät', 100, %L)$f$, v_tour),
    'Ausgaben einer abgeschlossenen Tour können nicht geändert werden.');


  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 2. Entwurf bearbeiten
do $$
declare
  v_tour uuid;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  insert into tours (driver_id) values ((select id from drivers where name = 'Samir Haddad'))
  returning id into v_tour;
  insert into tour_items (tour_id, product_id, loaded_qty) values
    (v_tour, (select id from products where name = 'Grüne Oliven'), 5),
    (v_tour, (select id from products where name = 'Olivenöl 1 l'), 10000);

  assert (select status from tours where id = v_tour) = 'draft', 'Tour bleibt Entwurf';
  assert (select number from tours where id = v_tour) is null, 'Keine Nummer vergeben';

  -- Entwurf bearbeiten ist erlaubt, Status ändern nicht
  update tours set name = 'Montag' where id = v_tour;
  perform _t_fails(format($f$update tours set status = 'active' where id = %L$f$, v_tour),
    'Status, Nummer und Abrechnung einer Tour ändern sich nur über die Tour-Funktionen.');
  delete from tours where id = v_tour;
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 3. Rechnung 7 % + 19 %, Festschreiben, Sperre
do $$
declare
  v_invoice uuid;
  v_spice uuid;
  v_rev_before bigint;
  v_number text;
  v_row invoices;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents, vat_rate)
  values ('Gewürzmischung', 'piece', 100, 333, 19) returning id into v_spice;
  assert (select sku from products where id = v_spice) ~ '^ART-[0-9]{3}$', 'Artikelnummer automatisch';

  select revenue_net_cents into v_rev_before
  from report_kpis(current_date - 1, current_date + 1);
  perform set_config('t.rev_before', v_rev_before::text, false);

  insert into invoices (recipient_name, recipient_address)
  values ('Kunde GmbH', 'Kundenweg 2, 20095 Hamburg') returning id into v_invoice;
  insert into invoice_items (invoice_id, product_id, qty)
  values (v_invoice, (select id from products where name = 'Grüne Oliven'), 3), (v_invoice, v_spice, 1);

  select * into v_row from invoices where id = v_invoice;
  -- Netto 1350 + 333 = 1683; USt 7 % von 1350 = 94,5 → 95; 19 % von 333 = 63,27 → 63
  assert v_row.net_cents = 1683, format('Netto %s', v_row.net_cents);
  assert v_row.vat7_cents = 95, format('USt 7 %% %s', v_row.vat7_cents);
  assert v_row.vat19_cents = 63, format('USt 19 %% %s', v_row.vat19_cents);
  assert v_row.gross_cents = 1841, format('Brutto %s', v_row.gross_cents);
  assert v_row.cost_cents = 1000, format('Wareneinsatz %s', v_row.cost_cents);
  assert v_row.number is null and v_row.status = 'draft', 'Entwurf ohne Nummer';

  -- Summen und Status sind nicht von Hand änderbar
  perform _t_fails(format('update invoices set gross_cents = 1 where id = %L', v_invoice),
    'Nummer, Status und Summen einer Rechnung ändern sich nur über die Rechnungs-Funktionen.');
  perform _t_fails(format($f$update invoices set status = 'paid' where id = %L$f$, v_invoice),
    'Nummer, Status und Summen einer Rechnung ändern sich nur über die Rechnungs-Funktionen.');

  v_number := finalize_invoice(v_invoice);
  assert v_number ~ '^RE-[0-9]{4}-001$', format('Rechnungsnummer %s', v_number);
  select * into v_row from invoices where id = v_invoice;
  assert v_row.status = 'open', 'Rechnung offen';
  assert v_row.due_date = v_row.date + 14, 'Fälligkeit nach 14 Tagen';
  assert v_row.is_small_amount, '18,41 € ist eine Kleinbetragsrechnung';

  -- Änderungsverlauf: Festschreiben ist mit Nummer und Status nachvollziehbar
  assert exists (
    select 1 from change_log
    where table_name = 'invoices' and record_id = v_invoice and action = 'update'
      and new_data ->> 'status' = 'open' and old_data ->> 'status' = 'draft' and changed_by is not null
  ), 'Änderungsverlauf der Rechnung';
  assert (select count(*) from change_log where table_name = 'tours' and action = 'update') >= 2,
    'Änderungsverlauf der Touren (Start, Abschluss)';
  perform _t_fails($f$insert into change_log (table_name, record_id, action) values ('x', gen_random_uuid(), 'insert')$f$,
    'permission denied%');

  -- Danach gesperrt (nur das PDF darf ergänzt werden)
  perform _t_fails(format($f$update invoices set note = 'x' where id = %L$f$, v_invoice),
    'Eine festgeschriebene Rechnung kann nicht mehr geändert werden.');
  perform _t_fails(format('update invoice_items set qty = 9 where invoice_id = %L', v_invoice),
    'Die Positionen einer festgeschriebenen Rechnung können nicht geändert werden.');
  perform _t_fails(format('delete from invoice_items where invoice_id = %L', v_invoice),
    'Die Positionen einer festgeschriebenen Rechnung können nicht geändert werden.');
  perform _t_fails(format('delete from invoices where id = %L', v_invoice),
    'Nur Entwürfe können gelöscht werden. Festgeschriebene Rechnungen werden storniert.');
  update invoices set pdf_path = 'documents/2026/rechnung/x.pdf' where id = v_invoice;
  perform _t_fails(format('select finalize_invoice(%L)', v_invoice), 'Nur Entwürfe können festgeschrieben werden.');

  assert (select revenue_net_cents from report_kpis(current_date - 1, current_date + 1)) = v_rev_before + 1683,
    'Umsatz enthält die Rechnung';
  perform set_config('t.invoice', v_invoice::text, false);
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 4. Storno: Gegenrechnung, Lager zurück, Umsatz 0
do $$
declare
  v_invoice uuid := current_setting('t.invoice')::uuid;
  v_storno uuid;
  v_row invoices;
begin
  -- Die Verwaltung darf alles, genau wie der Chef (auch stornieren)
  perform _t_login('c0000000-0000-4000-8000-000000000002');

  v_storno := cancel_invoice(v_invoice);
  select * into v_row from invoices where id = v_storno;
  assert v_row.gross_cents = -1841 and v_row.net_cents = -1683, 'Storno mit negativen Beträgen';
  assert v_row.number ~ '^RE-[0-9]{4}-002$', format('Stornonummer %s', v_row.number);
  assert v_row.status = 'cancelled' and v_row.cancels_invoice_id = v_invoice, 'Storno verweist aufs Original';
  assert (select status from invoices where id = v_invoice) = 'cancelled', 'Original storniert';
  assert (select cancelled_by_invoice_id from invoices where id = v_invoice) = v_storno, 'Original verweist auf Storno';
  assert (select count(*) from invoice_items where invoice_id = v_storno and qty < 0) = 2, 'Negative Mengen';
  assert (select revenue_net_cents from report_kpis(current_date - 1, current_date + 1))
         = current_setting('t.rev_before')::bigint, 'Storno + Original heben sich auf';
  assert (select invoice_count from report_kpis(current_date - 1, current_date + 1)) = 1, 'Storno zählt nicht als Rechnung';

  perform _t_fails(format('select cancel_invoice(%L)', v_invoice), 'Diese Rechnung ist bereits storniert.');
  perform _t_fails(format('select cancel_invoice(%L)', v_storno), 'Eine Stornorechnung kann nicht storniert werden.');
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 5. Zugriff: anon, abgemeldet, deaktiviert
do $$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  set local role anon;
  perform _t_fails('select count(*) from products', 'permission denied%');
  perform _t_fails('select * from profiles', 'permission denied%');
  perform _t_fails($f$select start_tour('00000000-0000-0000-0000-000000000000')$f$, 'permission denied%');
  assert (select min_version_ios from get_app_config()) = '0.0.0', 'App-Konfiguration ist ohne Login lesbar';
  reset role;

  -- angemeldet, aber Konto deaktiviert: sieht nichts, kann nichts
  perform _t_login('c0000000-0000-4000-8000-000000000003');
  assert (select count(*) from products) = 0, 'Deaktivierter Benutzer sieht keine Produkte';
  assert (select count(*) from tours) = 0, 'Deaktivierter Benutzer sieht keine Touren';
  perform _t_fails($f$select start_tour(gen_random_uuid())$f$, 'Ihr Konto ist deaktiviert.');
  perform _t_fails($f$insert into drivers (name) values ('X')$f$, 'new row violates row-level security%');
  perform _t_logout();

  -- ohne Benutzer-ID
  perform _t_login_anonymous();
  assert (select count(*) from products) = 0, 'Ohne Anmeldung keine Daten';
  perform _t_fails($f$select start_tour(gen_random_uuid())$f$, 'Bitte melden Sie sich an.');
  perform _t_logout();

  -- interne Funktionen und Nummernkreise sind für die App gesperrt
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  perform _t_fails($f$select next_number('tour')$f$, 'permission denied%');
  perform _t_fails($f$select mark_overdue_invoices()$f$, 'permission denied%');
  perform _t_fails($f$update number_counters set last_value = 0$f$, 'permission denied%');
  perform _t_fails($f$truncate products$f$, 'permission denied%');
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 6. Rollen und letzter Chef
do $$
declare
  v_chef uuid := 'c0000000-0000-4000-8000-000000000001';
  v_office uuid := 'c0000000-0000-4000-8000-000000000002';
begin
  -- Die Verwaltung darf alles, genau wie der Chef: Profile und Firmendaten der eigenen Firma ändern
  perform _t_login(v_office);
  update profiles set name = 'Neuer Name' where id = v_office;
  assert (select name from profiles where id = v_office) = 'Neuer Name', 'Eigener Name änderbar';
  update profiles set name = 'Anderer Chefname' where id = v_chef;
  update company_settings set name = 'Testfirma Neu GmbH';
  perform _t_logout();
  assert (select name from profiles where id = v_chef) = 'Anderer Chefname', 'Verwaltung ändert auch das Profil des Chefs';
  assert (select name from company_settings) = 'Testfirma Neu GmbH', 'Verwaltung ändert die Firmendaten';
  update profiles set name = 'Test Chef' where id = v_chef;
  update company_settings set name = 'Testfirma GmbH' where tenant_id = 'a0000000-0000-4000-8000-000000000001';

  perform _t_login(v_chef);
  perform _t_fails(format('update profiles set active = false where id = %L', v_chef),
    'Es muss mindestens ein aktiver Chef bleiben.');
  perform _t_fails(format($f$update profiles set role = 'office' where id = %L$f$, v_chef),
    'Es muss mindestens ein aktiver Chef bleiben.');
  perform _t_logout();
  perform _t_fails(format('delete from auth.users where id = %L', v_chef),
    'Es muss mindestens ein aktiver Chef bleiben.');
end $$;

-- ---------------------------------------------------------------- 7. Lieferschein und Rechnung daraus
do $$
declare
  v_note uuid;
  v_invoice uuid;
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  insert into delivery_notes (recipient_name, recipient_address)
  values ('Markt Süd', 'Marktplatz 5, 80331 München') returning id into v_note;
  assert (select number from delivery_notes where id = v_note) ~ '^LS-[0-9]{4}-001$', 'Lieferscheinnummer';
  insert into delivery_note_items (delivery_note_id, product_id, qty) values (v_note, v_olives, 8);

  perform _t_fails(format($f$update delivery_notes set signed_at = now(), signature_path = 'signatures/x.png' where id = %L$f$, v_note),
    'Bitte den Namen des Unterzeichners eintragen.');
  perform _t_fails(format($f$update delivery_notes set signed_at = now(), signer_name = 'Max' where id = %L$f$, v_note),
    'Das Unterschriftsbild fehlt.');
  update delivery_notes
  set signed_at = now(), signer_name = 'Max Muster', signature_path = 'signatures/x.png' where id = v_note;

  perform _t_fails(format($f$update delivery_notes set recipient_name = 'X' where id = %L$f$, v_note),
    'Ein unterschriebener Lieferschein kann nicht mehr geändert werden.');
  perform _t_fails(format('delete from delivery_notes where id = %L', v_note),
    'Ein unterschriebener Lieferschein kann nicht gelöscht werden.');
  perform _t_fails(format('insert into delivery_note_items (delivery_note_id, product_id, qty) values (%L, %L, 1)', v_note, v_olives),
    'Die Positionen eines unterschriebenen Lieferscheins können nicht geändert werden.');
  update delivery_notes set pdf_path = 'documents/2026/lieferschein/x.pdf' where id = v_note;

  -- ohne Positionen darf nicht unterschrieben werden
  declare
    v_empty uuid;
  begin
    insert into delivery_notes (recipient_name) values ('Leer') returning id into v_empty;
    perform _t_fails(format($f$update delivery_notes set signed_at = now(), signer_name = 'A', signature_path = 'x' where id = %L$f$, v_empty),
      'Zum Unterschreiben braucht der Lieferschein mindestens eine Position.');
  end;

  v_invoice := invoice_from_delivery_note(v_note);
  assert (select recipient_name from invoices where id = v_invoice) = 'Markt Süd', 'Empfänger übernommen';
  assert (select qty from invoice_items where invoice_id = v_invoice) = 8, 'Position übernommen';
  assert (select net_cents from invoices where id = v_invoice) = 8 * 450, 'Summe berechnet';
  perform _t_fails(format('select invoice_from_delivery_note(%L)', v_note),
    'Für diesen Lieferschein gibt es bereits eine Rechnung.');
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 8. Lager: Wareneingang, Korrektur, Produkt-Import
do $$
declare
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
  v_count int;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000002');
  perform _t_logout();

  perform _t_login('c0000000-0000-4000-8000-000000000001');
  select count(*) into v_count from products;
  assert import_products('[
    {"name":"Import A","category":"Test","unit":"jar","units_per_carton":6,"buy_price_net_cents":100,"sell_price_net_cents":200,"vat_rate":7},
    {"name":"Import B","category":"Test","unit":"kg","buy_price_net_cents":500,"sell_price_net_cents":800,"vat_rate":7}
  ]'::jsonb) = 2, 'Import legt 2 Produkte an';
  assert (select count(*) from products) = v_count + 2, 'Zwei neue Produkte';
  perform _t_fails($f$select import_products('[
    {"name":"Gut","unit":"piece","buy_price_net_cents":1,"sell_price_net_cents":2},
    {"name":"Schlecht","unit":"piece","buy_price_net_cents":-5,"sell_price_net_cents":2}
  ]'::jsonb)$f$, 'Zeile 2:%');
  assert (select count(*) from products where name = 'Gut') = 0, 'Bei einem Fehler wird nichts importiert';
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 9. Tour wieder öffnen und Start zurücknehmen
do $$
declare
  v_tour uuid := (select id from tours where status = 'closed' limit 1);
  v_driver uuid := (select id from drivers where name = 'Samir Haddad');
  v_draft uuid;
  v_oil uuid := (select id from products where name = 'Olivenöl 1 l');
  v_before bigint;
begin
  -- Die Verwaltung darf alles, genau wie der Chef (auch Touren wieder öffnen)
  perform _t_login('c0000000-0000-4000-8000-000000000002');

  perform reopen_tour(v_tour);
  assert (select status from tours where id = v_tour) = 'active', 'Tour wieder unterwegs';
  assert (select profit_cents from tours where id = v_tour) is null, 'Eingefrorene Werte gelöscht';

  -- Start zurücknehmen
  insert into tours (driver_id) values (v_driver) returning id into v_draft;
  insert into tour_items (tour_id, product_id, loaded_qty) values (v_draft, v_oil, 6);
  perform start_tour(v_draft);
  assert (select status from tours where id = v_draft) = 'active', 'Tour gestartet';
  perform undo_start_tour(v_draft);
  assert (select status from tours where id = v_draft) = 'draft', 'wieder Entwurf';
  assert (select number from tours where id = v_draft) is not null, 'Nummer bleibt erhalten';
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 10. Auswertungen
do $$
declare
  v_tour uuid := (select id from tours where status = 'active' and name is null limit 1);
  v_returns jsonb;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  -- erneut abschließen: gleiche Rückgabe wie vorher
  select jsonb_agg(jsonb_build_object('product_id', product_id, 'returned_qty',
    case product_name when 'Grüne Oliven' then 7 when 'Baladi-Käse' then 2000 else 4 end))
  into v_returns from tour_items where tour_id = v_tour;
  perform close_tour(v_tour, v_returns, 86800, null);
  assert (select difference_cents from tours where id = v_tour) = 0, 'Kasse stimmt';

  assert (select count(*) from report_driver_stats(current_date - 1, current_date + 1)) = 1, 'Eine Fahrerzeile';
  assert (select return_rate from report_driver_stats(current_date - 1, current_date + 1)) between 0.099 and 0.100,
    'Rücklaufquote nach Wert (9.950 / 100.250)';
  assert (select tour_count from report_kpis(current_date - 1, current_date + 1)) = 1, 'Eine abgeschlossene Tour';
  assert (select expenses_net_cents from report_kpis(current_date - 1, current_date + 1)) = 3500, 'Ausgaben netto';
  assert (select count(*) from report_expenses_by_category(current_date - 1, current_date + 1)) = 2, 'Zwei Kategorien';
  assert (select product_name from report_top_products(current_date - 1, current_date + 1, 1)) = 'Baladi-Käse',
    'Top-Produkt nach Umsatz (612,00 €)';
  assert (select count(*) from report_timeseries(current_date - 1, current_date + 1, 'day')) = 1, 'Ein Tag';
  perform _t_fails($f$select * from report_timeseries(current_date, current_date, 'year')$f$, 'Unbekannte Gruppierung%');
  assert (select open_count from v_open_invoices) = 0, 'Keine offene Rechnung';
  assert (select expense_count from v_expenses_by_month limit 1) = 2, 'Ausgaben pro Monat';

  -- Beleg: Brutto → Netto/USt (119,00 € bei 19 % = 100,00 + 19,00)
  insert into expenses (title, gross_cents, vat_rate) values ('Reparatur', 11900, 19);
  assert (select net_cents from expenses where title = 'Reparatur') = 10000, 'Netto aus Brutto';
  assert (select vat_cents from expenses where title = 'Reparatur') = 1900, 'USt aus Brutto';
  assert (select year_month from expenses where title = 'Reparatur') ~ '^[0-9]{4}-[0-9]{2}$', 'Monatsordner';
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 11. Keine Kleinunternehmer-Regelung, Firmendaten
do $$
declare
  v_invoice uuid;
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  -- Die Kleinunternehmer-Regelung gibt es nicht: sie lässt sich nicht einschalten
  perform _t_fails('update company_settings set is_small_business = true',
    'new row for relation "company_settings" violates check constraint%');

  -- unvollständige Firmendaten verhindern das Festschreiben
  update company_settings set tax_number = '', vat_id = '';
  insert into invoices (recipient_name, recipient_address) values ('Noch ein Kunde', 'Weg 2') returning id into v_invoice;
  insert into invoice_items (invoice_id, product_id, qty) values (v_invoice, v_olives, 1);
  perform _t_fails(format('select finalize_invoice(%L)', v_invoice),
    'Bitte zuerst in den Firmendaten ergänzen: Steuernummer oder USt-IdNr..');
  perform _t_logout();
end $$;

-- ---------------------------------------------------------------- 12. Nummernkreise ohne Lücken
do $$
begin
  assert (select last_value from number_counters where type = 'tour') = 2, 'Zwei Touren gestartet';
  assert (select last_value from number_counters where type = 'invoice') = 2, 'Zwei Rechnungsnummern (RE, Storno)';
  assert (select count(distinct number) from invoices where number is not null) = 2, 'Nummern sind eindeutig';
end $$;

select 'ALLE BACKEND-TESTS BESTANDEN' as ergebnis;
rollback;

