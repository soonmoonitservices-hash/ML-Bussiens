-- Test: Superadmin. Nur rasho.juan95@gmail.com darf Firmen auflisten, sperren und löschen.
-- Läuft nach _helpers.sql und endet mit ROLLBACK.

do $$
declare
  v_super uuid := 'c0000000-0000-4000-8000-0000000000a1';
  v_chef_a uuid := 'c0000000-0000-4000-8000-000000000001';
  v_tenant_b uuid := 'b0000000-0000-4000-8000-000000000002';
  v_chef_b uuid := 'c0000000-0000-4000-8000-0000000000b2';
  v_users uuid[];
begin
  -- Superadmin-Konto (in der Standard-Firma) und Firma B mit Chef und Daten
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values
    (v_super, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'Rasho.Juan95@gmail.com', '', now(), '{}',
     '{"name":"Super","tenant_id":"a0000000-0000-4000-8000-000000000001"}', now(), now()),
    (v_chef_b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'chef-b@test.de', '', now(), '{}', '{"name":"Chef B","new_tenant":true,"company":"Firma B"}', now(), now());
  select tenant_id into v_tenant_b from profiles where id = v_chef_b;
  assert (select name from tenants where id = v_tenant_b) = 'Firma B', 'Neue Firma mit new_tenant';
  assert (select role from profiles where id = v_chef_b) = 'chef', 'Chef der neuen Firma';

  perform _t_login(v_chef_b);
  insert into drivers (name) values ('Fahrer B');
  insert into products (name, unit, buy_price_net_cents, sell_price_net_cents)
  values ('Produkt B', 'piece', 100, 200);
  perform _t_logout();

  -- Nur der Superadmin
  assert (select is_superadmin() from (select _t_login(v_chef_a)) x) is not true, 'Chef ist kein Superadmin';
  perform _t_fails('select * from superadmin_tenants()', 'Das darf nur der Superadmin.');
  perform _t_fails(format('select superadmin_set_blocked(%L, true)', v_tenant_b), 'Das darf nur der Superadmin.');
  perform _t_fails(format('select superadmin_delete_tenant(%L)', v_tenant_b), 'Das darf nur der Superadmin.');
  perform _t_logout();

  perform _t_login(v_super);
  assert is_superadmin(), 'rasho.juan95@gmail.com ist Superadmin (auch bei anderer Schreibweise)';
  assert (select count(*) from superadmin_tenants()) = 2, 'Zwei Firmen sichtbar';
  assert (select chef_email from superadmin_tenants() where id = v_tenant_b) = 'chef-b@test.de', 'Chef von B';
  perform _t_fails(
    $f$select superadmin_set_blocked('a0000000-0000-4000-8000-000000000001', true)$f$,
    'Deine eigene Firma kannst du nicht sperren.');

  -- Sperren: Chef B sieht und ändert nichts mehr
  perform superadmin_set_blocked(v_tenant_b, true);
  perform _t_logout();
  perform _t_login(v_chef_b);
  assert (select count(*) from products) = 0, 'Gesperrt: keine Produkte sichtbar';
  assert (select count(*) from drivers) = 0, 'Gesperrt: keine Fahrer sichtbar';
  assert not is_active_user(), 'Gesperrt: nicht mehr aktiv';
  perform _t_fails($f$insert into drivers (name) values ('X')$f$, '%');
  perform _t_logout();

  -- Freigeben
  perform _t_login(v_super);
  perform superadmin_set_blocked(v_tenant_b, false);
  perform _t_logout();
  perform _t_login(v_chef_b);
  assert (select count(*) from products) = 1, 'Freigegeben: Produkte wieder da';
  perform _t_logout();

  -- Endgültig löschen
  perform _t_login(v_super);
  perform _t_fails(
    $f$select superadmin_delete_tenant('a0000000-0000-4000-8000-000000000001')$f$,
    'Deine eigene Firma kannst du nicht löschen.');
  v_users := superadmin_delete_tenant(v_tenant_b);
  assert v_chef_b = any (v_users), 'Benutzer-ID wird zurückgegeben';
  assert not exists (select 1 from tenants where id = v_tenant_b), 'Firma gelöscht';
  assert not exists (select 1 from profiles where tenant_id = v_tenant_b), 'Profile gelöscht';
  perform _t_logout();
  assert not exists (select 1 from products where tenant_id = v_tenant_b), 'Produkte gelöscht';
  assert not exists (select 1 from drivers where tenant_id = v_tenant_b), 'Fahrer gelöscht';
  assert (select count(*) from products where tenant_id = 'a0000000-0000-4000-8000-000000000001') = 3,
    'Daten der anderen Firma bleiben';
end $$;

select 'superadmin: BESTANDEN' as ergebnis;
rollback;
