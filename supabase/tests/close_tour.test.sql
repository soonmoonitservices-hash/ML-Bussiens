-- Pflicht-Test: Tour abschließen. Rückgaben gehen korrekt ins Lager zurück.
-- Beispiel: 13 Kartons × 4 + 3 = 55 Gläser geladen, 7 zurück → 48 verkauft; Umsatz 903,00 €,
-- Ausgaben 35,00 € → Soll 868,00 €; Bargeld 860,00 € → Fehlbetrag −8,00 € (die Begründung ist freiwillig).
-- Läuft nach _helpers.sql (siehe scripts/test_backend.sh) und endet mit ROLLBACK.

do $$
declare
  v_tour uuid;
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
  v_cheese uuid := (select id from products where name = 'Baladi-Käse');
  v_oil uuid := (select id from products where name = 'Olivenöl 1 l');
  v_returns jsonb;
  v_row tours;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');

  insert into tours (driver_id) values ((select id from drivers where name = 'Ahmad Khalil'))
  returning id into v_tour;
  insert into tour_items (tour_id, product_id, loaded_qty) values
    (v_tour, v_olives, 13 * 4 + 3), (v_tour, v_cheese, 70000), (v_tour, v_oil, 10);
  perform start_tour(v_tour);

  insert into expenses (title, category, gross_cents, tour_id) values
    ('Diesel', 'Fahrzeug & Kraftstoff', 1500, v_tour), ('Essen', 'Verpflegung', 2000, v_tour);

  v_returns := format('[{"product_id":"%s","returned_qty":7},{"product_id":"%s","returned_qty":2000},{"product_id":"%s","returned_qty":4}]',
    v_olives, v_cheese, v_oil)::jsonb;

  -- mehr zurück als geladen: Fehler
  perform _t_fails(format($f$select close_tour(%L, %L::jsonb, 86000, 'x')$f$, v_tour,
      format('[{"product_id":"%s","returned_qty":56}]', v_olives)),
    'Zurückgebracht für ‚Grüne Oliven‘ muss zwischen 0 und 55 liegen.');

  -- Differenz ohne Begründung ist erlaubt
  perform close_tour(v_tour, v_returns, 86000, null);
  assert (select difference_reason from tours where id = v_tour) is null, 'Begründung ist freiwillig';

  -- Rückgaben im Lager
  assert (select sold_qty from tour_items where tour_id = v_tour and product_id = v_olives) = 48, '48 Gläser verkauft';

  -- Abrechnung
  select * into v_row from tours where id = v_tour;
  assert v_row.status = 'closed', 'Tour abgeschlossen';
  assert v_row.revenue_net_cents = 90300, 'Umsatz 903,00 €';
  assert v_row.expected_cash_cents = 86800, 'Soll-Bargeld 868,00 €';
  assert v_row.difference_cents = -800, 'Fehlbetrag −8,00 €';
  assert v_row.profit_cents = 90300 - 59520 - 3500 - 800, 'Gewinn = Umsatz − Wareneinsatz − Ausgaben + Differenz (−8,00 €)';

  perform _t_logout();
end $$;

select 'close_tour: BESTANDEN' as ergebnis;
rollback;
