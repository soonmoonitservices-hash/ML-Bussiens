-- Produkte, Lagerbewegungen und Lagerfunktionen.
-- Mengen stehen immer in der Basiseinheit (Stück/Glas/Karton, bei kg in Gramm).

create table products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  name text not null check (btrim(name) <> ''),
  category text not null default '',
  unit product_unit not null,
  -- nur bei Stück/Glas: so viele Basiseinheiten stecken in einem Karton
  units_per_carton bigint check (units_per_carton > 0),
  -- Preise in Cent pro Basiseinheit (bei kg: Cent pro Kilogramm)
  buy_price_net_cents bigint not null check (buy_price_net_cents >= 0),
  sell_price_net_cents bigint not null check (sell_price_net_cents >= 0),
  vat_rate int not null default 7 check (vat_rate in (0, 7, 19)),
  min_stock bigint not null default 0 check (min_stock >= 0),
  stock bigint not null default 0 check (stock >= 0),
  image_path text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (units_per_carton is null or unit in ('piece', 'jar'))
);

create table stock_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products (id) on delete restrict,
  type movement_type not null,
  qty bigint not null check (qty <> 0),
  stock_after bigint not null check (stock_after >= 0),
  reason text,
  ref_table text,
  ref_id uuid,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create index stock_movements_product_idx on stock_movements (product_id, created_at);
create index stock_movements_ref_idx on stock_movements (ref_table, ref_id);
create index products_category_idx on products (category);

create trigger a_audit before insert or update on products
  for each row execute function _set_audit_columns();
create trigger a_audit before insert or update on stock_movements
  for each row execute function _set_audit_columns();

-- Artikelnummer automatisch vergeben, wenn keine angegeben wurde.
create function _products_set_sku() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.sku is null or btrim(new.sku) = '' then
    new.sku := _next_sku();
  end if;
  return new;
end
$$;

create trigger b_set_sku before insert on products
  for each row execute function _products_set_sku();

-- Der Bestand darf nur über Wareneingang, Korrektur und Touren/Rechnungen geändert werden.
create function _products_guard_stock() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.stock <> old.stock and not _is_bypass() then
    raise exception 'Der Bestand kann nur über Wareneingang oder Korrektur geändert werden.';
  end if;
  return new;
end
$$;

create trigger b_guard_stock before update on products
  for each row execute function _products_guard_stock();

-- Ein Produkt mit Anfangsbestand bekommt dafür eine nachvollziehbare Lagerbewegung.
create function _products_initial_stock() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.stock > 0 then
    insert into stock_movements (product_id, type, qty, stock_after, reason, ref_table, ref_id)
    values (new.id, 'intake', new.stock, new.stock, 'Anfangsbestand', 'products', new.id);
  end if;
  return new;
end
$$;

create trigger c_initial_stock after insert on products
  for each row execute function _products_initial_stock();

-- Lagerbewegungen sind unveränderlich.
create function _forbid_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  raise exception 'Lagerbewegungen können nicht geändert oder gelöscht werden.';
end
$$;

create trigger b_forbid_change before update or delete on stock_movements
  for each row execute function _forbid_change();

-- Einzige Stelle, die den Bestand ändert: sperrt das Produkt, verhindert Minusbestand
-- und schreibt die Lagerbewegung.
create function _move_stock(
  p_product_id uuid,
  p_qty bigint,
  p_type movement_type,
  p_reason text,
  p_ref_table text,
  p_ref_id uuid
) returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_product products;
  v_new_stock bigint;
  v_previous text;
begin
  if p_qty = 0 then
    return null;
  end if;

  select * into v_product from products where id = p_product_id for update;
  if not found then
    raise exception 'Produkt nicht gefunden.';
  end if;

  v_new_stock := v_product.stock + p_qty;
  if v_new_stock < 0 then
    raise exception 'Nicht genug Bestand für ‚%‘ (es fehlen %).',
      v_product.name, _fmt_qty(v_product.unit, -v_new_stock);
  end if;

  v_previous := _bypass_on();
  update products set stock = v_new_stock where id = p_product_id;
  perform _bypass_restore(v_previous);

  insert into stock_movements (product_id, type, qty, stock_after, reason, ref_table, ref_id)
  values (p_product_id, p_type, p_qty, v_new_stock, p_reason, p_ref_table, p_ref_id);

  return v_new_stock;
end
$$;

-- Wareneingang buchen. Gibt den neuen Bestand zurück.
create function stock_intake(p_product_id uuid, p_qty bigint, p_reason text default null)
returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_active boolean;
begin
  perform _require_active();
  if p_qty is null or p_qty <= 0 then
    raise exception 'Die Menge muss größer als 0 sein.';
  end if;

  select active into v_active from products where id = p_product_id;
  if v_active is null then
    raise exception 'Produkt nicht gefunden.';
  end if;
  if not v_active then
    raise exception 'Das Produkt ist deaktiviert.';
  end if;

  return _move_stock(p_product_id, p_qty, 'intake', nullif(btrim(p_reason), ''), 'products', p_product_id);
end
$$;

-- Bestand auf einen gezählten Wert korrigieren. Begründung ist Pflicht.
create function stock_correct(p_product_id uuid, p_new_stock bigint, p_reason text)
returns bigint
language plpgsql security definer set search_path = public as $$
declare
  v_current bigint;
begin
  perform _require_active();
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'Bitte eine Begründung für die Korrektur angeben.';
  end if;
  if p_new_stock is null or p_new_stock < 0 then
    raise exception 'Der Bestand darf nicht negativ sein.';
  end if;

  select stock into v_current from products where id = p_product_id for update;
  if not found then
    raise exception 'Produkt nicht gefunden.';
  end if;
  if v_current = p_new_stock then
    raise exception 'Der Bestand ist bereits %.', p_new_stock;
  end if;

  return _move_stock(
    p_product_id, p_new_stock - v_current, 'correction', btrim(p_reason), 'products', p_product_id
  );
end
$$;

grant execute on function stock_intake(uuid, bigint, text) to authenticated;
grant execute on function stock_correct(uuid, bigint, text) to authenticated;
