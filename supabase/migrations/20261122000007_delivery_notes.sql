-- Lieferscheine mit Unterschrift. Nach der Unterschrift ist nur noch das PDF änderbar.

create table delivery_notes (
  id uuid primary key default gen_random_uuid(),
  number text not null unique,
  date date not null default berlin_today(),
  recipient_name text not null check (btrim(recipient_name) <> ''),
  recipient_address text not null default '',
  tour_id uuid references tours (id) on delete restrict,
  note text,
  signature_path text,
  signer_name text,
  signed_at timestamptz,
  pdf_path text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table delivery_note_items (
  id uuid primary key default gen_random_uuid(),
  delivery_note_id uuid not null references delivery_notes (id) on delete cascade,
  product_id uuid not null references products (id) on delete restrict,
  -- Kopien vom Produkt
  product_name text not null,
  unit product_unit not null,
  units_per_carton bigint,
  qty bigint not null check (qty > 0),
  position int not null,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create index delivery_notes_date_idx on delivery_notes (date);
create index delivery_notes_tour_idx on delivery_notes (tour_id);
create index delivery_note_items_note_idx on delivery_note_items (delivery_note_id, position);
create index delivery_note_items_product_idx on delivery_note_items (product_id);

create trigger a_audit before insert or update on delivery_notes
  for each row execute function _set_audit_columns();
create trigger a_audit before insert or update on delivery_note_items
  for each row execute function _set_audit_columns();

-- Neue Lieferscheine bekommen automatisch eine Nummer und sind ungezeichnet.
create function _delivery_notes_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.number := next_number('delivery_note');
  new.signature_path := null;
  new.signer_name := null;
  new.signed_at := null;
  return new;
end
$$;

create trigger b_before_insert before insert on delivery_notes
  for each row execute function _delivery_notes_before_insert();

-- Unterschreiben nur mit Positionen, Namen und Unterschriftsbild; danach nur noch pdf_path ändern.
create function _delivery_notes_guard_update() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_pdf_only text[] := array['pdf_path', 'updated_at', 'updated_by', 'created_at', 'created_by'];
begin
  if _is_bypass() then
    return new;
  end if;

  if new.number <> old.number then
    raise exception 'Die Lieferscheinnummer kann nicht geändert werden.';
  end if;

  if old.signed_at is not null then
    if (to_jsonb(new) - v_pdf_only) is distinct from (to_jsonb(old) - v_pdf_only) then
      raise exception 'Ein unterschriebener Lieferschein kann nicht mehr geändert werden.';
    end if;
    return new;
  end if;

  if new.signed_at is not null then
    if not exists (select 1 from delivery_note_items where delivery_note_id = new.id) then
      raise exception 'Zum Unterschreiben braucht der Lieferschein mindestens eine Position.';
    end if;
    if new.signer_name is null or btrim(new.signer_name) = '' then
      raise exception 'Bitte den Namen des Unterzeichners eintragen.';
    end if;
    if new.signature_path is null or btrim(new.signature_path) = '' then
      raise exception 'Das Unterschriftsbild fehlt.';
    end if;
    new.signed_at := now();
  end if;
  return new;
end
$$;

create trigger b_guard_update before update on delivery_notes
  for each row execute function _delivery_notes_guard_update();

create function _delivery_notes_guard_delete() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.signed_at is not null and not _is_bypass() then
    raise exception 'Ein unterschriebener Lieferschein kann nicht gelöscht werden.';
  end if;
  return old;
end
$$;

create trigger b_guard_delete before delete on delivery_notes
  for each row execute function _delivery_notes_guard_delete();

-- Positionen: Kopie von Name/Einheit, laufende Position; nur änderbar, solange nicht unterschrieben.
create function _delivery_note_items_snapshot() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_product products;
begin
  select * into v_product from products where id = new.product_id;
  new.product_name := v_product.name;
  new.unit := v_product.unit;
  new.units_per_carton := v_product.units_per_carton;
  if new.position is null then
    select coalesce(max(position), 0) + 1 into new.position
    from delivery_note_items where delivery_note_id = new.delivery_note_id;
  end if;
  return new;
end
$$;

create trigger b_snapshot before insert on delivery_note_items
  for each row execute function _delivery_note_items_snapshot();

create function _delivery_note_items_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_signed_at timestamptz;
  v_note_found boolean;
begin
  if _is_bypass() then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  select signed_at, true into v_signed_at, v_note_found
  from delivery_notes
  where id = case when tg_op = 'DELETE' then old.delivery_note_id else new.delivery_note_id end;

  -- Lieferschein existiert nicht mehr (wird gerade gelöscht): Positionen mitlöschen
  if v_note_found is distinct from true then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  if v_signed_at is not null then
    raise exception 'Die Positionen eines unterschriebenen Lieferscheins können nicht geändert werden.';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end
$$;

create trigger c_guard before insert or update or delete on delivery_note_items
  for each row execute function _delivery_note_items_guard();
