-- Rechte zuspitzen: anon bekommt nichts, interne Funktionen sind für die App nicht aufrufbar,
-- Lagerbewegungen und Nummernzähler sind für Clients nur lesbar.
-- Neue Migrationen mit Funktionen müssen ihre Aufrufer ausdrücklich per GRANT freigeben.

revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;

-- TRUNCATE umgeht RLS und Trigger – darum für die App komplett entziehen.
revoke truncate, references, trigger on all tables in schema public from authenticated;
alter default privileges in schema public revoke truncate, references, trigger on tables from authenticated;

revoke insert, update, delete on stock_movements from authenticated;
revoke insert, update, delete on number_counters from authenticated;

-- Funktionen: Standard „nicht aufrufbar“; die App-Funktionen wurden einzeln freigegeben.
do $$
declare
  v_function record;
begin
  for v_function in
    select p.oid::regprocedure as signature, p.proname
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
  loop
    execute format('revoke all on function %s from public', v_function.signature);
    if v_function.proname <> 'get_app_config' then
      execute format('revoke all on function %s from anon', v_function.signature);
    end if;
    if v_function.proname like '\_%' or v_function.proname in ('next_number', 'mark_overdue_invoices') then
      execute format('revoke all on function %s from authenticated', v_function.signature);
    end if;
  end loop;
end
$$;

-- Reine Rechenhilfen laufen auch im Namen des Benutzers (Views, Berichte, Spaltenvorgaben).
grant execute on function berlin_today() to authenticated;
grant execute on function line_value_cents(product_unit, bigint, bigint) to authenticated;
grant execute on function gross_cents(bigint, int) to authenticated;
grant execute on function net_from_gross_cents(bigint, int) to authenticated;
