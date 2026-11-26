-- Test: Firmen sind getrennt. Jede Firma sieht und ändert nur ihre eigenen Daten.
-- Firma A = „Standard“ (Seed, Testbenutzer chef@test.de), Firma B wird hier angelegt.
-- Läuft nach _helpers.sql und endet mit ROLLBACK.

do $$
declare
  v_tenant_b uuid := 'b0000000-0000-4000-8000-000000000002';
  v_user_b uuid := 'c0000000-0000-4000-8000-0000000000b2';
  v_tour_a uuid;
  v_tour_b uuid;
  v_driver_b uuid;
  v_product_a uuid := (select id from products where name = 'Grüne Oliven');
  v_product_b uuid;
  v_invoice_a uuid;
begin
  -- Firma B mit eigenem Chef anlegen
  insert into tenants (id, name) values (v_tenant_b, 'Firma B');
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values (v_user_b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'chef-b@test.de', '', now(), '{}',
          format('{"name":"Chef B","tenant_id":"%s"}', v_tenant_b)::jsonb, now(), now());
  assert (select role from profiles where id = v_user_b) = 'chef', 'Erster Benutzer der Firma B wird Chef';
  assert (select count(*) from company_settings where tenant_id = v_tenant_b) = 1, 'Firmendaten für B angelegt';

  -- Firma A: Tour (Entwurf) und Rechnung anlegen
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  insert into tours (driver_id) values ((select id from drivers where name = 'Ahmad Khalil'))
  returning id into v_tour_a;
  insert into tour_items (tour_id, product_id, loaded_qty) values (v_tour_a, v_product_a, 10);
  insert into invoices (recipient_name, recipient_address)
  values ('Kunde A', 'Straße 1, 10115 Berlin') returning id into v_invoice_a;
  perform _t_logout();

  -- Firma B sieht nichts von A
  perform _t_login(v_user_b);
  assert (select count(*) from products) = 0, 'B sieht keine Produkte von A';
  assert (select count(*) from drivers) = 0, 'B sieht keine Fahrer von A';
  assert (select count(*) from tours) = 0, 'B sieht keine Touren von A';
  assert (select count(*) from tour_items) = 0, 'B sieht keine Positionen von A';
  assert (select count(*) from invoices) = 0, 'B sieht keine Rechnungen von A';
  assert (select count(*) from profiles) = 1, 'B sieht nur den eigenen Benutzer';
  assert (select count(*) from company_settings) = 1, 'B sieht nur die eigenen Firmendaten';
  assert (select name from company_settings) = 'Firma B', 'B sieht die eigenen Firmendaten';
  assert (select count(*) from tenants) = 1, 'B sieht nur die eigene Firma';

  -- B darf Datensätze von A nicht per Funktion anfassen
  perform _t_fails(format($f$select start_tour(%L)$f$, v_tour_a), 'Datensatz nicht gefunden.');
  perform _t_fails(format($f$select finalize_invoice(%L)$f$, v_invoice_a), 'Datensatz nicht gefunden.');

  -- B darf nichts in A anlegen und nichts mit Daten von A verknüpfen
  perform _t_fails(format($f$insert into drivers (tenant_id, name) values (%L, 'Fremd')$f$,
      'a0000000-0000-4000-8000-000000000001'),
    'new row violates row-level security policy%');

  insert into drivers (name) values ('Fahrer B') returning id into v_driver_b;
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents)
  values ('Produkt B', 'piece', 100, 200) returning id into v_product_b;
  assert (select sku from products where id = v_product_b) = 'ART-001', 'Artikelnummern zählen je Firma';
  insert into tours (driver_id) values (v_driver_b) returning id into v_tour_b;
  perform _t_fails(format($f$insert into tour_items (tour_id, product_id, loaded_qty) values (%L, %L, 1)$f$,
      v_tour_b, v_product_a),
    'Der Datensatz gehört zu einer anderen Firma.');
  perform _t_logout();

  -- Nummern zählen je Firma: beide bekommen die erste Tournummer
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  perform start_tour(v_tour_a);
  assert (select number from tours where id = v_tour_a) = 'T-' || extract(year from berlin_today())::int || '-001',
    'Firma A: erste Tour';
  perform _t_logout();

  perform _t_login(v_user_b);
  insert into tour_items (tour_id, product_id, loaded_qty) values (v_tour_b, v_product_b, 5);
  perform start_tour(v_tour_b);
  assert (select number from tours where id = v_tour_b) = 'T-' || extract(year from berlin_today())::int || '-001',
    'Firma B: eigene erste Tour';
  assert (select count(*) from tours) = 1, 'B sieht nur die eigene Tour';
  perform _t_logout();

  -- A sieht nichts von B
  perform _t_login('c0000000-0000-4000-8000-000000000001');
  assert (select count(*) from products where name = 'Produkt B') = 0, 'A sieht keine Produkte von B';
  assert (select count(*) from tours where id = v_tour_b) = 0, 'A sieht keine Touren von B';
  assert (select count(*) from profiles where email = 'chef-b@test.de') = 0, 'A sieht keine Benutzer von B';
  perform _t_logout();

  -- Neuer Benutzer ohne Firma → bekommt eine eigene Firma und wird Chef
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values ('c0000000-0000-4000-8000-0000000000c3', '00000000-0000-0000-0000-000000000000',
          'authenticated', 'authenticated', 'neu@kunde.de', '', now(), '{}',
          '{"company":"Kunde Drei"}', now(), now());
  assert (select role from profiles where email = 'neu@kunde.de') = 'chef', 'Neue Firma: Benutzer wird Chef';
  assert (select t.name from profiles p join tenants t on t.id = p.tenant_id where p.email = 'neu@kunde.de')
    = 'Kunde Drei', 'Neue Firma trägt den angegebenen Namen';
  assert (select tenant_id from profiles where email = 'neu@kunde.de')
    not in ('a0000000-0000-4000-8000-000000000001', v_tenant_b), 'Eigene, neue Firma';
end $$;

select 'tenants: BESTANDEN' as ergebnis;
rollback;
