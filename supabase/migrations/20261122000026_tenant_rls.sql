-- Zugriffsregeln je Firma: Jeder Benutzer sieht und ändert nur Zeilen seiner Firma.
-- Die Regel prüft die Firma des Benutzers einmal je Abfrage ((select current_tenant())).

-- Alle bisherigen Regeln der betroffenen Tabellen entfernen.
do $$
declare
  v_policy record;
begin
  for v_policy in
    select schemaname, tablename, policyname from pg_policies
    where schemaname = 'public'
      and tablename in (
        'drivers', 'products', 'tours', 'tour_items', 'expenses', 'delivery_notes',
        'delivery_note_items', 'invoices', 'invoice_items', 'product_bundles', 'product_bundle_items',
        'stock_movements', 'number_counters', 'change_log', 'company_settings', 'profiles', 'app_config')
  loop
    execute format('drop policy %I on %I.%I', v_policy.policyname, v_policy.schemaname, v_policy.tablename);
  end loop;
end
$$;

-- Normale Tabellen: lesen und schreiben, nur in der eigenen Firma (die Trigger regeln die Sperren).
do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'drivers', 'products', 'tours', 'tour_items', 'expenses', 'delivery_notes',
    'delivery_note_items', 'invoices', 'invoice_items', 'product_bundles', 'product_bundle_items'
  ] loop
    execute format('create policy %I on %I for select to authenticated using (tenant_id = (select current_tenant()))',
      v_table || '_select', v_table);
    execute format('create policy %I on %I for insert to authenticated with check (tenant_id = (select current_tenant()))',
      v_table || '_insert', v_table);
    execute format('create policy %I on %I for update to authenticated using (tenant_id = (select current_tenant())) with check (tenant_id = (select current_tenant()))',
      v_table || '_update', v_table);
    execute format('create policy %I on %I for delete to authenticated using (tenant_id = (select current_tenant()))',
      v_table || '_delete', v_table);
  end loop;
end
$$;

-- Nur lesbar (schreiben tun Funktionen und Trigger).
create policy stock_movements_select on stock_movements for select to authenticated
  using (tenant_id = (select current_tenant()));
create policy number_counters_select on number_counters for select to authenticated
  using (tenant_id = (select current_tenant()));
create policy change_log_select on change_log for select to authenticated
  using (tenant_id = (select current_tenant()));

-- Firmendaten: lesen alle der Firma, ändern nur der Chef.
create policy company_settings_select on company_settings for select to authenticated
  using (tenant_id = (select current_tenant()));
create policy company_settings_update on company_settings for update to authenticated
  using (tenant_id = (select current_tenant()) and (select is_chef()))
  with check (tenant_id = (select current_tenant()) and (select is_chef()));

-- Benutzer: nur die der eigenen Firma; ändern der Chef oder man selbst.
create policy profiles_select on profiles for select to authenticated
  using (tenant_id = (select current_tenant()));
create policy profiles_update on profiles for update to authenticated
  using (tenant_id = (select current_tenant()) and ((select is_chef()) or id = (select auth.uid())))
  with check (tenant_id = (select current_tenant()) and ((select is_chef()) or id = (select auth.uid())));

-- App-Konfiguration (Pflicht-Update) gilt für alle Firmen: lesen ja, ändern nur der Betreiber im Dashboard.
create policy app_config_select on app_config for select to authenticated
  using ((select current_tenant()) is not null);

-- Firmen: jeder sieht nur seine eigene.
alter table tenants enable row level security;
create policy tenants_select on tenants for select to authenticated
  using (id = (select current_tenant()));
revoke all on tenants from authenticated, anon;
grant select on tenants to authenticated;

-- Dateien: jeder Pfad beginnt mit der Firmen-Kennung (z. B. <firma>/2026-11/beleg.jpg).
-- Übergang: Pfade ohne Firmen-Kennung (so wurden Dateien vor den Firmen abgelegt) gehören zur
-- Firma „Standard“. So bleiben bestehende Fotos erreichbar und ältere App-Versionen laufen weiter.
drop policy app_files_all on storage.objects;
create policy app_files_all on storage.objects for all to authenticated
  using (
    bucket_id in ('receipts', 'signatures', 'documents', 'logos', 'products')
    and (
      (storage.foldername(name))[1] = (select current_tenant()::text)
      or (
        (select current_tenant()) = 'a0000000-0000-4000-8000-000000000001'
        and coalesce((storage.foldername(name))[1], '') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-'
      )
    )
  )
  with check (
    bucket_id in ('receipts', 'signatures', 'documents', 'logos', 'products')
    and (
      (storage.foldername(name))[1] = (select current_tenant()::text)
      or (
        (select current_tenant()) = 'a0000000-0000-4000-8000-000000000001'
        and coalesce((storage.foldername(name))[1], '') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-'
      )
    )
  );
