-- Test: Aus einem Karton einzelne Produkte abziehen (zurück oder geschenkt).
-- Karton „Probierkarton“: Verkauf 20,00 €, Einkauf 10,00 €, Inhalt je Karton 2 Gläser Oliven
-- (Verkauf 4,50 €, Einkauf 3,00 €). 2 Kartons geladen, aus den Kartons kommt 1 Glas zurück und
-- 1 Glas wird verschenkt. Läuft nach _helpers.sql und endet mit ROLLBACK.

do $$
declare
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
  v_oil uuid := (select id from products where name = 'Olivenöl 1 l');
  v_carton uuid;
  v_tour uuid;
  v_row tours;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents, vat_rate)
  values ('Probierkarton', 'carton', 1000, 2000, 7) returning id into v_carton;
  insert into product_contents (product_id, content_product_id, qty) values (v_carton, v_olives, 2);

  insert into tours (driver_id) values ((select id from drivers where name = 'Ahmad Khalil'))
  returning id into v_tour;
  insert into tour_items (tour_id, product_id, loaded_qty) values (v_tour, v_carton, 2);
  perform start_tour(v_tour);

  -- Nicht zum Inhalt gehörende Produkte und zu viele Stück sind Fehler
  perform _t_fails(format($f$select close_tour(%L, %L::jsonb, 0, null)$f$, v_tour,
      format('[{"product_id":"%s","returned_qty":0,"removals":[{"product_id":"%s","returned_qty":1}]}]', v_carton, v_oil)),
    'Das Produkt gehört nicht zum Inhalt von ‚Probierkarton‘.');
  perform _t_fails(format($f$select close_tour(%L, %L::jsonb, 0, null)$f$, v_tour,
      format('[{"product_id":"%s","returned_qty":0,"removals":[{"product_id":"%s","returned_qty":3,"gift_qty":2}]}]', v_carton, v_olives)),
    'Aus ‚Probierkarton‘ können höchstens 4 ‚Grüne Oliven‘ entfernt werden.');

  -- Umsatz: 2 × 20,00 € − 2 Gläser × 4,50 € = 31,00 €; Bargeld stimmt
  perform close_tour(v_tour,
    format('[{"product_id":"%s","returned_qty":0,"removals":[{"product_id":"%s","returned_qty":1,"gift_qty":1}]}]', v_carton, v_olives)::jsonb,
    3100, null);
  select * into v_row from tours where id = v_tour;
  assert v_row.revenue_net_cents = 3100, format('Umsatz %s', v_row.revenue_net_cents);
  -- Wareneinsatz: 2 × 10,00 € − zurückgebrachtes Glas 3,00 € = 17,00 € (das Geschenk bleibt Kosten)
  assert v_row.cost_cents = 1700, format('Wareneinsatz %s', v_row.cost_cents);
  assert v_row.expected_cash_cents = 3100, 'Soll-Bargeld 31,00 €';
  assert v_row.profit_cents = 3100 - 1700, 'Gewinn 14,00 €';
  assert (select count(*) from tour_item_removals where tour_item_id = (select id from tour_items where tour_id = v_tour)) = 1,
    'Eine Entfernung gespeichert';

  -- Wieder öffnen löscht die Entfernungen
  perform reopen_tour(v_tour);
  assert (select count(*) from tour_item_removals) = 0, 'Entfernungen gelöscht';
  assert (select removed_revenue_cents from tour_items where tour_id = v_tour) = 0, 'Beträge zurückgesetzt';

  perform _t_logout();
end $$;

select 'carton_removals: BESTANDEN' as ergebnis;
rollback;
