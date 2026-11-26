-- Winzige Abfrage für den App-Cache: letzter Änderungszeitpunkt je Stammdaten-Tabelle.

create function data_versions()
returns table (table_name text, last_updated timestamptz)
language sql stable set search_path = public as $$
  select 'products'::text, max(updated_at) from products
  union all select 'drivers', max(updated_at) from drivers
  union all select 'company_settings', max(updated_at) from company_settings
$$;
comment on function data_versions() is 'Letzte Änderung je Stammdaten-Tabelle, damit die App nur bei Änderung neu lädt.';

grant execute on function data_versions() to authenticated;
