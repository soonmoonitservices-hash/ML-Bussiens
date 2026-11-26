-- Beim Tour-Abschluss lassen sich aus einem Karton einzelne Produkte abziehen: zurückgebracht
-- oder verschenkt. Der Umsatz sinkt um den Verkaufswert der entfernten Produkte (zu ihren
-- eigenen Preisen). Zurückgebrachte Produkte senken auch den Wareneinsatz (die Ware kommt
-- zurück), Geschenke nicht.
--
-- close_tour: p_returns darf je Karton-Produkt eine Liste „removals“ enthalten:
--   {"product_id": "<karton>", "returned_qty": 0, "removals": [
--      {"product_id": "<enthaltenes Produkt>", "returned_qty": 1, "gift_qty": 1}]}

alter table tour_items
  add column removed_revenue_cents bigint not null default 0 check (removed_revenue_cents >= 0),
  add column removed_cost_cents bigint not null default 0 check (removed_cost_cents >= 0);
comment on column tour_items.removed_revenue_cents is 'Verkaufswert der aus Kartons entfernten Produkte (mindert den Umsatz).';
comment on column tour_items.removed_cost_cents is 'Einkaufswert der aus Kartons zurückgebrachten Produkte (mindert den Wareneinsatz).';

create table tour_item_removals (
  id uuid primary key default gen_random_uuid(),
  tour_item_id uuid not null references tour_items (id) on delete cascade,
  content_product_id uuid not null references products (id) on delete restrict,
  content_name text not null,
  unit product_unit not null,
  returned_qty bigint not null default 0 check (returned_qty >= 0),
  gift_qty bigint not null default 0 check (gift_qty >= 0),
  -- Preise zum Zeitpunkt des Abschlusses (Cent pro Basiseinheit, bei kg pro Kilogramm)
  sell_price_cents bigint not null check (sell_price_cents >= 0),
  buy_price_cents bigint not null check (buy_price_cents >= 0),
  tenant_id uuid not null default current_tenant() references tenants (id) on delete restrict,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (tour_item_id, content_product_id),
  check (returned_qty + gift_qty > 0)
);
create index tour_item_removals_item_idx on tour_item_removals (tour_item_id);
create index tour_item_removals_product_idx on tour_item_removals (content_product_id);
create index tour_item_removals_tenant_idx on tour_item_removals (tenant_id);
comment on table tour_item_removals is 'Aus einem Karton entfernte Produkte (zurück oder geschenkt) beim Tour-Abschluss.';

create trigger a_audit before insert or update on tour_item_removals
  for each row execute function _set_audit_columns();
create trigger a0_tenant before insert or update on tour_item_removals
  for each row execute function _tenant_guard('tour_item_id:tour_items', 'content_product_id:products');

alter table tour_item_removals enable row level security;
create policy tour_item_removals_select on tour_item_removals for select to authenticated
  using (tenant_id = (select current_tenant()));
revoke all on tour_item_removals from authenticated, anon;
grant select on tour_item_removals to authenticated;

-- Entfernte Produkte übernehmen, prüfen und die Beträge an der Tour-Position festhalten.
create function _apply_carton_removals(p_tour_id uuid, p_returns jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_entry jsonb;
  v_removal jsonb;
  v_item tour_items;
  v_content record;
  v_returned bigint;
  v_gift bigint;
  v_revenue bigint;
  v_cost bigint;
begin
  for v_entry in select e from jsonb_array_elements(p_returns) e where jsonb_typeof(e -> 'removals') = 'array' loop
    select * into v_item from tour_items
    where tour_id = p_tour_id and product_id = (v_entry ->> 'product_id')::uuid;
    if not found then
      raise exception 'Ein Produkt in der Rückgabe gehört nicht zu dieser Tour.';
    end if;
    if v_item.unit <> 'carton' then
      raise exception 'Nur aus Kartons lassen sich einzelne Produkte entfernen (‚%‘).', v_item.product_name;
    end if;

    v_revenue := 0;
    v_cost := 0;
    delete from tour_item_removals where tour_item_id = v_item.id;

    for v_removal in select r from jsonb_array_elements(v_entry -> 'removals') r loop
      v_returned := coalesce((v_removal ->> 'returned_qty')::bigint, 0);
      v_gift := coalesce((v_removal ->> 'gift_qty')::bigint, 0);
      if v_returned < 0 or v_gift < 0 then
        raise exception 'Die Mengen dürfen nicht negativ sein.';
      end if;
      if v_returned + v_gift = 0 then
        continue;
      end if;

      select c.qty as per_carton, p.id, p.name, p.unit, p.sell_price_net_cents, p.buy_price_net_cents
      into v_content
      from product_contents c
      join products p on p.id = c.content_product_id
      where c.product_id = v_item.product_id and c.content_product_id = (v_removal ->> 'product_id')::uuid;
      if not found then
        raise exception 'Das Produkt gehört nicht zum Inhalt von ‚%‘.', v_item.product_name;
      end if;

      -- höchstens so viele, wie in den bezahlten Kartons stecken
      if v_returned + v_gift > v_content.per_carton * v_item.billed_qty then
        raise exception 'Aus ‚%‘ können höchstens % ‚%‘ entfernt werden.',
          v_item.product_name, v_content.per_carton * v_item.billed_qty, v_content.name;
      end if;

      insert into tour_item_removals (
        tour_item_id, content_product_id, content_name, unit, returned_qty, gift_qty,
        sell_price_cents, buy_price_cents
      ) values (
        v_item.id, v_content.id, v_content.name, v_content.unit, v_returned, v_gift,
        v_content.sell_price_net_cents, v_content.buy_price_net_cents
      );
      v_revenue := v_revenue + line_value_cents(v_content.unit, v_returned + v_gift, v_content.sell_price_net_cents);
      v_cost := v_cost + line_value_cents(v_content.unit, v_returned, v_content.buy_price_net_cents);
    end loop;

    if v_revenue > line_value_cents(v_item.unit, v_item.billed_qty, v_item.sell_price_cents) then
      raise exception 'Der Wert der entfernten Produkte ist höher als der Preis von ‚%‘.', v_item.product_name;
    end if;
    update tour_items set removed_revenue_cents = v_revenue, removed_cost_cents = v_cost where id = v_item.id;
  end loop;
end
$$;
revoke all on function _apply_carton_removals(uuid, jsonb) from public, anon, authenticated;

-- close_tour, reopen_tour und die Top-Produkte anpassen (ohne sie neu abzutippen).
do $$
declare
  v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'close_tour';
  v_def := replace(
    v_def,
    'perform _apply_tour_returns(p_tour_id, coalesce(p_returns, ''[]''::jsonb));',
    E'perform _apply_tour_returns(p_tour_id, coalesce(p_returns, ''[]''::jsonb));\n  perform _apply_carton_removals(p_tour_id, coalesce(p_returns, ''[]''::jsonb));'
  );
  v_def := replace(
    v_def,
    'line_value_cents(unit, billed_qty, sell_price_cents)',
    '(line_value_cents(unit, billed_qty, sell_price_cents) - removed_revenue_cents)'
  );
  v_def := replace(
    v_def,
    'line_value_cents(unit, sold_qty, buy_price_cents)',
    '(line_value_cents(unit, sold_qty, buy_price_cents) - removed_cost_cents)'
  );
  if v_def not like '%_apply_carton_removals%' or v_def not like '%removed_revenue_cents%'
     or v_def not like '%removed_cost_cents%' then
    raise exception 'close_tour konnte nicht angepasst werden';
  end if;
  execute v_def;

  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'reopen_tour';
  v_def := replace(
    v_def,
    'set returned_qty = 0, gift_qty = 0 where id = v_item.id;',
    E'set returned_qty = 0, gift_qty = 0, removed_revenue_cents = 0, removed_cost_cents = 0 where id = v_item.id;\n    delete from tour_item_removals where tour_item_id = v_item.id;'
  );
  if v_def not like '%tour_item_removals%' then
    raise exception 'reopen_tour konnte nicht angepasst werden';
  end if;
  execute v_def;

  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'report_top_products';
  v_def := replace(
    v_def,
    'line_value_cents(ti.unit, ti.billed_qty, ti.sell_price_cents)',
    '(line_value_cents(ti.unit, ti.billed_qty, ti.sell_price_cents) - ti.removed_revenue_cents)'
  );
  if v_def not like '%removed_revenue_cents%' then
    raise exception 'report_top_products konnte nicht angepasst werden';
  end if;
  execute v_def;
end
$$;
