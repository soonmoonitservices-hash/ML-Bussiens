-- Zugriffsregeln (RLS) und Storage. Grundsatz: nur angemeldete, aktive Benutzer.
-- Die eigentlichen Geschäftsregeln und Sperren stehen in den Triggern und Funktionen.

alter table profiles enable row level security;
alter table company_settings enable row level security;
alter table app_config enable row level security;
alter table drivers enable row level security;
alter table products enable row level security;
alter table stock_movements enable row level security;
alter table number_counters enable row level security;
alter table tours enable row level security;
alter table tour_items enable row level security;
alter table expenses enable row level security;
alter table delivery_notes enable row level security;
alter table delivery_note_items enable row level security;
alter table invoices enable row level security;
alter table invoice_items enable row level security;

-- Nur lesen für aktive Benutzer (geschrieben wird ausschließlich über Funktionen).
create policy profiles_select on profiles for select to authenticated using (is_active_user());
create policy company_settings_select on company_settings for select to authenticated using (is_active_user());
create policy app_config_select on app_config for select to authenticated using (is_active_user());
create policy stock_movements_select on stock_movements for select to authenticated using (is_active_user());
create policy number_counters_select on number_counters for select to authenticated using (is_active_user());

-- profiles: Chef ändert alles, jeder seinen eigenen Namen (der Trigger sperrt Rolle/aktiv für Nicht-Chefs).
create policy profiles_update on profiles for update to authenticated
  using (is_active_user() and (is_chef() or id = auth.uid()))
  with check (is_active_user() and (is_chef() or id = auth.uid()));

-- Firmendaten und App-Konfiguration: nur der Chef ändert.
create policy company_settings_update on company_settings for update to authenticated
  using (is_chef()) with check (is_chef());
create policy app_config_update on app_config for update to authenticated
  using (is_chef()) with check (is_chef());

-- Normale Tabellen: aktive Benutzer lesen und schreiben (Sperren regeln die Trigger).
do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'drivers', 'products', 'tours', 'tour_items', 'expenses',
    'delivery_notes', 'delivery_note_items', 'invoices', 'invoice_items'
  ] loop
    execute format('create policy %I on %I for select to authenticated using (is_active_user())',
      v_table || '_select', v_table);
    execute format('create policy %I on %I for insert to authenticated with check (is_active_user())',
      v_table || '_insert', v_table);
    execute format('create policy %I on %I for update to authenticated using (is_active_user()) with check (is_active_user())',
      v_table || '_update', v_table);
    execute format('create policy %I on %I for delete to authenticated using (is_active_user())',
      v_table || '_delete', v_table);
  end loop;
end
$$;

-- Storage: private Buckets, eine Policy: nur angemeldete, aktive Benutzer.
-- Dateityp und Größe prüft nur die App (Bilder vor dem Upload verkleinern, max. 10 MB).
insert into storage.buckets (id, name, public) values
  ('receipts', 'receipts', false),
  ('signatures', 'signatures', false),
  ('documents', 'documents', false),
  ('logos', 'logos', false),
  ('products', 'products', false)
on conflict (id) do nothing;

create policy app_files_all on storage.objects for all to authenticated
  using (
    bucket_id in ('receipts', 'signatures', 'documents', 'logos', 'products') and public.is_active_user()
  )
  with check (
    bucket_id in ('receipts', 'signatures', 'documents', 'logos', 'products') and public.is_active_user()
  );
