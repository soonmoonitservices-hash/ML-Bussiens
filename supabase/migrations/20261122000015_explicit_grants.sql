-- Tabellenrechte ausdrücklich setzen, damit es nicht von der Projekt-Einstellung
-- „Grant API access to new tables automatically“ abhängt. RLS und Trigger regeln den Rest.

grant usage on schema public to anon, authenticated;

do $$
declare
  v_table record;
  v_view record;
begin
  for v_table in select tablename from pg_tables where schemaname = 'public' loop
    execute format('grant select, insert, update, delete on public.%I to authenticated', v_table.tablename);
  end loop;

  -- Views (Auswertungen) sind nur lesbar.
  for v_view in select viewname from pg_views where schemaname = 'public' loop
    execute format('revoke all on public.%I from authenticated', v_view.viewname);
    execute format('grant select on public.%I to authenticated', v_view.viewname);
  end loop;
end
$$;

-- Lagerbewegungen, Nummernzähler und Änderungsverlauf schreiben nur Funktionen/Trigger.
revoke insert, update, delete on stock_movements from authenticated;
revoke insert, update, delete on number_counters from authenticated;
revoke insert, update, delete on change_log from authenticated;

-- TRUNCATE umgeht RLS und Trigger.
revoke truncate, references, trigger on all tables in schema public from authenticated;
