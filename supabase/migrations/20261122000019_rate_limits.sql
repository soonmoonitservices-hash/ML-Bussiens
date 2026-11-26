-- Rate-Limit für teure Schreibfunktionen. Die Zähler liegen pro Benutzer, Aktion
-- und Zeitfenster in einer Tabelle, die nur die Funktion selbst ändern darf.

create table rate_limits (
  user_id uuid not null,
  action text not null,
  window_start timestamptz not null,
  count int not null default 0,
  primary key (user_id, action, window_start)
);
alter table rate_limits enable row level security;
revoke all on rate_limits from authenticated, anon;

comment on table rate_limits is 'Zähler für das Rate-Limit teurer Funktionen (nur über _rate_limit).';

create function _rate_limit(p_action text, p_max int, p_window_seconds int)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_window timestamptz;
  v_count int;
begin
  if v_user is null then
    return; -- interne Aufrufe ohne Benutzer (Wartung, Tests mit Service-Rolle)
  end if;
  v_window := to_timestamp(floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  insert into rate_limits as r (user_id, action, window_start, count)
  values (v_user, p_action, v_window, 1)
  on conflict (user_id, action, window_start) do update set count = r.count + 1
  returning r.count into v_count;
  if v_count > p_max then
    raise exception 'Zu viele Anfragen. Bitte kurz warten.' using errcode = '54000';
  end if;
end
$$;
comment on function _rate_limit(text, int, int) is 'Zählt Aufrufe pro Benutzer und Zeitfenster; über dem Limit Fehler.';
revoke all on function _rate_limit(text, int, int) from public, anon, authenticated;

-- Limit in die bestehenden Funktionen einsetzen (direkt nach dem ersten BEGIN).
do $$
declare
  v_spec record;
  v_def text;
begin
  for v_spec in
    select * from (values
      ('start_tour', 30, 60),
      ('close_tour', 30, 60),
      ('finalize_invoice', 30, 60),
      ('cancel_invoice', 30, 60),
      ('import_products', 5, 3600)
    ) as t(name, max_calls, window_seconds)
  loop
    select pg_get_functiondef(p.oid) into v_def
    from pg_proc p
    where p.pronamespace = 'public'::regnamespace and p.proname = v_spec.name;
    v_def := regexp_replace(
      v_def,
      E'\nbegin\n',
      format(E'\nbegin\n  perform public._rate_limit(%L, %s, %s);\n', v_spec.name, v_spec.max_calls, v_spec.window_seconds)
    );
    if v_def not like '%_rate_limit%' then
      raise exception 'Rate-Limit konnte in % nicht eingesetzt werden', v_spec.name;
    end if;
    execute v_def;
  end loop;
end
$$;

-- Täglich aufräumen.
select cron.schedule('cleanup-rate-limits', '10 1 * * *',
  $$delete from public.rate_limits where window_start < now() - interval '1 day'$$);
