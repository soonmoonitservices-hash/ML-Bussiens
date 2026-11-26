-- Touren, Tour-Positionen und Ausgaben (eine Tabelle für alle Ausgaben und Belege).

create table tours (
  id uuid primary key default gen_random_uuid(),
  -- erst beim Start vergeben (T-2026-001), damit Entwürfe keine Lücken erzeugen
  number text unique,
  driver_id uuid not null references drivers (id) on delete restrict,
  driver_name text not null default '',
  name text,
  note text,
  planned_at timestamptz not null default now(),
  status tour_status not null default 'draft',
  started_at timestamptz,
  started_by uuid,
  closed_at timestamptz,
  closed_by uuid,
  cash_received_cents bigint check (cash_received_cents >= 0),
  difference_reason text,
  -- beim Abschluss eingefroren:
  revenue_net_cents bigint,
  revenue_gross_cents bigint,
  cost_cents bigint,
  expenses_gross_cents bigint,
  expenses_net_cents bigint,
  expected_cash_cents bigint,
  difference_cents bigint,
  profit_cents bigint,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (status = 'draft' or number is not null),
  check (status <> 'closed' or (cash_received_cents is not null and profit_cents is not null))
);

create table tour_items (
  id uuid primary key default gen_random_uuid(),
  tour_id uuid not null references tours (id) on delete cascade,
  product_id uuid not null references products (id) on delete restrict,
  -- Kopien vom Produkt (Snapshot), damit spätere Preisänderungen nichts verändern
  product_name text not null,
  unit product_unit not null,
  units_per_carton bigint,
  buy_price_cents bigint not null check (buy_price_cents >= 0),
  sell_price_cents bigint not null check (sell_price_cents >= 0),
  vat_rate int not null check (vat_rate in (0, 7, 19)),
  loaded_qty bigint not null check (loaded_qty > 0),
  returned_qty bigint not null default 0 check (returned_qty >= 0),
  sold_qty bigint generated always as (loaded_qty - returned_qty) stored,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (tour_id, product_id),
  check (returned_qty <= loaded_qty)
);

create table expenses (
  id uuid primary key default gen_random_uuid(),
  date date not null default berlin_today(),
  year_month text generated always as (
    extract(year from date)::int::text || '-' || lpad(extract(month from date)::int::text, 2, '0')
  ) stored,
  title text not null check (btrim(title) <> ''),
  category text not null default 'Sonstiges',
  gross_cents bigint not null check (gross_cents >= 0),
  vat_rate int not null default 0 check (vat_rate in (0, 7, 19)),
  net_cents bigint generated always as (net_from_gross_cents(gross_cents, vat_rate)) stored,
  vat_cents bigint generated always as (gross_cents - net_from_gross_cents(gross_cents, vat_rate)) stored,
  image_path text,
  tour_id uuid references tours (id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create index tours_status_planned_idx on tours (status, planned_at);
create index tours_driver_planned_idx on tours (driver_id, planned_at);
create index tour_items_product_idx on tour_items (product_id);
create index expenses_year_month_idx on expenses (year_month);
create index expenses_tour_idx on expenses (tour_id);
create index expenses_date_idx on expenses (date);

create trigger a_audit before insert or update on tours
  for each row execute function _set_audit_columns();
create trigger a_audit before insert or update on tour_items
  for each row execute function _set_audit_columns();
create trigger a_audit before insert or update on expenses
  for each row execute function _set_audit_columns();

-- ---------------------------------------------------------------- tours

-- Neue Touren sind immer Entwürfe; Fahrername wird als Kopie gespeichert.
create function _tours_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_driver drivers;
begin
  select * into v_driver from drivers where id = new.driver_id;
  if not v_driver.active then
    raise exception 'Der Fahrer ist deaktiviert.';
  end if;
  new.driver_name := v_driver.name;

  if not _is_bypass() then
    new.number := null;
    new.status := 'draft';
    new.started_at := null;
    new.started_by := null;
    new.closed_at := null;
    new.closed_by := null;
    new.cash_received_cents := null;
    new.difference_reason := null;
    new.revenue_net_cents := null;
    new.revenue_gross_cents := null;
    new.cost_cents := null;
    new.expenses_gross_cents := null;
    new.expenses_net_cents := null;
    new.expected_cash_cents := null;
    new.difference_cents := null;
    new.profit_cents := null;
  end if;
  return new;
end
$$;

create trigger b_before_insert before insert on tours
  for each row execute function _tours_before_insert();

-- Entwurf frei bearbeitbar, unterwegs nur Name und Notiz, abgeschlossen gar nicht.
-- Status und Abrechnungswerte ändern nur die Tour-Funktionen.
create function _tours_guard_update() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_editable text[];
  v_driver drivers;
begin
  if _is_bypass() then
    return new;
  end if;

  if old.status = 'closed' then
    raise exception 'Abgeschlossene Touren können nicht geändert werden.';
  end if;

  v_editable := array['name', 'note', 'updated_at', 'updated_by', 'created_at', 'created_by'];
  if old.status = 'draft' then
    v_editable := v_editable || array['driver_id', 'driver_name', 'planned_at'];
  end if;

  if (to_jsonb(new) - v_editable) is distinct from (to_jsonb(old) - v_editable) then
    if old.status = 'draft' then
      raise exception 'Status, Nummer und Abrechnung einer Tour ändern sich nur über die Tour-Funktionen.';
    end if;
    raise exception 'Eine Tour, die unterwegs ist, kann nur noch in Name und Notiz geändert werden.';
  end if;

  if new.driver_id <> old.driver_id then
    select * into v_driver from drivers where id = new.driver_id;
    if not v_driver.active then
      raise exception 'Der Fahrer ist deaktiviert.';
    end if;
    new.driver_name := v_driver.name;
  end if;
  return new;
end
$$;

create trigger b_guard_update before update on tours
  for each row execute function _tours_guard_update();

create function _tours_guard_delete() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.status <> 'draft' and not _is_bypass() then
    raise exception 'Nur Entwürfe können gelöscht werden.';
  end if;
  return old;
end
$$;

create trigger b_guard_delete before delete on tours
  for each row execute function _tours_guard_delete();

-- ----------------------------------------------------------- tour_items

-- Kopiert Name, Einheit, Preise und USt vom Produkt. Die App schickt nur product_id + Menge.
create function _tour_items_snapshot() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_product products;
begin
  select * into v_product from products where id = new.product_id;
  if not v_product.active then
    raise exception 'Das Produkt ‚%‘ ist deaktiviert.', v_product.name;
  end if;
  new.product_name := v_product.name;
  new.unit := v_product.unit;
  new.units_per_carton := v_product.units_per_carton;
  new.buy_price_cents := v_product.buy_price_net_cents;
  new.sell_price_cents := v_product.sell_price_net_cents;
  new.vat_rate := v_product.vat_rate;
  new.returned_qty := 0;
  return new;
end
$$;

create trigger b_snapshot before insert on tour_items
  for each row execute function _tour_items_snapshot();

-- Positionen sind nur änderbar, solange die Tour ein Entwurf ist.
create function _tour_items_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_status tour_status;
  -- sold_qty ist berechnet (geladen − zurück) und ändert sich mit loaded_qty mit
  v_editable text[] := array['loaded_qty', 'sold_qty', 'updated_at', 'updated_by', 'created_at', 'created_by'];
begin
  if _is_bypass() then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  select status into v_status from tours
  where id = case when tg_op = 'DELETE' then old.tour_id else new.tour_id end;
  -- Tour existiert nicht mehr (wird gerade gelöscht): Positionen mitlöschen
  if v_status is null then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if v_status <> 'draft' then
    raise exception 'Die Ware einer Tour kann nur im Entwurf geändert werden.';
  end if;

  if tg_op = 'UPDATE'
     and (to_jsonb(new) - v_editable) is distinct from (to_jsonb(old) - v_editable) then
    raise exception 'Bei einer Position kann nur die Menge geändert werden.';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end
$$;

create trigger c_guard before insert or update or delete on tour_items
  for each row execute function _tour_items_guard();

-- ------------------------------------------------------------- expenses

-- Ausgaben einer abgeschlossenen Tour sind eingefroren (auch neue kommen nicht mehr dazu).
create function _expenses_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_is_closed boolean := false;
begin
  if _is_bypass() then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  if tg_op in ('UPDATE', 'DELETE') then
    v_is_closed := exists (select 1 from tours where id = old.tour_id and status = 'closed');
  end if;
  if not v_is_closed and tg_op in ('INSERT', 'UPDATE') then
    v_is_closed := exists (select 1 from tours where id = new.tour_id and status = 'closed');
  end if;
  if v_is_closed then
    raise exception 'Ausgaben einer abgeschlossenen Tour können nicht geändert werden.';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end
$$;

create trigger b_guard before insert or update or delete on expenses
  for each row execute function _expenses_guard();
