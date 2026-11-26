-- Benutzer (nur Chef und Verwaltung). Fahrer haben keinen Login.

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  email text not null,
  role user_role not null default 'office',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create trigger a_audit before insert or update on profiles
  for each row execute function _set_audit_columns();

-- Ist der aktuelle Benutzer angemeldet und aktiv? (auch für RLS-Regeln)
create function is_active_user() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and active)
$$;

create function is_chef() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles where id = auth.uid() and active and role = 'chef'
  )
$$;

grant execute on function is_active_user() to authenticated;
grant execute on function is_chef() to authenticated;

-- Eingangsprüfung jeder App-Funktion.
create function _require_active() returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Bitte melden Sie sich an.';
  end if;
  if not is_active_user() then
    raise exception 'Ihr Konto ist deaktiviert.';
  end if;
end
$$;

create function _require_chef() returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _require_active();
  if not is_chef() then
    raise exception 'Dafür ist die Rolle Chef nötig.';
  end if;
end
$$;

-- Neuer Auth-Benutzer → Profil. Der erste Benutzer wird Chef, alle weiteren Verwaltung.
create function _handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, name, email, role)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'name'), ''), split_part(new.email, '@', 1)),
    coalesce(new.email, ''),
    case when exists (select 1 from profiles) then 'office'::user_role else 'chef'::user_role end
  );
  return new;
end
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function _handle_new_user();

-- Regeln für Profiländerungen: Nur der Chef ändert Rolle/aktiv, es bleibt immer ein aktiver Chef.
create function _guard_profiles() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and auth.uid() is not null and not _is_bypass() then
    if new.id <> old.id or new.email is distinct from old.email then
      raise exception 'Die E-Mail-Adresse kann hier nicht geändert werden.';
    end if;
    if (new.role <> old.role or new.active <> old.active) and not is_chef() then
      raise exception 'Nur der Chef darf Rolle und Aktivstatus ändern.';
    end if;
  end if;

  if old.role = 'chef' and old.active
     and (tg_op = 'DELETE' or new.role <> 'chef' or not new.active) then
    -- Chefs sperren, damit zwei gleichzeitige Änderungen nicht beide durchgehen.
    perform 1 from profiles where role = 'chef' and active for update;
    if not exists (
      select 1 from profiles where role = 'chef' and active and id <> old.id
    ) then
      raise exception 'Es muss mindestens ein aktiver Chef bleiben.';
    end if;
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end
$$;

create trigger b_guard before update or delete on profiles
  for each row execute function _guard_profiles();
