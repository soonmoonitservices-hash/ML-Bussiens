-- Pflicht-Test: Tour starten. Es gibt keinen Bestand mehr: Eine Tour startet immer, auch mit
-- beliebigen Mengen. Sie bekommt beim Start ihre Nummer und wird „unterwegs“.
-- Läuft nach _helpers.sql (siehe scripts/test_backend.sh) und endet mit ROLLBACK.

do $$
declare
  v_tour uuid;
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
  v_oil uuid := (select id from products where name = 'Olivenöl 1 l');
begin
  perform _t_login('c0000000-0000-4000-8000-000000000001');

  insert into tours (driver_id) values ((select id from drivers where name = 'Samir Haddad'))
  returning id into v_tour;
  insert into tour_items (tour_id, product_id, loaded_qty) values (v_tour, v_olives, 5), (v_tour, v_oil, 10000);

  assert (select status from tours where id = v_tour) = 'draft', 'Tour beginnt als Entwurf';
  assert (select number from tours where id = v_tour) is null, 'Der Entwurf hat noch keine Tournummer';

  perform start_tour(v_tour);
  assert (select status from tours where id = v_tour) = 'active', 'Tour ist unterwegs';
  assert (select number from tours where id = v_tour) is not null, 'Beim Start wird die Nummer vergeben';

  -- eine Tour ohne Positionen kann nicht starten
  perform _t_fails(
    format('select start_tour(%L)', (select id from tours where false)),
    '%');

  perform _t_logout();
end $$;

select 'start_tour: BESTANDEN' as ergebnis;
rollback;
