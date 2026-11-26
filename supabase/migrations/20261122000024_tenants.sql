-- Mehrere Firmen in einer Datenbank. Jede Firma („Mandant“) sieht nur ihre eigenen Daten.
-- Diese Migration legt die Firmen-Tabelle an und ordnet jedem Benutzer eine Firma zu.
-- Die Trennung der Daten folgt in den nächsten Migrationen (25 bis 27).

create table tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (btrim(name) <> ''),
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create trigger a_audit before insert or update on tenants
  for each row execute function _set_audit_columns();

comment on table tenants is 'Firma (Mandant). Jede Firma sieht nur ihre eigenen Daten.';

-- Die erste Firma: nimmt vorhandene Daten auf und den ersten Benutzer, der sich ohne Firma anmeldet.
insert into tenants (id, name) values ('a0000000-0000-4000-8000-000000000001', 'Standard');

alter table profiles add column tenant_id uuid references tenants (id) on delete restrict;
update profiles set tenant_id = 'a0000000-0000-4000-8000-000000000001';
alter table profiles alter column tenant_id set not null;
create index profiles_tenant_idx on profiles (tenant_id);
comment on column profiles.tenant_id is 'Firma des Benutzers. Nur der Betreiber ändert sie (Dashboard).';

-- Firma des angemeldeten, aktiven Benutzers (null ohne Anmeldung).
create function current_tenant() returns uuid
language sql stable security definer set search_path = public as $$
  select tenant_id from profiles where id = auth.uid() and active
$$;
comment on function current_tenant() is 'Firma des angemeldeten, aktiven Benutzers.';
grant execute on function current_tenant() to authenticated;

-- Neuer Auth-Benutzer → Profil in einer Firma:
--   1. mit raw_user_meta_data.tenant_id: in diese Firma,
--   2. sonst in die Firma „Standard“, solange dort noch niemand ist,
--   3. sonst in eine neue Firma (Name aus raw_user_meta_data.company oder der E-Mail).
-- Der erste Benutzer einer Firma wird Chef, alle weiteren Verwaltung.
create or replace function _handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_tenant uuid;
  v_meta text := nullif(btrim(new.raw_user_meta_data ->> 'tenant_id'), '');
begin
  if v_meta is not null then
    select id into v_tenant from tenants where id = v_meta::uuid;
    if v_tenant is null then
      raise exception 'Firma nicht gefunden.';
    end if;
  elsif not exists (select 1 from profiles where tenant_id = 'a0000000-0000-4000-8000-000000000001') then
    v_tenant := 'a0000000-0000-4000-8000-000000000001';
  else
    insert into tenants (name)
    values (coalesce(nullif(btrim(new.raw_user_meta_data ->> 'company'), ''), split_part(new.email, '@', 1)))
    returning id into v_tenant;
  end if;

  insert into profiles (id, name, email, role, tenant_id)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'name'), ''), split_part(new.email, '@', 1)),
    coalesce(new.email, ''),
    case when exists (select 1 from profiles where tenant_id = v_tenant and role = 'chef' and active)
      then 'office'::user_role else 'chef'::user_role end,
    v_tenant
  );
  return new;
end
$$;

-- Profil-Regeln: Die Firma ändert die App nie; „mindestens ein aktiver Chef“ gilt je Firma.
create or replace function _guard_profiles() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and auth.uid() is not null and not _is_bypass() then
    if new.id <> old.id or new.email is distinct from old.email then
      raise exception 'Die E-Mail-Adresse kann hier nicht geändert werden.';
    end if;
    if new.tenant_id <> old.tenant_id then
      raise exception 'Die Firma eines Benutzers kann hier nicht geändert werden.';
    end if;
    if (new.role <> old.role or new.active <> old.active) and not is_chef() then
      raise exception 'Nur der Chef darf Rolle und Aktivstatus ändern.';
    end if;
  end if;

  -- (Zieht ein Chef in eine andere Firma um, was nur der Betreiber im Dashboard tut, gilt die
  -- Regel für die alte Firma nicht mehr: sie wird dabei aufgelöst.)
  if old.role = 'chef' and old.active
     and (tg_op = 'DELETE' or (new.tenant_id = old.tenant_id and (new.role <> 'chef' or not new.active))) then
    -- Chefs der Firma sperren, damit zwei gleichzeitige Änderungen nicht beide durchgehen.
    perform 1 from profiles where role = 'chef' and active and tenant_id = old.tenant_id for update;
    if not exists (
      select 1 from profiles
      where role = 'chef' and active and tenant_id = old.tenant_id and id <> old.id
    ) then
      raise exception 'Es muss mindestens ein aktiver Chef bleiben.';
    end if;
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end
$$;
