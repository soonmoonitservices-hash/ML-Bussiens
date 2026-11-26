-- Test: Produkte mit zwei Namen und Karton-Inhalt. Läuft nach _helpers.sql und endet mit ROLLBACK.

do $$
declare
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
  v_oil uuid := (select id from products where name = 'Olivenöl 1 l');
  v_carton uuid;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');

  -- Zwei Namen
  update products set name_ar = 'زيتون أخضر' where id = v_olives;
  assert (select name_ar from products where id = v_olives) = 'زيتون أخضر', 'Arabischer Name gespeichert';
  perform _t_fails(format($f$update products set name_ar = '  ' where id = %L$f$, v_olives), '%');

  -- Karton mit Inhalt
  insert into products (name, name_ar, unit, buy_price_net_cents, sell_price_net_cents)
  values ('Probierkarton', 'كرتونة مشكلة', 'carton', 1000, 2000) returning id into v_carton;
  insert into product_contents (product_id, content_product_id, qty) values (v_carton, v_olives, 2), (v_carton, v_oil, 1);
  assert (select count(*) from product_contents where product_id = v_carton) = 2, 'Zwei Produkte im Karton';
  update product_contents set qty = 3 where product_id = v_carton and content_product_id = v_olives;
  assert (select qty from product_contents where product_id = v_carton and content_product_id = v_olives) = 3, 'Menge änderbar';
  delete from product_contents where product_id = v_carton and content_product_id = v_oil;
  assert (select count(*) from product_contents where product_id = v_carton) = 1, 'Produkt entfernbar';

  -- Nur Karton-Produkte haben einen Inhalt, ein Karton nicht sich selbst
  perform _t_fails(format($f$insert into product_contents (product_id, content_product_id, qty) values (%L, %L, 1)$f$, v_olives, v_oil),
    'Nur Produkte mit der Einheit Karton haben einen Inhalt.');
  perform _t_fails(format($f$insert into product_contents (product_id, content_product_id, qty) values (%L, %L, 1)$f$, v_carton, v_carton), '%');

  -- Löschen des Kartons nimmt den Inhalt mit
  delete from products where id = v_carton;
  assert not exists (select 1 from product_contents where product_id = v_carton), 'Inhalt mit gelöscht';
  perform _t_logout();
end $$;

select 'product_contents: BESTANDEN' as ergebnis;
rollback;
