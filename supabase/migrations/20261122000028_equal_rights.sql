-- Gleiche Rechte für Chef und Verwaltung: Wer in einer Firma angemeldet und aktiv ist, darf alles,
-- was bisher dem Chef vorbehalten war (Firmendaten ändern, Benutzer verwalten, Touren und Rechnungen
-- wieder öffnen bzw. stornieren). Die Rolle bleibt als Bezeichnung erhalten, und es muss weiter
-- mindestens ein aktiver Chef je Firma bleiben. Der Funktionsname is_chef() bleibt, damit alle
-- Zugriffsregeln und Funktionen unverändert weiterlaufen.

create or replace function is_chef() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and active)
$$;
comment on function is_chef() is 'Darf verwalten: jeder aktive Benutzer (Chef und Verwaltung haben gleiche Rechte).';
