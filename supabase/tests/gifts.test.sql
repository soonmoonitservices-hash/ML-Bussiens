-- Test: Geschenkte Produkte beim Tour-Abschluss.
-- 55 Gläser geladen, 7 zurück, 5 geschenkt → 43 bezahlt (Umsatz 43 × 4,50 €), Wareneinsatz auf 48 Gläser.
-- Geschenke gehen nicht ins Lager zurück. Läuft nach _helpers.sql und endet mit ROLLBACK.

do $$
declare
  v_tour uuid;
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
  v_row tours;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');

  insert into tours (driver_id) values ((select id from drivers where name = 'Ahmad Khalil'))
  returning id into v_tour;
  insert into tour_items (tour_id, product_id, loaded_qty) values (v_tour, v_olives, 55);
  perform start_tour(v_tour);

  -- zurück + geschenkt dürfen nicht mehr als geladen sein
  perform _t_fails(format($f$select close_tour(%L, %L::jsonb, 0, 'x')$f$, v_tour,
      format('[{"product_id":"%s","returned_qty":30,"gift_qty":26}]', v_olives)),
    'Zurück und geschenkt zusammen dürfen für ‚Grüne Oliven‘ höchstens 55 sein.');

  -- 43 bezahlt × 4,50 € = 193,50 €; Bargeld stimmt
  perform close_tour(v_tour,
    format('[{"product_id":"%s","returned_qty":7,"gift_qty":5}]', v_olives)::jsonb, 19350, null);

  select * into v_row from tours where id = v_tour;
  assert v_row.revenue_net_cents = 19350, 'Umsatz nur für bezahlte Gläser: 193,50 €';
  assert v_row.cost_cents = 48 * 300, 'Wareneinsatz zählt auch die geschenkten Gläser (48 × 3,00 €)';
  assert v_row.expected_cash_cents = 19350, 'Soll-Bargeld 193,50 €';
  assert v_row.profit_cents = 19350 - 48 * 300, 'Gewinn sinkt um den Einkaufswert der Geschenke';
  assert (select billed_qty from tour_items where tour_id = v_tour) = 43, '43 bezahlt';
  assert (select sold_qty from tour_items where tour_id = v_tour) = 48, '48 haben das Lager verlassen';

  perform _t_logout();
end $$;

select 'gifts: BESTANDEN' as ergebnis;
rollback;
