-- Rechnungen. Entwürfe sind frei bearbeitbar; festgeschriebene Rechnungen sind unveränderbar (GoBD).

create table invoices (
  id uuid primary key default gen_random_uuid(),
  -- erst beim Festschreiben vergeben (RE-2026-001), damit die Nummern lückenlos bleiben
  number text unique,
  date date not null default berlin_today(),
  service_date date not null default berlin_today(),
  due_date date,
  recipient_name text not null default '',
  recipient_address text not null default '',
  -- für E-Rechnung (frei eintippen): USt-IdNr. des Empfängers, Leitweg-ID / Käuferreferenz
  recipient_vat_id text,
  buyer_reference text,
  note text,
  net_cents bigint not null default 0,
  vat7_cents bigint not null default 0,
  vat19_cents bigint not null default 0,
  gross_cents bigint not null default 0,
  -- Wareneinsatz (Einkaufswert der Positionen)
  cost_cents bigint not null default 0,
  status invoice_status not null default 'draft',
  finalized_at timestamptz,
  finalized_by uuid,
  paid_at date,
  cancels_invoice_id uuid references invoices (id) on delete restrict,
  cancelled_by_invoice_id uuid references invoices (id) on delete restrict,
  tour_id uuid references tours (id) on delete restrict,
  delivery_note_id uuid references delivery_notes (id) on delete restrict,
  stock_booked boolean not null default false,
  -- beim Festschreiben festgehalten (ändert sich später nie mehr):
  -- Kleinunternehmer (ohne USt) und Kleinbetragsrechnung (bis 250 € brutto)
  is_small_business boolean not null default false,
  is_small_amount boolean not null default false,
  pdf_path text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (status = 'draft' or number is not null),
  check (due_date is null or due_date >= date)
);

create table invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references invoices (id) on delete cascade,
  -- null = freie Position ohne Produkt
  product_id uuid references products (id) on delete restrict,
  -- Kopien vom Produkt
  product_name text not null check (btrim(product_name) <> ''),
  unit product_unit not null,
  vat_rate int not null check (vat_rate in (0, 7, 19)),
  buy_price_cents bigint not null default 0 check (buy_price_cents >= 0),
  -- negativ nur bei Stornorechnungen
  qty bigint not null check (qty <> 0),
  price_net_cents bigint not null check (price_net_cents >= 0),
  line_net_cents bigint generated always as (line_value_cents(unit, qty, price_net_cents)) stored,
  position int not null,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create index invoices_status_due_idx on invoices (status, due_date);
create index invoices_date_idx on invoices (date);
create index invoices_tour_idx on invoices (tour_id);
create index invoices_delivery_note_idx on invoices (delivery_note_id);
create index invoices_cancels_idx on invoices (cancels_invoice_id);
create index invoice_items_invoice_idx on invoice_items (invoice_id, position);
create index invoice_items_product_idx on invoice_items (product_id);

create trigger a_audit before insert or update on invoices
  for each row execute function _set_audit_columns();
create trigger a_audit before insert or update on invoice_items
  for each row execute function _set_audit_columns();

-- Berechnet die Summen einer Rechnung neu: Netto, USt 7 % und 19 % getrennt gerundet, Brutto, Wareneinsatz.
-- Kleinunternehmer berechnen keine USt (Brutto = Netto).
create function _recalc_invoice(p_invoice_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_net bigint;
  v_net7 bigint;
  v_net19 bigint;
  v_cost bigint;
  v_vat7 bigint;
  v_vat19 bigint;
  v_previous text;
  v_is_small_business boolean;
begin
  select is_small_business into v_is_small_business from company_settings;

  select
    coalesce(sum(line_net_cents), 0),
    coalesce(sum(line_net_cents) filter (where vat_rate = 7), 0),
    coalesce(sum(line_net_cents) filter (where vat_rate = 19), 0),
    coalesce(sum(line_value_cents(unit, qty, buy_price_cents)), 0)
  into v_net, v_net7, v_net19, v_cost
  from invoice_items where invoice_id = p_invoice_id;

  v_vat7 := case when v_is_small_business then 0 else round(v_net7::numeric * 7 / 100)::bigint end;
  v_vat19 := case when v_is_small_business then 0 else round(v_net19::numeric * 19 / 100)::bigint end;

  v_previous := _bypass_on();
  update invoices
  set net_cents = v_net,
      vat7_cents = v_vat7,
      vat19_cents = v_vat19,
      gross_cents = v_net + v_vat7 + v_vat19,
      cost_cents = v_cost
  where id = p_invoice_id;
  perform _bypass_restore(v_previous);
end
$$;

-- Neue Rechnungen sind immer Entwürfe ohne Nummer und ohne Summen.
create function _invoices_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not _is_bypass() then
    new.number := null;
    new.status := 'draft';
    new.net_cents := 0;
    new.vat7_cents := 0;
    new.vat19_cents := 0;
    new.gross_cents := 0;
    new.cost_cents := 0;
    new.finalized_at := null;
    new.finalized_by := null;
    new.paid_at := null;
    new.cancels_invoice_id := null;
    new.cancelled_by_invoice_id := null;
    new.stock_booked := false;
    new.is_small_business := false;
    new.is_small_amount := false;
  end if;
  return new;
end
$$;

create trigger b_before_insert before insert on invoices
  for each row execute function _invoices_before_insert();

-- Entwurf: nur Inhaltsfelder änderbar. Festgeschrieben: nur noch pdf_path.
create function _invoices_guard_update() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_system text[] := array['updated_at', 'updated_by', 'created_at', 'created_by', 'pdf_path'];
  v_draft_editable text[];
begin
  if _is_bypass() then
    return new;
  end if;

  if old.status <> 'draft' then
    if (to_jsonb(new) - v_system) is distinct from (to_jsonb(old) - v_system) then
      raise exception 'Eine festgeschriebene Rechnung kann nicht mehr geändert werden.';
    end if;
    return new;
  end if;

  v_draft_editable := v_system || array[
    'date', 'service_date', 'due_date', 'recipient_name', 'recipient_address',
    'recipient_vat_id', 'buyer_reference', 'note', 'tour_id', 'delivery_note_id'
  ];
  if (to_jsonb(new) - v_draft_editable) is distinct from (to_jsonb(old) - v_draft_editable) then
    raise exception 'Nummer, Status und Summen einer Rechnung ändern sich nur über die Rechnungs-Funktionen.';
  end if;
  return new;
end
$$;

create trigger b_guard_update before update on invoices
  for each row execute function _invoices_guard_update();

create function _invoices_guard_delete() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.status <> 'draft' and not _is_bypass() then
    raise exception 'Nur Entwürfe können gelöscht werden. Festgeschriebene Rechnungen werden storniert.';
  end if;
  return old;
end
$$;

create trigger b_guard_delete before delete on invoices
  for each row execute function _invoices_guard_delete();

-- Positionen: Kopie von Name, Einheit, USt und Einkaufspreis vom Produkt.
-- Der Verkaufspreis darf abweichen (Rabatt), sonst gilt der Preis vom Produkt.
create function _invoice_items_snapshot() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_product products;
begin
  if _is_bypass() then
    return new;
  end if;

  if new.qty is null or new.qty <= 0 then
    raise exception 'Die Menge muss größer als 0 sein.';
  end if;

  if new.product_id is not null then
    select * into v_product from products where id = new.product_id;
    new.product_name := v_product.name;
    new.unit := v_product.unit;
    new.vat_rate := v_product.vat_rate;
    new.buy_price_cents := v_product.buy_price_net_cents;
    new.price_net_cents := coalesce(new.price_net_cents, v_product.sell_price_net_cents);
  else
    -- freie Position: Name, Einheit, USt und Preis kommen von der App
    new.buy_price_cents := 0;
    if new.price_net_cents is null then
      raise exception 'Bitte einen Preis für die freie Position eintragen.';
    end if;
  end if;

  if new.position is null then
    select coalesce(max(position), 0) + 1 into new.position
    from invoice_items where invoice_id = new.invoice_id;
  end if;
  return new;
end
$$;

create trigger b_snapshot before insert on invoice_items
  for each row execute function _invoice_items_snapshot();

-- Positionen nur ändern, solange die Rechnung ein Entwurf ist.
create function _invoice_items_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_status invoice_status;
begin
  if _is_bypass() then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  select status into v_status from invoices
  where id = case when tg_op = 'DELETE' then old.invoice_id else new.invoice_id end;

  -- Rechnung existiert nicht mehr (wird gerade gelöscht): Positionen mitlöschen
  if v_status is null then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if v_status <> 'draft' then
    raise exception 'Die Positionen einer festgeschriebenen Rechnung können nicht geändert werden.';
  end if;
  if tg_op = 'UPDATE' and new.qty <= 0 then
    raise exception 'Die Menge muss größer als 0 sein.';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end
$$;

create trigger c_guard before insert or update or delete on invoice_items
  for each row execute function _invoice_items_guard();

-- Nach jeder Änderung der Positionen die Summen der Rechnung neu berechnen.
create function _invoice_items_recalc() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform _recalc_invoice(case when tg_op = 'DELETE' then old.invoice_id else new.invoice_id end);
  return null;
end
$$;

create trigger d_recalc after insert or update or delete on invoice_items
  for each row execute function _invoice_items_recalc();
