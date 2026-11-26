-- Das übergebene Bargeld geht in den Gewinn ein: Gewinn = Umsatz − Wareneinsatz − Ausgaben
-- + Differenz (übergebenes Bargeld − Soll-Bargeld). Ein Mehr- oder Wenigerbetrag zählt also
-- direkt zum Gewinn und ist kein eigener „Überschuss“ mehr.

do $$
declare
  v_def text;
  v_previous text;
begin
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = 'close_tour';
  v_def := replace(
    v_def,
    'profit_cents = v_revenue_net - v_cost - v_expenses_net',
    'profit_cents = v_revenue_net - v_cost - v_expenses_net + v_difference'
  );
  if v_def not like '%v_expenses_net + v_difference%' then
    raise exception 'close_tour konnte nicht angepasst werden';
  end if;
  execute v_def;

  -- Bereits abgeschlossene Touren nachziehen.
  v_previous := _bypass_on();
  update tours set profit_cents = profit_cents + difference_cents
  where status = 'closed' and difference_cents is not null and difference_cents <> 0;
  perform _bypass_restore(v_previous);
end
$$;
