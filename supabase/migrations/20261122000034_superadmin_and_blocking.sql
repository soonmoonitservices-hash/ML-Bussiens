-- Superadmin: genau ein Konto (rasho.juan95@gmail.com) darf Firmen und ihre Chefs verwalten.
-- Hier: wer Superadmin ist, und das Sperren einer ganzen Firma. Ist eine Firma gesperrt,
-- sehen und ändern ihre Benutzer (Chef und Manager) nichts mehr.

create table platform_admins (
  email text primary key check (email = lower(email))
);
alter table platform_admins enable row level security;
revoke all on platform_admins from authenticated, anon;
comment on table platform_admins is 'Superadmins der Plattform (E-Mail, klein geschrieben). Nur der Betreiber ändert sie.';

insert into platform_admins (email) values ('rasho.juan95@gmail.com');

create function is_superadmin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from platform_admins a
    join auth.users u on lower(u.email) = a.email
    where u.id = auth.uid()
  )
$$;
comment on function is_superadmin() is 'Ist der angemeldete Benutzer einer der Superadmins?';
grant execute on function is_superadmin() to authenticated;

alter table tenants add column blocked boolean not null default false;
comment on column tenants.blocked is 'Gesperrte Firma: ihre Benutzer sehen und ändern nichts mehr.';

-- Gesperrte Firmen: kein Zugriff mehr (alle Regeln und Funktionen prüfen current_tenant()
-- bzw. is_active_user()).
create or replace function current_tenant() returns uuid
language sql stable security definer set search_path = public as $$
  select p.tenant_id
  from profiles p
  join tenants t on t.id = p.tenant_id
  where p.id = auth.uid() and p.active and not t.blocked
$$;

create or replace function is_active_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from profiles p
    join tenants t on t.id = p.tenant_id
    where p.id = auth.uid() and p.active and not t.blocked
  )
$$;

-- Neuer Benutzer mit „new_tenant“ bekommt immer eine eigene, neue Firma (so legt der
-- Superadmin neue Chefs an).
create or replace function _handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_tenant uuid;
  v_meta text := nullif(btrim(new.raw_user_meta_data ->> 'tenant_id'), '');
  v_new boolean := coalesce((new.raw_user_meta_data ->> 'new_tenant')::boolean, false);
begin
  if v_meta is not null then
    select id into v_tenant from tenants where id = v_meta::uuid;
    if v_tenant is null then
      raise exception 'Firma nicht gefunden.';
    end if;
  elsif not v_new and not exists (select 1 from profiles where tenant_id = 'a0000000-0000-4000-8000-000000000001') then
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
