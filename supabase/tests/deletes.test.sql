-- Test: Alles darf gelöscht werden (Tour, Lieferschein, Rechnung), aber nur in der eigenen Firma.
-- Läuft nach _helpers.sql und endet mit ROLLBACK.

do $$
declare
  v_chef uuid := 'c0000000-0000-4000-8000-000000000001';
  v_olives uuid := (select id from products where name = 'Grüne Oliven');
  v_tour uuid;
  v_invoice uuid;
  v_note uuid;
  v_other_tenant uuid := 'b0000000-0000-4000-8000-000000000002';
  v_other_user uuid := 'c0000000-0000-4000-8000-0000000000b2';
begin
  insert into tenants (id, name) values (v_other_tenant, 'Firma B');
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values (v_other_user, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'chef-b@test.de', '', now(), '{}', format('{"tenant_id":"%s"}', v_other_tenant)::jsonb, now(), now());

  perform _t_login(v_chef);

  -- Abgeschlossene Tour mit Ausgabe
  insert into tours (driver_id) values ((select id from drivers where name = 'Ahmad Khalil'))
  returning id into v_tour;
  insert into tour_items (tour_id, product_id, loaded_qty) values (v_tour, v_olives, 10);
  perform start_tour(v_tour);
  insert into expenses (title, category, gross_cents, tour_id) values ('Diesel', 'Fahrzeug', 1000, v_tour);
  perform close_tour(v_tour, format('[{"product_id":"%s","returned_qty":0}]', v_olives)::jsonb, 3500, null);
  assert (select status from tours where id = v_tour) = 'closed', 'Tour ist abgeschlossen';

  -- Direkt löschen bleibt gesperrt, über die Funktion geht es
  perform _t_fails(format('delete from tours where id = %L', v_tour), 'Nur Entwürfe können gelöscht werden.');

  -- Eine andere Firma darf nichts löschen
  perform _t_login(v_other_user);
  perform _t_fails(format('select delete_tour(%L)', v_tour), 'Datensatz nicht gefunden.');
  perform _t_login(v_chef);
  assert exists (select 1 from tours where id = v_tour), 'Tour ist noch da';

  perform delete_tour(v_tour);
  assert not exists (select 1 from tours where id = v_tour), 'Abgeschlossene Tour gelöscht';
  assert not exists (select 1 from tour_items where tour_id = v_tour), 'Positionen gelöscht';
  assert not exists (select 1 from expenses where title = 'Diesel'), 'Tour-Ausgaben gelöscht';

  -- Festgeschriebene Rechnung
  insert into invoices (recipient_name, recipient_address) values ('Kunde', 'Straße 1, 10115 Berlin')
  returning id into v_invoice;
  insert into invoice_items (invoice_id, product_id, qty) values (v_invoice, v_olives, 2);
  perform finalize_invoice(v_invoice);
  assert (select status from invoices where id = v_invoice) <> 'draft', 'Rechnung ist festgeschrieben';
  perform _t_fails(format('delete from invoices where id = %L', v_invoice), 'Nur Entwürfe können gelöscht werden.%');
  perform _t_login(v_other_user);
  perform _t_fails(format('select delete_invoice(%L)', v_invoice), 'Datensatz nicht gefunden.');
  perform _t_login(v_chef);
  perform delete_invoice(v_invoice);
  assert not exists (select 1 from invoices where id = v_invoice), 'Festgeschriebene Rechnung gelöscht';
  assert not exists (select 1 from invoice_items where invoice_id = v_invoice), 'Positionen gelöscht';

  -- Lieferschein
  insert into delivery_notes (recipient_name, recipient_address) values ('Kunde', 'Straße 1, 10115 Berlin')
  returning id into v_note;
  insert into delivery_note_items (delivery_note_id, product_id, qty) values (v_note, v_olives, 3);
  perform delete_delivery_note(v_note);
  assert not exists (select 1 from delivery_notes where id = v_note), 'Lieferschein gelöscht';

  perform _t_logout();
end $$;

select 'deletes: BESTANDEN' as ergebnis;
rollback;
