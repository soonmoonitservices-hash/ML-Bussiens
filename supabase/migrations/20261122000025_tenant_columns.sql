-- Jede Geschäftstabelle bekommt eine Firmen-Kennung (tenant_id).
-- Bestehende Zeilen gehören zur Firma „Standard“. Neue Zeilen erben die Firma des Benutzers;
-- Positionen und Bewegungen übernehmen sie von ihrem Elternteil und werden geprüft, damit
-- nie etwas einer anderen Firma verknüpft werden kann.

-- Spalte mit konstantem Standard anlegen (verändert bestehende Zeilen nicht, löst keine Trigger aus),
-- danach den Standard auf die Firma des Benutzers umstellen.
do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'drivers', 'products', 'tours', 'expenses', 'delivery_notes', 'invoices', 'product_bundles',
    'company_settings', 'number_counters', 'stock_movements', 'tour_items',
    'delivery_note_items', 'invoice_items', 'product_bundle_items'
  ] loop
    execute format(
      'alter table %I add column tenant_id uuid not null default %L references tenants (id) on delete restrict',
      v_table, 'a0000000-0000-4000-8000-000000000001');
    execute format('alter table %I alter column tenant_id set default current_tenant()', v_table);
    execute format('create index %I on %I (tenant_id)', v_table || '_tenant_idx', v_table);
    execute format('comment on column %I.tenant_id is %L', v_table, 'Firma, zu der die Zeile gehört.');
  end loop;
end
$$;

-- Änderungsverlauf: Firma aus der Zeile übernehmen (kann leer bleiben, dann sieht ihn niemand).
alter table change_log add column tenant_id uuid references tenants (id) on delete restrict;
alter table change_log alter column tenant_id set default current_tenant();
create index change_log_tenant_idx on change_log (tenant_id);

create function _change_log_tenant() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.tenant_id := coalesce(
    (coalesce(new.new_data, new.old_data) ->> 'tenant_id')::uuid, new.tenant_id);
  return new;
end
$$;
create trigger a0_tenant before insert on change_log
  for each row execute function _change_log_tenant();

-- Nummern und Artikelnummern zählen je Firma.
alter table products drop constraint products_sku_key;
alter table products add constraint products_tenant_sku_key unique (tenant_id, sku);
alter table tours drop constraint tours_number_key;
alter table tours add constraint tours_tenant_number_key unique (tenant_id, number);
alter table delivery_notes drop constraint delivery_notes_number_key;
alter table delivery_notes add constraint delivery_notes_tenant_number_key unique (tenant_id, number);
alter table invoices drop constraint invoices_number_key;
alter table invoices add constraint invoices_tenant_number_key unique (tenant_id, number);

alter table number_counters drop constraint number_counters_pkey;
alter table number_counters add primary key (tenant_id, type, year);

-- Firmendaten: eine Zeile je Firma.
alter table company_settings drop constraint company_settings_pkey;
alter table company_settings add primary key (tenant_id);

-- Neue Firma → leere Firmendaten anlegen.
create function _tenants_create_settings() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into company_settings (tenant_id, name) values (new.id, new.name);
  return new;
end
$$;
create trigger b_create_settings after insert on tenants
  for each row execute function _tenants_create_settings();

-- Firma von Eltern übernehmen und prüfen. Argumente: „Spalte:Tabelle“.
create function _tenant_guard() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_arg text;
  v_id uuid;
  v_tenant uuid;
begin
  foreach v_arg in array tg_argv loop
    v_id := nullif(to_jsonb(new) ->> split_part(v_arg, ':', 1), '')::uuid;
    if v_id is null then
      continue;
    end if;
    execute format('select tenant_id from public.%I where id = $1', split_part(v_arg, ':', 2))
      into v_tenant using v_id;
    if v_tenant is null then
      raise exception 'Verknüpfter Datensatz nicht gefunden.';
    end if;
    if new.tenant_id is null then
      new.tenant_id := v_tenant;
    elsif new.tenant_id <> v_tenant then
      raise exception 'Der Datensatz gehört zu einer anderen Firma.';
    end if;
  end loop;
  return new;
end
$$;
comment on function _tenant_guard() is 'Übernimmt die Firma vom verknüpften Datensatz und verhindert Verknüpfungen über Firmen hinweg.';

create trigger a0_tenant before insert or update on tours
  for each row execute function _tenant_guard('driver_id:drivers');
create trigger a0_tenant before insert or update on tour_items
  for each row execute function _tenant_guard('tour_id:tours', 'product_id:products');
create trigger a0_tenant before insert or update on expenses
  for each row execute function _tenant_guard('tour_id:tours');
create trigger a0_tenant before insert or update on delivery_notes
  for each row execute function _tenant_guard('tour_id:tours');
create trigger a0_tenant before insert or update on delivery_note_items
  for each row execute function _tenant_guard('delivery_note_id:delivery_notes', 'product_id:products');
create trigger a0_tenant before insert or update on invoices
  for each row execute function _tenant_guard(
    'tour_id:tours', 'delivery_note_id:delivery_notes',
    'cancels_invoice_id:invoices', 'cancelled_by_invoice_id:invoices');
create trigger a0_tenant before insert or update on invoice_items
  for each row execute function _tenant_guard('invoice_id:invoices', 'product_id:products');
create trigger a0_tenant before insert or update on stock_movements
  for each row execute function _tenant_guard('product_id:products');
create trigger a0_tenant before insert or update on product_bundle_items
  for each row execute function _tenant_guard('bundle_id:product_bundles', 'product_id:products');
