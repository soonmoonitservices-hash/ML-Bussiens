-- Alles darf gelöscht werden: Touren (auch abgeschlossene), Lieferscheine (auch unterschriebene)
-- und Rechnungen (auch festgeschriebene). Das war bisher gesperrt. Der Betreiber hat es so
-- entschieden und trägt das Risiko: festgeschriebene Rechnungen müssen in Deutschland aufbewahrt
-- werden, gelöschte Rechnungsnummern hinterlassen Lücken. Die App warnt vor dem Löschen.
--
-- Gelöscht wird über diese Funktionen (nicht direkt per DELETE), damit die Sperren für die
-- Dauer des Löschens ruhen. Verweise anderer Datensätze auf das Gelöschte werden gelöst.

alter table delivery_notes drop constraint delivery_notes_tour_id_fkey;
alter table delivery_notes add constraint delivery_notes_tour_id_fkey
  foreign key (tour_id) references tours (id) on delete set null;

alter table invoices drop constraint invoices_tour_id_fkey;
alter table invoices add constraint invoices_tour_id_fkey
  foreign key (tour_id) references tours (id) on delete set null;
alter table invoices drop constraint invoices_delivery_note_id_fkey;
alter table invoices add constraint invoices_delivery_note_id_fkey
  foreign key (delivery_note_id) references delivery_notes (id) on delete set null;
alter table invoices drop constraint invoices_cancels_invoice_id_fkey;
alter table invoices add constraint invoices_cancels_invoice_id_fkey
  foreign key (cancels_invoice_id) references invoices (id) on delete set null;
alter table invoices drop constraint invoices_cancelled_by_invoice_id_fkey;
alter table invoices add constraint invoices_cancelled_by_invoice_id_fkey
  foreign key (cancelled_by_invoice_id) references invoices (id) on delete set null;

-- Tour löschen: mit Positionen und ihren Ausgaben.
create function delete_tour(p_tour_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_previous text;
begin
  perform _require_active();
  perform _require_row_in_tenant('tours', p_tour_id);
  v_previous := _bypass_on();
  delete from expenses where tour_id = p_tour_id;
  delete from tours where id = p_tour_id;
  perform _bypass_restore(v_previous);
end
$$;

-- Lieferschein löschen (auch unterschrieben).
create function delete_delivery_note(p_delivery_note_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_previous text;
begin
  perform _require_active();
  perform _require_row_in_tenant('delivery_notes', p_delivery_note_id);
  v_previous := _bypass_on();
  delete from delivery_notes where id = p_delivery_note_id;
  perform _bypass_restore(v_previous);
end
$$;

-- Rechnung löschen (auch festgeschrieben oder storniert).
create function delete_invoice(p_invoice_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_previous text;
begin
  perform _require_active();
  perform _require_row_in_tenant('invoices', p_invoice_id);
  v_previous := _bypass_on();
  delete from invoices where id = p_invoice_id;
  perform _bypass_restore(v_previous);
end
$$;

comment on function delete_tour(uuid) is 'Löscht eine Tour (auch abgeschlossen) mit Positionen und Tour-Ausgaben.';
comment on function delete_delivery_note(uuid) is 'Löscht einen Lieferschein (auch unterschrieben).';
comment on function delete_invoice(uuid) is 'Löscht eine Rechnung (auch festgeschrieben). Rechtlich riskant, die App warnt davor.';

grant execute on function delete_tour(uuid), delete_delivery_note(uuid), delete_invoice(uuid) to authenticated;
