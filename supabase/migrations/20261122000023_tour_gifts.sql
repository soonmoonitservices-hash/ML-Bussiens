-- Geschenkte Produkte beim Tour-Abschluss.
-- Geschenkte Ware verlässt das Lager (wird also nicht zurückgebucht), bringt aber keinen
-- Umsatz. Der Einkaufspreis zählt als Wareneinsatz und senkt den Gewinn.
--   sold_qty   = geladen − zurück            (Ware, die das Lager dauerhaft verlassen hat)
--   billed_qty = geladen − zurück − geschenkt (Ware, die bezahlt wird: Umsatz)

alter table tour_items
  add column gift_qty bigint not null default 0 check (gift_qty >= 0);
alter table tour_items
  add constraint tour_items_gift_within_load check (returned_qty + gift_qty <= loaded_qty);
alter table tour_items
  add column billed_qty bigint generated always as (loaded_qty - returned_qty - gift_qty) stored;

comment on column tour_items.gift_qty is 'Verschenkte Menge in Basiseinheit: kein Umsatz, Einkaufspreis zählt als Wareneinsatz.';
comment on column tour_items.billed_qty is 'Bezahlte Menge = geladen − zurück − geschenkt (Basis für den Umsatz).';

-- Rückgaben und Geschenke übernehmen. Pro Produkt: {"product_id", "returned_qty", "gift_qty"}.
create or replace function _apply_tour_returns(p_tour_id uuid, p_returns jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_item record;
  v_returned bigint;
  v_gift bigint;
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
    select coalesce((e ->> 'returned_qty')::bigint, 0), coalesce((e ->> 'gift_qty')::bigint, 0)
    into v_returned, v_gift
    from jsonb_array_elements(p_returns) e
    where (e ->> 'product_id')::uuid = v_item.product_id;
    v_returned := coalesce(v_returned, 0);
    v_gift := coalesce(v_gift, 0);

    if v_returned < 0 or v_returned > v_item.loaded_qty then
      raise exception 'Zurückgebracht für ‚%‘ muss zwischen 0 und % liegen.',
        v_item.product_name, _fmt_qty(v_item.unit, v_item.loaded_qty);
    end if;
    if v_gift < 0 or v_returned + v_gift > v_item.loaded_qty then
      raise exception 'Zurück und geschenkt zusammen dürfen für ‚%‘ höchstens % sein.',
        v_item.product_name, _fmt_qty(v_item.unit, v_item.loaded_qty);
    end if;

    update tour_items set returned_qty = v_returned, gift_qty = v_gift where id = v_item.id;
    perform _move_stock(v_item.product_id, v_returned, 'tour_return', null, 'tours', p_tour_id);
  end loop;
end
$$;

-- Bestehende Funktionen anpassen, ohne sie neu abzutippen (so bleibt das Rate-Limit aus
-- Migration 19 erhalten): Umsatz aus billed_qty, Wiederöffnen setzt Geschenke zurück.
do $$
declare
  v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'close_tour';
  v_def := replace(v_def, 'sold_qty, sell_price_cents', 'billed_qty, sell_price_cents');
  if v_def not like '%billed_qty, sell_price_cents%' then
    raise exception 'close_tour konnte nicht angepasst werden';
  end if;
  execute v_def;

  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'reopen_tour';
  v_def := replace(v_def, 'set returned_qty = 0 where', 'set returned_qty = 0, gift_qty = 0 where');
  if v_def not like '%gift_qty = 0%' then
    raise exception 'reopen_tour konnte nicht angepasst werden';
  end if;
  execute v_def;

  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'report_top_products';
  v_def := replace(v_def, 'ti.sold_qty', 'ti.billed_qty');
  if v_def not like '%ti.billed_qty%' then
    raise exception 'report_top_products konnte nicht angepasst werden';
  end if;
  execute v_def;

  -- billed_qty ist berechnet und ändert sich mit loaded_qty mit (wie sold_qty).
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = '_tour_items_guard';
  v_def := replace(v_def, '''sold_qty'', ''updated_at''', '''sold_qty'', ''billed_qty'', ''updated_at''');
  if v_def not like '%billed_qty%' then
    raise exception '_tour_items_guard konnte nicht angepasst werden';
  end if;
  execute v_def;
end
$$;
