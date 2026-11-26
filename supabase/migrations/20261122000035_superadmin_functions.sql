-- Funktionen des Superadmins: Firmen auflisten, sperren und endgültig löschen.
-- Sie prüfen alle selbst, dass der Aufrufer Superadmin ist. Die eigene Firma des Superadmins
-- lässt sich weder sperren noch löschen.

create function _require_superadmin() returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Bitte melden Sie sich an.';
  end if;
  if not is_superadmin() then
    raise exception 'Das darf nur der Superadmin.';
  end if;
end
$$;
revoke all on function _require_superadmin() from public, anon, authenticated;

-- Alle Firmen mit Chef, Benutzerzahl und Sperre.
create function superadmin_tenants()
returns table (
  id uuid, name text, blocked boolean, user_count integer,
  chef_name text, chef_email text, created_at timestamptz
)
language plpgsql stable security definer set search_path = public as $$
begin
  perform _require_superadmin();
  return query
  select t.id, t.name, t.blocked,
         (select count(*)::int from profiles p where p.tenant_id = t.id),
         c.name, c.email, t.created_at
  from tenants t
  left join lateral (
    select p.name, p.email from profiles p
    where p.tenant_id = t.id and p.role = 'chef'
    order by p.created_at limit 1
  ) c on true
  order by t.created_at;
end
$$;

-- Firma sperren oder wieder freigeben (betrifft Chef und alle Manager der Firma).
create function superadmin_set_blocked(p_tenant uuid, p_blocked boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _require_superadmin();
  if exists (
    select 1 from profiles where tenant_id = p_tenant and id = auth.uid()
  ) then
    raise exception 'Deine eigene Firma kannst du nicht sperren.';
  end if;
  update tenants set blocked = p_blocked where id = p_tenant;
  if not found then
    raise exception 'Firma nicht gefunden.';
  end if;
end
$$;

-- Alle Daten einer Firma endgültig löschen (Datenbank-Teil). Gibt die Benutzer-IDs zurück,
-- damit die Edge Function ihre Konten löscht. NICHT rückgängig zu machen.
create function superadmin_delete_tenant(p_tenant uuid) returns uuid[]
language plpgsql security definer set search_path = public as $$
declare
  v_users uuid[];
  v_previous text;
begin
  perform _require_superadmin();
  if exists (select 1 from profiles where tenant_id = p_tenant and id = auth.uid()) then
    raise exception 'Deine eigene Firma kannst du nicht löschen.';
  end if;
  if not exists (select 1 from tenants where id = p_tenant) then
    raise exception 'Firma nicht gefunden.';
  end if;

  select coalesce(array_agg(id), '{}') into v_users from profiles where tenant_id = p_tenant;

  v_previous := _bypass_on();
  delete from expenses where tenant_id = p_tenant;
  delete from invoices where tenant_id = p_tenant;
  delete from delivery_notes where tenant_id = p_tenant;
  delete from tours where tenant_id = p_tenant;
  delete from product_contents where tenant_id = p_tenant;
  delete from products where tenant_id = p_tenant;
  delete from drivers where tenant_id = p_tenant;
  delete from number_counters where tenant_id = p_tenant;
  delete from change_log where tenant_id = p_tenant;
  delete from company_settings where tenant_id = p_tenant;
  delete from profiles where tenant_id = p_tenant;
  delete from tenants where id = p_tenant;
  perform _bypass_restore(v_previous);
  return v_users;
end
$$;

comment on function superadmin_tenants() is 'Superadmin: alle Firmen mit Chef und Sperre.';
comment on function superadmin_set_blocked(uuid, boolean) is 'Superadmin: Firma sperren oder freigeben.';
comment on function superadmin_delete_tenant(uuid) is 'Superadmin: alle Daten einer Firma endgültig löschen.';

grant execute on function superadmin_tenants() to authenticated;
grant execute on function superadmin_set_blocked(uuid, boolean) to authenticated;
grant execute on function superadmin_delete_tenant(uuid) to authenticated;

-- Beim Löschen einer Firma dürfen auch die letzten Chefs gehen.
create or replace function _guard_profiles() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' and _is_bypass() then
    return old;
  end if;

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

  if old.role = 'chef' and old.active
     and (tg_op = 'DELETE' or (new.tenant_id = old.tenant_id and (new.role <> 'chef' or not new.active))) then
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
