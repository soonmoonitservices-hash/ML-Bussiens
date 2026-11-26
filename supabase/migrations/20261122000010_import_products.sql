-- CSV-Import: legt viele Produkte in EINER Transaktion an. Bei einem Fehler wird nichts angelegt.
-- p_rows: [{"name", "category", "unit", "units_per_carton", "buy_price_net_cents",
--           "sell_price_net_cents", "vat_rate", "min_stock", "stock"}]
-- Gibt die Anzahl angelegter Produkte zurück.
create function import_products(p_rows jsonb) returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_row jsonb;
  v_line int;
  v_count int := 0;
begin
  perform _require_active();
  if jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) = 0 then
    raise exception 'Die Importliste ist leer.';
  end if;

  for v_row, v_line in
    select e.value, e.ordinality::int from jsonb_array_elements(p_rows) with ordinality e
  loop
    begin
      insert into products (
        name, category, unit, units_per_carton, buy_price_net_cents, sell_price_net_cents,
        vat_rate, min_stock, stock
      ) values (
        v_row ->> 'name',
        coalesce(v_row ->> 'category', ''),
        (v_row ->> 'unit')::product_unit,
        nullif(v_row ->> 'units_per_carton', '')::bigint,
        (v_row ->> 'buy_price_net_cents')::bigint,
        (v_row ->> 'sell_price_net_cents')::bigint,
        coalesce((v_row ->> 'vat_rate')::int, 7),
        coalesce((v_row ->> 'min_stock')::bigint, 0),
        coalesce((v_row ->> 'stock')::bigint, 0)
      );
    exception when others then
      raise exception 'Zeile %: %', v_line, sqlerrm;
    end;
    v_count := v_count + 1;
  end loop;

  return v_count;
end
$$;

grant execute on function import_products(jsonb) to authenticated;
