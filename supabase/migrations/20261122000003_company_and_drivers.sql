-- Firmendaten (genau eine Zeile) und Fahrer (nur Liste, kein Login).

create table company_settings (
  id boolean primary key default true check (id),
  name text not null default '',
  address text not null default '',
  phone text not null default '',
  email text not null default '',
  tax_number text not null default '',
  vat_id text not null default '',
  iban text not null default '',
  bic text not null default '',
  bank_name text not null default '',
  managing_director text not null default '',
  logo_path text,
  payment_term_days int not null default 14 check (payment_term_days >= 0),
  invoice_footer text not null default 'Vielen Dank für Ihren Auftrag.',
  -- true: Fahrer kassiert Bruttopreise, das Soll-Bargeld ist dann brutto
  cash_includes_vat boolean not null default false,
  -- Kleinunternehmer (§ 19 UStG): Rechnungen ohne USt, mit Hinweistext
  is_small_business boolean not null default false,
  small_business_note text not null default 'Gemäß § 19 UStG wird keine Umsatzsteuer berechnet.',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

insert into company_settings (id) values (true);

create trigger a_audit before insert or update on company_settings
  for each row execute function _set_audit_columns();

-- Pflicht-Update: Mindestversion der App (genau eine Zeile, Pflege über das Dashboard).
create table app_config (
  id boolean primary key default true check (id),
  min_version_ios text not null default '0.0.0',
  min_version_android text not null default '0.0.0',
  message text not null default 'Bitte aktualisieren Sie die App.',
  ios_store_url text not null default '',
  android_store_url text not null default '',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

insert into app_config (id) values (true);

create trigger a_audit before insert or update on app_config
  for each row execute function _set_audit_columns();

-- Die App prüft die Mindestversion schon vor dem Login, darum ist diese eine Funktion
-- (nicht die Tabelle) auch ohne Anmeldung aufrufbar.
create function get_app_config() returns app_config
language sql stable security definer set search_path = public as $$
  select * from app_config limit 1
$$;

revoke all on function get_app_config() from public;
grant execute on function get_app_config() to anon, authenticated;

create table drivers (
  id uuid primary key default gen_random_uuid(),
  name text not null check (btrim(name) <> ''),
  phone text,
  vehicle text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create trigger a_audit before insert or update on drivers
  for each row execute function _set_audit_columns();
