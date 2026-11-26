-- Der Lagerbestand entfällt. Produkte sind nur noch eine Liste (Name, Einheit, Karton-Größe,
-- Preise, Kategorie). Touren und Rechnungen buchen nichts mehr vom Lager ab, es gibt keinen
-- Wareneingang, keine Korrektur und keinen Lagerwert. „Zurück“ bei einer Tour bleibt erhalten:
-- verkauft = geladen − zurück − geschenkt bestimmt weiter den Umsatz.

drop view v_stock_overview;
drop function stock_intake(uuid, bigint, text);
drop function stock_correct(uuid, bigint, text);

-- Aufrufe von _move_stock aus den Funktionen entfernen (ohne sie neu abzutippen, so bleiben
-- Rate-Limit, Firmenprüfung und Geschenke erhalten).
do $$
declare
  v_name text;
  v_def text;
begin
  foreach v_name in array array[
    'start_tour', 'undo_start_tour', '_apply_tour_returns', 'reopen_tour',
    'finalize_invoice', 'cancel_invoice'
  ] loop
    select pg_get_functiondef(p.oid) into v_def
    from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = v_name;
    v_def := regexp_replace(v_def, 'perform _move_stock\([^;]*\);', 'null;', 'g');
    if v_def like '%_move_stock%' then
      raise exception 'Funktion % konnte nicht angepasst werden', v_name;
    end if;
    execute v_def;
  end loop;

  -- Produkt-Import ohne Bestandsspalten
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'import_products';
  v_def := replace(v_def, 'vat_rate, min_stock, stock', 'vat_rate');
  v_def := replace(v_def,
    E'coalesce((v_row ->> ''vat_rate'')::int, 7),\n        coalesce((v_row ->> ''min_stock'')::bigint, 0),\n        coalesce((v_row ->> ''stock'')::bigint, 0)',
    'coalesce((v_row ->> ''vat_rate'')::int, 7)');
  if v_def like '%stock%' then
    raise exception 'import_products konnte nicht angepasst werden';
  end if;
  execute v_def;
end
$$;

drop function _move_stock(uuid, bigint, movement_type, text, text, uuid);
drop trigger b_guard_stock on products;
drop trigger c_initial_stock on products;
drop function _products_guard_stock();
drop function _products_initial_stock();
drop table stock_movements;
drop type movement_type;

alter table products drop column stock;
alter table products drop column min_stock;

-- Auswertung ohne Lagerwert.
drop function report_kpis(date, date);
create function report_kpis(p_from date, p_to date)
returns table (
  revenue_net_cents bigint, cost_cents bigint, expenses_net_cents bigint, profit_cents bigint,
  tour_count integer, invoice_count integer
)
language sql stable set search_path = public as $$
  with t as (
    select coalesce(sum(revenue_net_cents), 0) as rev, coalesce(sum(cost_cents), 0) as cost, count(*)::int as cnt
    from tours
    where status = 'closed' and (closed_at at time zone 'Europe/Berlin')::date between p_from and p_to
  ), i as (
    select coalesce(sum(net_cents), 0) as rev, coalesce(sum(cost_cents), 0) as cost,
           (count(*) filter (where cancels_invoice_id is null))::int as cnt
    from invoices
    where status <> 'draft' and tour_id is null and date between p_from and p_to
  ), e as (
    select coalesce(sum(net_cents), 0) as total from expenses where date between p_from and p_to
  )
  select t.rev + i.rev, t.cost + i.cost, e.total, t.rev + i.rev - t.cost - i.cost - e.total, t.cnt, i.cnt
  from t, i, e
$$;
grant execute on function report_kpis(date, date) to authenticated;
