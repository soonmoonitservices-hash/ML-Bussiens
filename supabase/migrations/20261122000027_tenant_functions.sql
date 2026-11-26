-- Funktionen firmensicher machen. Sie laufen mit erhöhten Rechten (security definer), also
-- prüfen sie selbst, dass der übergebene Datensatz zur Firma des Benutzers gehört, und
-- Nummern, Artikelnummern und Firmendaten kommen aus der eigenen Firma.

-- Prüft, dass die Zeile existiert UND zur Firma des Benutzers gehört.
create function _require_row_in_tenant(p_table text, p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_found boolean;
begin
  execute format('select exists (select 1 from public.%I where id = $1 and tenant_id = public.current_tenant())', p_table)
    into v_found using p_id;
  if not v_found then
    raise exception 'Datensatz nicht gefunden.';
  end if;
end
$$;
comment on function _require_row_in_tenant(text, uuid) is 'Fehler, wenn die Zeile nicht zur Firma des Benutzers gehört.';
revoke all on function _require_row_in_tenant(text, uuid) from public, anon, authenticated;

-- Nummernkreise je Firma.
create or replace function next_number(p_type text) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_tenant uuid := current_tenant();
  v_year int := extract(year from berlin_today())::int;
  v_prefix text;
  v_value bigint;
begin
  if v_tenant is null then
    raise exception 'Bitte melden Sie sich an.';
  end if;
  v_prefix := case p_type
    when 'tour' then 'T'
    when 'delivery_note' then 'LS'
    when 'invoice' then 'RE'
  end;
  if v_prefix is null then
    raise exception 'Unbekannter Nummernkreis: %', p_type;
  end if;

  insert into number_counters (tenant_id, type, year, last_value)
  values (v_tenant, p_type, v_year, 1)
  on conflict (tenant_id, type, year) do update set last_value = number_counters.last_value + 1
  returning last_value into v_value;

  return format('%s-%s-%s', v_prefix, v_year, lpad(v_value::text, 3, '0'));
end
$$;

-- Artikelnummer ART-001, ART-002 … je Firma.
drop function _next_sku() cascade;
create function _next_sku(p_tenant uuid) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_value bigint;
begin
  insert into number_counters (tenant_id, type, year, last_value)
  values (p_tenant, 'sku', 0, 1)
  on conflict (tenant_id, type, year) do update set last_value = number_counters.last_value + 1
  returning last_value into v_value;

  return 'ART-' || lpad(v_value::text, 3, '0');
end
$$;
revoke all on function _next_sku(uuid) from public, anon, authenticated;

create or replace function _products_set_sku() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.sku is null or btrim(new.sku) = '' then
    new.sku := _next_sku(new.tenant_id);
  end if;
  return new;
end
$$;

-- Firmendaten der eigenen Firma lesen (statt „die eine Zeile“).
do $$
declare
  v_function record;
  v_def text;
begin
  for v_function in
    select p.oid, p.proname from pg_proc p
    where p.pronamespace = 'public'::regnamespace and p.prosrc like '%from company_settings;%'
  loop
    v_def := replace(pg_get_functiondef(v_function.oid),
      'from company_settings;', 'from company_settings where tenant_id = public.current_tenant();');
    if v_def like '%from company_settings;%' then
      raise exception 'Funktion % konnte nicht angepasst werden', v_function.proname;
    end if;
    execute v_def;
  end loop;
end
$$;

-- Die Firma des übergebenen Datensatzes prüfen, direkt nach der Anmelde-Prüfung.
do $$
declare
  v_spec record;
  v_def text;
begin
  for v_spec in
    select * from (values
      ('start_tour', 'tours', 'p_tour_id'),
      ('undo_start_tour', 'tours', 'p_tour_id'),
      ('close_tour', 'tours', 'p_tour_id'),
      ('reopen_tour', 'tours', 'p_tour_id'),
      ('finalize_invoice', 'invoices', 'p_invoice_id'),
      ('cancel_invoice', 'invoices', 'p_invoice_id'),
      ('mark_invoice_paid', 'invoices', 'p_invoice_id'),
      ('mark_invoice_unpaid', 'invoices', 'p_invoice_id'),
      ('invoice_from_delivery_note', 'delivery_notes', 'p_delivery_note_id'),
      ('stock_intake', 'products', 'p_product_id'),
      ('stock_correct', 'products', 'p_product_id')
    ) as t(name, tbl, param)
  loop
    select pg_get_functiondef(p.oid) into v_def
    from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = v_spec.name;
    v_def := regexp_replace(
      v_def,
      'perform (public\.)?_require_(active|chef)\(\);',
      format(E'perform _require_\\2();\n  perform public._require_row_in_tenant(%L, %s);', v_spec.tbl, v_spec.param)
    );
    if v_def not like '%_require_row_in_tenant%' then
      raise exception 'Firmenprüfung konnte in % nicht eingesetzt werden', v_spec.name;
    end if;
    execute v_def;
  end loop;
end
$$;
