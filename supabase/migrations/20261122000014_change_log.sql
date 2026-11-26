-- Änderungsverlauf für Touren und Rechnungen (wer hat wann was geändert).
-- Gespeichert werden nur die geänderten Felder (alt/neu), damit der Free-Plan-Speicher klein bleibt.

create table change_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  record_id uuid not null,
  action text not null check (action in ('insert', 'update', 'delete')),
  changed_by uuid,
  changed_at timestamptz not null default now(),
  old_data jsonb,
  new_data jsonb
);

create index change_log_record_idx on change_log (table_name, record_id, changed_at);

alter table change_log enable row level security;
create policy change_log_select on change_log for select to authenticated using (is_active_user());
revoke insert, update, delete on change_log from authenticated;
revoke all on change_log from anon;

create function _log_change() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb;
  v_new jsonb;
  v_ignored text[] := array['updated_at', 'updated_by'];
begin
  if tg_op = 'INSERT' then
    insert into change_log (table_name, record_id, action, changed_by, new_data)
    values (tg_table_name, new.id, 'insert', auth.uid(), to_jsonb(new));
    return null;
  end if;

  if tg_op = 'DELETE' then
    insert into change_log (table_name, record_id, action, changed_by, old_data)
    values (tg_table_name, old.id, 'delete', auth.uid(), to_jsonb(old));
    return null;
  end if;

  -- nur die Felder, die sich wirklich geändert haben
  select jsonb_object_agg(o.key, o.value), jsonb_object_agg(o.key, n.value)
  into v_old, v_new
  from jsonb_each(to_jsonb(old) - v_ignored) o
  join jsonb_each(to_jsonb(new) - v_ignored) n using (key)
  where o.value is distinct from n.value;

  if v_old is not null then
    insert into change_log (table_name, record_id, action, changed_by, old_data, new_data)
    values (tg_table_name, new.id, 'update', auth.uid(), v_old, v_new);
  end if;
  return null;
end
$$;

create trigger z_log_change after insert or update or delete on tours
  for each row execute function _log_change();
create trigger z_log_change after insert or update or delete on invoices
  for each row execute function _log_change();
