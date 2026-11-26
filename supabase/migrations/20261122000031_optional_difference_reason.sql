-- Beim Abschließen einer Tour ist die Begründung für eine Kassendifferenz freiwillig.
-- Vorher war sie bei jeder Differenz Pflicht (Fehler „Die Kasse stimmt nicht …“).

do $$
declare
  v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'close_tour';
  v_def := regexp_replace(
    v_def,
    'if v_difference <> 0 and \(p_difference_reason is null or btrim\(p_difference_reason\) = ''''\) then\s+raise exception[^;]*;\s+end if;',
    '',
    'g'
  );
  if v_def like '%Die Kasse stimmt nicht%' then
    raise exception 'close_tour konnte nicht angepasst werden';
  end if;
  execute v_def;
end
$$;
