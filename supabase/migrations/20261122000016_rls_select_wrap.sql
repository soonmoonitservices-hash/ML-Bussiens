-- RLS schneller: Hilfsfunktionen in (select ...) einpacken, damit sie nur einmal pro
-- Abfrage ausgewertet werden und nicht pro Zeile. Gleiche Regeln wie vorher.

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'drivers', 'products', 'tours', 'tour_items', 'expenses',
    'delivery_notes', 'delivery_note_items', 'invoices', 'invoice_items'
  ] loop
    execute format('drop policy %I on %I', v_table || '_select', v_table);
    execute format('drop policy %I on %I', v_table || '_insert', v_table);
    execute format('drop policy %I on %I', v_table || '_update', v_table);
    execute format('drop policy %I on %I', v_table || '_delete', v_table);
    execute format('create policy %I on %I for select to authenticated using ((select is_active_user()))',
      v_table || '_select', v_table);
    execute format('create policy %I on %I for insert to authenticated with check ((select is_active_user()))',
      v_table || '_insert', v_table);
    execute format('create policy %I on %I for update to authenticated using ((select is_active_user())) with check ((select is_active_user()))',
      v_table || '_update', v_table);
    execute format('create policy %I on %I for delete to authenticated using ((select is_active_user()))',
      v_table || '_delete', v_table);
  end loop;
end
$$;

drop policy profiles_select on profiles;
create policy profiles_select on profiles for select to authenticated using ((select is_active_user()));
drop policy company_settings_select on company_settings;
create policy company_settings_select on company_settings for select to authenticated using ((select is_active_user()));
drop policy app_config_select on app_config;
create policy app_config_select on app_config for select to authenticated using ((select is_active_user()));
drop policy stock_movements_select on stock_movements;
create policy stock_movements_select on stock_movements for select to authenticated using ((select is_active_user()));
drop policy number_counters_select on number_counters;
create policy number_counters_select on number_counters for select to authenticated using ((select is_active_user()));

drop policy profiles_update on profiles;
create policy profiles_update on profiles for update to authenticated
  using ((select is_active_user()) and ((select is_chef()) or id = (select auth.uid())))
  with check ((select is_active_user()) and ((select is_chef()) or id = (select auth.uid())));

drop policy company_settings_update on company_settings;
create policy company_settings_update on company_settings for update to authenticated
  using ((select is_chef())) with check ((select is_chef()));
drop policy app_config_update on app_config;
create policy app_config_update on app_config for update to authenticated
  using ((select is_chef())) with check ((select is_chef()));

drop policy app_files_all on storage.objects;
create policy app_files_all on storage.objects for all to authenticated
  using (
    bucket_id in ('receipts', 'signatures', 'documents', 'logos', 'products') and (select public.is_active_user())
  )
  with check (
    bucket_id in ('receipts', 'signatures', 'documents', 'logos', 'products') and (select public.is_active_user())
  );
