-- Gemeinsame Vorbereitung für alle *.test.sql: Hilfsfunktionen, Testbenutzer, Firmendaten.
-- Wird von scripts/test_backend.sh vor jede Testdatei gesetzt. Alles läuft in einer Transaktion
-- (die Testdatei endet mit ROLLBACK).

\set ON_ERROR_STOP on
begin;

-- ---------------------------------------------------------------- Hilfsfunktionen (nur für den Test)
create function _t_login(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  set local role authenticated;
end $$;

create function _t_login_anonymous() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"authenticated"}', true);
  set local role authenticated;
end $$;

create function _t_logout() returns void language plpgsql as $$
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);
end $$;

-- Erwartet, dass das SQL fehlschlägt und die Meldung zum Muster passt.
create function _t_fails(p_sql text, p_pattern text) returns void language plpgsql as $$
declare
  v_message text;
begin
  begin
    execute p_sql;
  exception when others then
    v_message := sqlerrm;
  end;
  assert v_message is not null, format('Erwarteter Fehler blieb aus: %s', p_sql);
  assert v_message like p_pattern,
    format('Falsche Meldung: "%s" (erwartet: "%s") bei: %s', v_message, p_pattern, p_sql);
end $$;

grant execute on function _t_login(uuid), _t_login_anonymous(), _t_logout(),
  _t_fails(text, text) to public;

-- ---------------------------------------------------------------- Benutzer
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('c0000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'chef@test.de', '', now(), '{}', '{"name":"Test Chef","tenant_id":"a0000000-0000-4000-8000-000000000001"}', now(), now()),
  ('c0000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'office@test.de', '', now(), '{}', '{"name":"Test Verwaltung","tenant_id":"a0000000-0000-4000-8000-000000000001"}', now(), now()),
  ('c0000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'inaktiv@test.de', '', now(), '{}', '{"tenant_id":"a0000000-0000-4000-8000-000000000001"}', now(), now());

do $$
begin
  assert (select role from profiles where email = 'chef@test.de') = 'chef', 'Erster Benutzer wird Chef';
  assert (select role from profiles where email = 'office@test.de') = 'office', 'Weitere werden Verwaltung';
  assert (select name from profiles where email = 'inaktiv@test.de') = 'inaktiv', 'Name fällt auf E-Mail zurück';
end $$;
update profiles set active = false where email = 'inaktiv@test.de';

-- Firmendaten (Soll-Bargeld netto, wie im Beispiel der Spezifikation)
select _t_login('c0000000-0000-4000-8000-000000000001');
update company_settings
set name = 'Testfirma GmbH', address = 'Teststraße 1, 10115 Berlin',
    tax_number = '12/345/67890', cash_includes_vat = false;
select _t_logout();

