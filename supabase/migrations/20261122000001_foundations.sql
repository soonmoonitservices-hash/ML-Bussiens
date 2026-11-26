-- Grundlagen: Typen, Standardrechte, zentrale Hilfsfunktionen, Nummernkreise.

create type user_role as enum ('chef', 'office');
create type product_unit as enum ('carton', 'piece', 'jar', 'kg');
create type tour_status as enum ('draft', 'active', 'closed');
create type invoice_status as enum ('draft', 'open', 'paid', 'overdue', 'cancelled');
create type movement_type as enum (
  'intake', 'tour_out', 'tour_return', 'tour_undo', 'invoice', 'invoice_cancel', 'correction'
);

-- Neue Funktionen sind standardmäßig NICHT von der App aufrufbar.
-- Wer aufrufbar sein soll, bekommt ein ausdrückliches GRANT.
alter default privileges revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;

-- Heutiges Datum in Deutschland (alle Fristen und Nummernkreise nutzen es).
create function berlin_today() returns date
language sql stable set search_path = public as $$
  select (now() at time zone 'Europe/Berlin')::date
$$;

-- Zentrale Wertberechnung: bei kg ist qty in Gramm und der Preis in Cent pro kg.
-- Kaufmännisch gerundet (0,5 Cent wird aufgerundet, bei Storno symmetrisch).
create function line_value_cents(p_unit product_unit, p_qty bigint, p_price_cents bigint)
returns bigint language sql immutable set search_path = public as $$
  select case p_unit
    when 'kg' then round(p_qty::numeric * p_price_cents / 1000)::bigint
    else p_qty * p_price_cents
  end
$$;

-- Brutto aus Netto (USt kaufmännisch gerundet).
create function gross_cents(p_net_cents bigint, p_vat_rate int) returns bigint
language sql immutable set search_path = public as $$
  select p_net_cents + round(p_net_cents::numeric * p_vat_rate / 100)::bigint
$$;

-- Netto aus Brutto (für Belege, bei denen der Bruttobetrag auf dem Beleg steht).
create function net_from_gross_cents(p_gross_cents bigint, p_vat_rate int) returns bigint
language sql immutable set search_path = public as $$
  select round(p_gross_cents::numeric * 100 / (100 + p_vat_rate))::bigint
$$;

-- Menge für Fehlermeldungen: kg-Produkte in Kilogramm, sonst die Zahl.
create function _fmt_qty(p_unit product_unit, p_qty bigint) returns text
language sql immutable set search_path = public as $$
  select case p_unit
    when 'kg' then replace(trim_scale(p_qty::numeric / 1000)::text, '.', ',') || ' kg'
    else p_qty::text
  end
$$;

-- Geld für Fehlermeldungen: 86800 → „868,00 €“, −800 → „-8,00 €“.
create function _fmt_money(p_cents bigint) returns text
language sql immutable set search_path = public as $$
  select case when p_cents < 0 then '-' else '' end
    || (abs(p_cents) / 100)::text || ',' || lpad((abs(p_cents) % 100)::text, 2, '0') || ' €'
$$;

-- Transaktions-Schalter: interne Funktionen dürfen geschützte Felder ändern.
-- Der vorherige Wert wird immer gesichert und wiederhergestellt.
create function _bypass_on() returns text
language plpgsql set search_path = public as $$
declare
  v_previous text := coalesce(current_setting('app.bypass', true), '');
begin
  perform set_config('app.bypass', 'on', true);
  return v_previous;
end
$$;

create function _bypass_restore(p_previous text) returns void
language plpgsql set search_path = public as $$
begin
  perform set_config('app.bypass', coalesce(p_previous, ''), true);
end
$$;

create function _is_bypass() returns boolean
language sql stable set search_path = public as $$
  select coalesce(current_setting('app.bypass', true), '') = 'on'
$$;

-- Setzt created_*/updated_* automatisch; created_* ist nicht überschreibbar.
create function _set_audit_columns() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := now();
    new.created_by := auth.uid();
  else
    new.created_at := old.created_at;
    new.created_by := old.created_by;
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end
$$;

-- Nummernkreise (Tour, Lieferschein, Rechnung, Artikelnummer).
create table number_counters (
  type text not null,
  year int not null,
  last_value bigint not null default 0 check (last_value >= 0),
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  primary key (type, year)
);

create trigger a_audit before insert or update on number_counters
  for each row execute function _set_audit_columns();

-- Fortlaufend pro Jahr, lückenlos, nie doppelt (Upsert sperrt die Zeile).
-- Nur intern nutzbar: würde die App Nummern abrufen, entstünden Lücken.
create function next_number(p_type text) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_year int := extract(year from berlin_today())::int;
  v_prefix text;
  v_value bigint;
begin
  v_prefix := case p_type
    when 'tour' then 'T'
    when 'delivery_note' then 'LS'
    when 'invoice' then 'RE'
  end;
  if v_prefix is null then
    raise exception 'Unbekannter Nummernkreis: %', p_type;
  end if;

  insert into number_counters (type, year, last_value)
  values (p_type, v_year, 1)
  on conflict (type, year) do update set last_value = number_counters.last_value + 1
  returning last_value into v_value;

  return format('%s-%s-%s', v_prefix, v_year, lpad(v_value::text, 3, '0'));
end
$$;

-- Artikelnummer ART-001, ART-002 … (Zähler ohne Jahr).
create function _next_sku() returns text
language plpgsql security definer set search_path = public as $$
declare
  v_value bigint;
begin
  insert into number_counters (type, year, last_value)
  values ('sku', 0, 1)
  on conflict (type, year) do update set last_value = number_counters.last_value + 1
  returning last_value into v_value;

  return 'ART-' || lpad(v_value::text, 3, '0');
end
$$;
