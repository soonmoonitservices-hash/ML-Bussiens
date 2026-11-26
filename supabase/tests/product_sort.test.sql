-- Test: eigene Reihenfolge der Produkte (sort_order, reorder_products). Läuft nach _helpers.sql, endet mit ROLLBACK.

do $$
declare
  v_a uuid; v_b uuid; v_c uuid; v_d uuid; v_e uuid;
  v_order text;
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');

  -- Fünf Produkte in bekannter Reihenfolge anlegen; neue kommen immer ans Ende.
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents) values ('S-A', 'piece', 1, 2) returning id into v_a;
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents) values ('S-B', 'piece', 1, 2) returning id into v_b;
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents) values ('S-C', 'piece', 1, 2) returning id into v_c;
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents) values ('S-D', 'piece', 1, 2) returning id into v_d;
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents) values ('S-E', 'piece', 1, 2) returning id into v_e;

  select string_agg(name, ',' order by sort_order) into v_order from products where name like 'S-%';
  assert v_order = 'S-A,S-B,S-C,S-D,S-E', format('Neue Produkte am Ende in Anlegereihenfolge: %s', v_order);

  -- Alle fünf umsortieren (als angemeldeter Benutzer, mit Zeilensicherheit): E,D,C,B,A
  perform reorder_products(array[v_e, v_d, v_c, v_b, v_a]);
  select string_agg(name, ',' order by sort_order) into v_order from products where name like 'S-%';
  assert v_order = 'S-E,S-D,S-C,S-B,S-A', format('Reihenfolge gespeichert: %s', v_order);

  -- Nur eine Teilliste (z. B. Suche/Filter): B und D tauschen, die anderen bleiben an ihrem Platz.
  perform reorder_products(array[v_b, v_d]);
  select string_agg(name, ',' order by sort_order) into v_order from products where name like 'S-%';
  assert v_order = 'S-E,S-B,S-C,S-D,S-A', format('Teilliste tauscht nur ihre Plätze: %s', v_order);

  -- Produkt aus der Mitte nach vorn: Liste der ersten vier neu angeordnet.
  perform reorder_products(array[v_c, v_e, v_b, v_d]);
  select string_agg(name, ',' order by sort_order) into v_order from products where name like 'S-%';
  assert v_order = 'S-C,S-E,S-B,S-D,S-A', format('Mitte nach vorn: %s', v_order);

  -- Ein neues Produkt kommt nach einer Umsortierung weiter ans Ende.
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents) values ('S-F', 'piece', 1, 2);
  select string_agg(name, ',' order by sort_order) into v_order from products where name like 'S-%';
  assert v_order = 'S-C,S-E,S-B,S-D,S-A,S-F', format('Neues Produkt am Ende: %s', v_order);

  -- Plätze sind eindeutig (keine doppelten Positionen).
  assert (select count(distinct sort_order) from products) = (select count(*) from products), 'Positionen eindeutig';

  perform _t_logout();
end $$;

select 'product_sort: BESTANDEN' as ergebnis;
rollback;
