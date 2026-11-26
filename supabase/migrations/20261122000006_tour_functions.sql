-- Tour-Ablauf: starten, Start zurücknehmen, abschließen, wieder öffnen.
-- Jede Funktion läuft in einer Transaktion; Produkte werden immer nach product_id sortiert gesperrt.

create function start_tour(p_tour_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_tour tours;
  v_item record;
  v_previous text;
begin
  perform _require_active();
  select * into v_tour from tours where id = p_tour_id for update;
  if not found then
    raise exception 'Tour nicht gefunden.';
  end if;
  if v_tour.status <> 'draft' then
    raise exception 'Nur Entwürfe können gestartet werden.';
  end if;
  if not exists (select 1 from drivers where id = v_tour.driver_id and active) then
    raise exception 'Der Fahrer ist deaktiviert.';
  end if;
  if not exists (select 1 from tour_items where tour_id = p_tour_id) then
    raise exception 'Bitte zuerst die Ware für die Tour auswählen.';
  end if;

  v_previous := _bypass_on();

  -- Preise ein letztes Mal vom Produkt übernehmen, danach sind sie eingefroren.
  update tour_items ti
  set product_name = p.name,
      unit = p.unit,
      units_per_carton = p.units_per_carton,
      buy_price_cents = p.buy_price_net_cents,
      sell_price_cents = p.sell_price_net_cents,
      vat_rate = p.vat_rate
  from products p
  where p.id = ti.product_id and ti.tour_id = p_tour_id;

  for v_item in
    select product_id, loaded_qty from tour_items where tour_id = p_tour_id order by product_id
  loop
    perform _move_stock(v_item.product_id, -v_item.loaded_qty, 'tour_out', null, 'tours', p_tour_id);
  end loop;

  update tours
  set status = 'active',
      number = coalesce(number, next_number('tour')),
      started_at = now(),
      started_by = auth.uid()
  where id = p_tour_id;

  perform _bypass_restore(v_previous);
end
$$;

-- Tour von „unterwegs“ zurück in den Entwurf, die Ware geht zurück ins Lager.
create function undo_start_tour(p_tour_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_tour tours;
  v_item record;
  v_previous text;
begin
  perform _require_active();
  select * into v_tour from tours where id = p_tour_id for update;
  if not found then
    raise exception 'Tour nicht gefunden.';
  end if;
  if v_tour.status <> 'active' then
    raise exception 'Nur Touren, die unterwegs sind, können zurückgenommen werden.';
  end if;

  v_previous := _bypass_on();
  for v_item in
    select product_id, loaded_qty from tour_items where tour_id = p_tour_id order by product_id
  loop
    perform _move_stock(v_item.product_id, v_item.loaded_qty, 'tour_undo', null, 'tours', p_tour_id);
  end loop;

  update tours set status = 'draft', started_at = null, started_by = null where id = p_tour_id;
  perform _bypass_restore(v_previous);
end
$$;

-- Prüft die Rückgabe-Liste und trägt die zurückgebrachten Mengen ein.
-- p_returns: [{"product_id": "...", "returned_qty": 7}] – nicht genannte Produkte = 0 zurück.
create function _apply_tour_returns(p_tour_id uuid, p_returns jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_item record;
  v_returned bigint;
begin
  if jsonb_typeof(p_returns) <> 'array' then
    raise exception 'Die Rückgabe muss als Liste übergeben werden.';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_returns) e
    group by e ->> 'product_id' having count(*) > 1
  ) then
    raise exception 'Ein Produkt wurde mehrfach angegeben.';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_returns) e
    where not exists (
      select 1 from tour_items
      where tour_id = p_tour_id and product_id = (e ->> 'product_id')::uuid
    )
  ) then
    raise exception 'Ein Produkt in der Rückgabe gehört nicht zu dieser Tour.';
  end if;

  for v_item in select * from tour_items where tour_id = p_tour_id order by product_id loop
    select coalesce((e ->> 'returned_qty')::bigint, 0) into v_returned
    from jsonb_array_elements(p_returns) e
    where (e ->> 'product_id')::uuid = v_item.product_id;
    v_returned := coalesce(v_returned, 0);

    if v_returned < 0 or v_returned > v_item.loaded_qty then
      raise exception 'Zurückgebracht für ‚%‘ muss zwischen 0 und % liegen.',
        v_item.product_name, _fmt_qty(v_item.unit, v_item.loaded_qty);
    end if;

    update tour_items set returned_qty = v_returned where id = v_item.id;
    perform _move_stock(v_item.product_id, v_returned, 'tour_return', null, 'tours', p_tour_id);
  end loop;
end
$$;

-- Tour abschließen: Rückgabe ins Lager, Abrechnung berechnen und einfrieren.
create function close_tour(
  p_tour_id uuid,
  p_returns jsonb,
  p_cash_received_cents bigint,
  p_difference_reason text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_tour tours;
  v_previous text;
  v_revenue_net bigint;
  v_revenue_gross bigint;
  v_cost bigint;
  v_expenses_gross bigint;
  v_expenses_net bigint;
  v_expected_cash bigint;
  v_difference bigint;
  v_cash_includes_vat boolean;
begin
  perform _require_active();
  select * into v_tour from tours where id = p_tour_id for update;
  if not found then
    raise exception 'Tour nicht gefunden.';
  end if;
  if v_tour.status <> 'active' then
    raise exception 'Nur Touren, die unterwegs sind, können abgeschlossen werden.';
  end if;
  if p_cash_received_cents is null or p_cash_received_cents < 0 then
    raise exception 'Bitte den vom Fahrer übergebenen Geldbetrag eintragen.';
  end if;

  v_previous := _bypass_on();
  perform _apply_tour_returns(p_tour_id, coalesce(p_returns, '[]'::jsonb));

  select
    coalesce(sum(line_value_cents(unit, sold_qty, sell_price_cents)), 0),
    coalesce(sum(public.gross_cents(line_value_cents(unit, sold_qty, sell_price_cents), vat_rate)), 0),
    coalesce(sum(line_value_cents(unit, sold_qty, buy_price_cents)), 0)
  into v_revenue_net, v_revenue_gross, v_cost
  from tour_items where tour_id = p_tour_id;

  select coalesce(sum(e.gross_cents), 0), coalesce(sum(e.net_cents), 0)
  into v_expenses_gross, v_expenses_net
  from expenses e where e.tour_id = p_tour_id;

  select cash_includes_vat into v_cash_includes_vat from company_settings;
  v_expected_cash := case when v_cash_includes_vat then v_revenue_gross else v_revenue_net end
                     - v_expenses_gross;
  v_difference := p_cash_received_cents - v_expected_cash;

  if v_difference <> 0 and (p_difference_reason is null or btrim(p_difference_reason) = '') then
    raise exception 'Die Kasse stimmt nicht (Differenz %). Bitte eine Begründung angeben.',
      _fmt_money(v_difference);
  end if;

  update tours
  set status = 'closed',
      closed_at = now(),
      closed_by = auth.uid(),
      cash_received_cents = p_cash_received_cents,
      difference_reason = nullif(btrim(p_difference_reason), ''),
      revenue_net_cents = v_revenue_net,
      revenue_gross_cents = v_revenue_gross,
      cost_cents = v_cost,
      expenses_gross_cents = v_expenses_gross,
      expenses_net_cents = v_expenses_net,
      expected_cash_cents = v_expected_cash,
      difference_cents = v_difference,
      profit_cents = v_revenue_net - v_cost - v_expenses_net
  where id = p_tour_id;

  perform _bypass_restore(v_previous);
end
$$;

-- Nur Chef: abgeschlossene Tour wieder öffnen (Rückgaben kommen aus dem Lager, Werte werden gelöscht).
create function reopen_tour(p_tour_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_tour tours;
  v_item record;
  v_previous text;
begin
  perform _require_chef();
  select * into v_tour from tours where id = p_tour_id for update;
  if not found then
    raise exception 'Tour nicht gefunden.';
  end if;
  if v_tour.status <> 'closed' then
    raise exception 'Nur abgeschlossene Touren können wieder geöffnet werden.';
  end if;

  v_previous := _bypass_on();
  for v_item in
    select id, product_id, returned_qty from tour_items where tour_id = p_tour_id order by product_id
  loop
    perform _move_stock(v_item.product_id, -v_item.returned_qty, 'tour_undo', null, 'tours', p_tour_id);
    update tour_items set returned_qty = 0 where id = v_item.id;
  end loop;

  update tours
  set status = 'active',
      closed_at = null,
      closed_by = null,
      cash_received_cents = null,
      difference_reason = null,
      revenue_net_cents = null,
      revenue_gross_cents = null,
      cost_cents = null,
      expenses_gross_cents = null,
      expenses_net_cents = null,
      expected_cash_cents = null,
      difference_cents = null,
      profit_cents = null
  where id = p_tour_id;
  perform _bypass_restore(v_previous);
end
$$;

grant execute on function start_tour(uuid) to authenticated;
grant execute on function undo_start_tour(uuid) to authenticated;
grant execute on function close_tour(uuid, jsonb, bigint, text) to authenticated;
grant execute on function reopen_tour(uuid) to authenticated;
