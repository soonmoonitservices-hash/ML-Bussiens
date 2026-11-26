-- Auswertungen: nur lesen. Views und Funktionen laufen mit den Rechten des Aufrufers (RLS gilt).
-- Umsatz = abgeschlossene Touren (nach closed_at) + festgeschriebene Rechnungen OHNE Tour,
-- sonst würde Tour-Ware doppelt gezählt. Storno und Original heben sich auf.

create view v_stock_overview with (security_invoker = true) as
select
  p.id as product_id,
  p.sku,
  p.name,
  p.category,
  p.unit,
  p.units_per_carton,
  p.stock,
  p.min_stock,
  p.active,
  line_value_cents(p.unit, p.stock, p.buy_price_net_cents) as stock_value_cents,
  p.stock < p.min_stock as is_below_min_stock,
  case when p.units_per_carton is not null then p.stock / p.units_per_carton end as cartons,
  case when p.units_per_carton is not null then p.stock % p.units_per_carton end as loose_units
from products p;

-- Entwurf/unterwegs: erwarteter Gewinn live; abgeschlossen: eingefrorene Werte.
create view v_tour_overview with (security_invoker = true) as
select
  t.*,
  coalesce(i.item_count, 0)::int as item_count,
  coalesce(i.loaded_value_buy_cents, 0) as loaded_value_buy_cents,
  coalesce(i.loaded_value_sell_cents, 0) as loaded_value_sell_cents,
  coalesce(i.loaded_value_sell_cents, 0) - coalesce(i.loaded_value_buy_cents, 0) as expected_profit_cents,
  coalesce(e.gross, 0) as live_expenses_gross_cents,
  coalesce(e.net, 0) as live_expenses_net_cents,
  case
    when t.status = 'closed' then t.profit_cents
    else coalesce(i.loaded_value_sell_cents, 0) - coalesce(i.loaded_value_buy_cents, 0) - coalesce(e.net, 0)
  end as profit_shown_cents
from tours t
left join lateral (
  select
    count(*) as item_count,
    sum(line_value_cents(unit, loaded_qty, buy_price_cents)) as loaded_value_buy_cents,
    sum(line_value_cents(unit, loaded_qty, sell_price_cents)) as loaded_value_sell_cents
  from tour_items where tour_id = t.id
) i on true
left join lateral (
  select sum(x.gross_cents) as gross, sum(x.net_cents) as net
  from expenses x where x.tour_id = t.id
) e on true;

create view v_expenses_by_month with (security_invoker = true) as
select
  year_month,
  count(*)::int as expense_count,
  sum(gross_cents) as gross_cents,
  sum(net_cents) as net_cents,
  sum(vat_cents) as vat_cents
from expenses
group by year_month;

create view v_open_invoices with (security_invoker = true) as
select
  coalesce(sum(gross_cents) filter (where status in ('open', 'overdue')), 0) as open_gross_cents,
  (count(*) filter (where status in ('open', 'overdue')))::int as open_count,
  (count(*) filter (where status = 'overdue'))::int as overdue_count,
  coalesce(sum(gross_cents) filter (where status = 'overdue'), 0) as overdue_gross_cents
from invoices;

create function report_kpis(p_from date, p_to date)
returns table (
  revenue_net_cents bigint,
  cost_cents bigint,
  expenses_net_cents bigint,
  profit_cents bigint,
  tour_count int,
  invoice_count int,
  stock_value_cents bigint
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
  ), s as (
    select coalesce(sum(line_value_cents(unit, stock, buy_price_net_cents)), 0) as total from products
  )
  select t.rev + i.rev, t.cost + i.cost, e.total, t.rev + i.rev - t.cost - i.cost - e.total,
         t.cnt, i.cnt, s.total
  from t, i, e, s
$$;

create function report_timeseries(p_from date, p_to date, p_granularity text)
returns table (
  period_start date,
  revenue_net_cents bigint,
  expenses_net_cents bigint,
  profit_cents bigint
)
language plpgsql stable set search_path = public as $$
#variable_conflict use_column
begin
  if p_granularity not in ('day', 'week', 'month') then
    raise exception 'Unbekannte Gruppierung ‚%‘ (erlaubt: day, week, month).', p_granularity;
  end if;

  return query
  with events as (
    select (closed_at at time zone 'Europe/Berlin')::date as d, t.revenue_net_cents as rev,
           t.cost_cents as cost, 0::bigint as exp
    from tours t
    where t.status = 'closed' and (t.closed_at at time zone 'Europe/Berlin')::date between p_from and p_to
    union all
    select i.date, i.net_cents, i.cost_cents, 0::bigint
    from invoices i
    where i.status <> 'draft' and i.tour_id is null and i.date between p_from and p_to
    union all
    select x.date, 0::bigint, 0::bigint, x.net_cents
    from expenses x
    where x.date between p_from and p_to
  )
  select date_trunc(p_granularity, d)::date, sum(rev)::bigint, sum(exp)::bigint,
         (sum(rev) - sum(cost) - sum(exp))::bigint
  from events
  group by 1
  order by 1;
end
$$;

-- Rücklaufquote nach WERT (zurück ÷ geladen zum Verkaufspreis), weil kg und Stück gemischt sind.
create function report_driver_stats(p_from date, p_to date)
returns table (
  driver_id uuid,
  driver_name text,
  tour_count int,
  revenue_net_cents bigint,
  avg_revenue_per_tour_cents bigint,
  return_rate numeric,
  difference_sum_cents bigint,
  shortage_sum_cents bigint
)
language sql stable set search_path = public as $$
  select
    t.driver_id,
    max(t.driver_name),
    count(*)::int,
    sum(t.revenue_net_cents),
    round(sum(t.revenue_net_cents)::numeric / count(*))::bigint,
    coalesce(round(sum(v.returned_value)::numeric / nullif(sum(v.loaded_value), 0), 4), 0),
    sum(t.difference_cents),
    coalesce(sum(-t.difference_cents) filter (where t.difference_cents < 0), 0)
  from tours t
  left join lateral (
    select
      sum(line_value_cents(unit, returned_qty, sell_price_cents)) as returned_value,
      sum(line_value_cents(unit, loaded_qty, sell_price_cents)) as loaded_value
    from tour_items where tour_id = t.id
  ) v on true
  where t.status = 'closed' and (t.closed_at at time zone 'Europe/Berlin')::date between p_from and p_to
  group by t.driver_id
  order by 4 desc
$$;

create function report_top_products(p_from date, p_to date, p_limit int default 10)
returns table (
  product_id uuid,
  product_name text,
  unit product_unit,
  sold_qty bigint,
  revenue_net_cents bigint
)
language sql stable set search_path = public as $$
  with sold as (
    select ti.product_id, ti.product_name, ti.unit, ti.sold_qty as qty,
           line_value_cents(ti.unit, ti.sold_qty, ti.sell_price_cents) as rev
    from tour_items ti
    join tours t on t.id = ti.tour_id
    where t.status = 'closed'
      and (t.closed_at at time zone 'Europe/Berlin')::date between p_from and p_to
    union all
    select ii.product_id, ii.product_name, ii.unit, ii.qty, ii.line_net_cents
    from invoice_items ii
    join invoices i on i.id = ii.invoice_id
    where i.status <> 'draft' and i.tour_id is null and i.date between p_from and p_to
      and ii.product_id is not null
  )
  select product_id, max(product_name), unit, sum(qty)::bigint, sum(rev)::bigint
  from sold
  group by product_id, unit
  order by 5 desc
  limit p_limit
$$;

create function report_expenses_by_category(p_from date, p_to date)
returns table (category text, expense_count int, gross_cents bigint, net_cents bigint)
language sql stable set search_path = public as $$
  select category, count(*)::int, sum(gross_cents)::bigint, sum(net_cents)::bigint
  from expenses
  where date between p_from and p_to
  group by category
  order by 3 desc
$$;

grant execute on function report_kpis(date, date) to authenticated;
grant execute on function report_timeseries(date, date, text) to authenticated;
grant execute on function report_driver_stats(date, date) to authenticated;
grant execute on function report_top_products(date, date, int) to authenticated;
grant execute on function report_expenses_by_category(date, date) to authenticated;
