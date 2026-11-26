-- Rechnungs-Ablauf: festschreiben, stornieren, bezahlt markieren, aus Lieferschein erstellen, überfällig setzen.

-- Kleinbetragsrechnung: bis 250 € brutto (weniger Pflichtangaben, keine E-Rechnungspflicht).
create function _small_invoice_limit_cents() returns bigint
language sql immutable set search_path = public as $$
  select 25000::bigint
$$;

-- Prüft vor dem Festschreiben, ob die Firmendaten für eine Rechnung vollständig sind (§ 14 UStG).
create function _require_company_data_for_invoice() returns void
language plpgsql security definer set search_path = public as $$
declare
  v_company company_settings;
  v_missing text[] := array[]::text[];
begin
  select * into v_company from company_settings;
  if btrim(v_company.name) = '' then
    v_missing := array_append(v_missing, 'Firmenname');
  end if;
  if btrim(v_company.address) = '' then
    v_missing := array_append(v_missing, 'Adresse');
  end if;
  if btrim(v_company.tax_number) = '' and btrim(v_company.vat_id) = '' then
    v_missing := array_append(v_missing, 'Steuernummer oder USt-IdNr.');
  end if;
  if array_length(v_missing, 1) > 0 then
    raise exception 'Bitte zuerst in den Firmendaten ergänzen: %.', array_to_string(v_missing, ', ');
  end if;
end
$$;

-- Rechnung festschreiben: Nummer, Fälligkeit, Summen; ohne Tour wird die Ware abgebucht.
-- Gibt die Rechnungsnummer zurück.
create function finalize_invoice(p_invoice_id uuid) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_invoice invoices;
  v_company company_settings;
  v_item record;
  v_previous text;
  v_has_products boolean;
  v_number text;
begin
  perform _require_active();
  select * into v_invoice from invoices where id = p_invoice_id for update;
  if not found then
    raise exception 'Rechnung nicht gefunden.';
  end if;
  if v_invoice.status <> 'draft' then
    raise exception 'Nur Entwürfe können festgeschrieben werden.';
  end if;
  if btrim(v_invoice.recipient_name) = '' or btrim(v_invoice.recipient_address) = '' then
    raise exception 'Bitte Name und Adresse des Empfängers eintragen.';
  end if;
  if not exists (select 1 from invoice_items where invoice_id = p_invoice_id) then
    raise exception 'Bitte mindestens eine Position hinzufügen.';
  end if;
  perform _require_company_data_for_invoice();
  select * into v_company from company_settings;

  v_previous := _bypass_on();
  perform _recalc_invoice(p_invoice_id);
  select * into v_invoice from invoices where id = p_invoice_id;

  v_has_products := exists (
    select 1 from invoice_items where invoice_id = p_invoice_id and product_id is not null
  );
  if v_invoice.tour_id is null then
    for v_item in
      select product_id, sum(qty)::bigint as qty from invoice_items
      where invoice_id = p_invoice_id and product_id is not null
      group by product_id order by product_id
    loop
      perform _move_stock(v_item.product_id, -v_item.qty, 'invoice', null, 'invoices', p_invoice_id);
    end loop;
  end if;

  v_number := next_number('invoice');
  update invoices
  set number = v_number,
      status = 'open',
      due_date = coalesce(due_date, date + v_company.payment_term_days),
      finalized_at = now(),
      finalized_by = auth.uid(),
      stock_booked = (tour_id is null and v_has_products),
      is_small_business = v_company.is_small_business,
      is_small_amount = (gross_cents <= _small_invoice_limit_cents())
  where id = p_invoice_id;

  perform _bypass_restore(v_previous);
  return v_number;
end
$$;

-- Nur Chef: erzeugt eine Stornorechnung mit negativen Werten und bucht die Ware zurück.
-- Beide Rechnungen stehen danach auf „storniert“. Gibt die ID der Stornorechnung zurück.
create function cancel_invoice(p_invoice_id uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_invoice invoices;
  v_storno_id uuid := gen_random_uuid();
  v_item record;
  v_previous text;
begin
  perform _require_chef();
  select * into v_invoice from invoices where id = p_invoice_id for update;
  if not found then
    raise exception 'Rechnung nicht gefunden.';
  end if;
  if v_invoice.status = 'draft' then
    raise exception 'Entwürfe werden gelöscht, nicht storniert.';
  end if;
  if v_invoice.cancels_invoice_id is not null then
    raise exception 'Eine Stornorechnung kann nicht storniert werden.';
  end if;
  if v_invoice.status = 'cancelled' then
    raise exception 'Diese Rechnung ist bereits storniert.';
  end if;

  v_previous := _bypass_on();

  insert into invoices (
    id, number, date, service_date, due_date, recipient_name, recipient_address,
    recipient_vat_id, buyer_reference, note, status, finalized_at, finalized_by,
    cancels_invoice_id, tour_id, delivery_note_id, stock_booked,
    is_small_business, is_small_amount
  ) values (
    v_storno_id, next_number('invoice'), berlin_today(), v_invoice.service_date, berlin_today(),
    v_invoice.recipient_name, v_invoice.recipient_address,
    v_invoice.recipient_vat_id, v_invoice.buyer_reference,
    'Storno zu ' || v_invoice.number, 'cancelled', now(), auth.uid(),
    p_invoice_id, v_invoice.tour_id, v_invoice.delivery_note_id, false,
    v_invoice.is_small_business, v_invoice.is_small_amount
  );

  insert into invoice_items (
    invoice_id, product_id, product_name, unit, vat_rate, buy_price_cents,
    qty, price_net_cents, position
  )
  select v_storno_id, product_id, product_name, unit, vat_rate, buy_price_cents,
         -qty, price_net_cents, position
  from invoice_items where invoice_id = p_invoice_id;

  -- Summen exakt gegengleich zum Original (unabhängig von späteren Einstellungen).
  update invoices
  set net_cents = -v_invoice.net_cents,
      vat7_cents = -v_invoice.vat7_cents,
      vat19_cents = -v_invoice.vat19_cents,
      gross_cents = -v_invoice.gross_cents,
      cost_cents = -v_invoice.cost_cents
  where id = v_storno_id;

  if v_invoice.stock_booked then
    for v_item in
      select product_id, sum(qty)::bigint as qty from invoice_items
      where invoice_id = p_invoice_id and product_id is not null
      group by product_id order by product_id
    loop
      perform _move_stock(v_item.product_id, v_item.qty, 'invoice_cancel', null, 'invoices', v_storno_id);
    end loop;
  end if;

  update invoices
  set status = 'cancelled', cancelled_by_invoice_id = v_storno_id
  where id = p_invoice_id;

  perform _bypass_restore(v_previous);
  return v_storno_id;
end
$$;

create function mark_invoice_paid(p_invoice_id uuid, p_paid_at date default null) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_invoice invoices;
  v_paid_at date := coalesce(p_paid_at, berlin_today());
  v_previous text;
begin
  perform _require_active();
  select * into v_invoice from invoices where id = p_invoice_id for update;
  if not found then
    raise exception 'Rechnung nicht gefunden.';
  end if;
  if v_invoice.status not in ('open', 'overdue') then
    raise exception 'Nur offene Rechnungen können als bezahlt markiert werden.';
  end if;
  if v_paid_at > berlin_today() then
    raise exception 'Das Zahlungsdatum darf nicht in der Zukunft liegen.';
  end if;

  v_previous := _bypass_on();
  update invoices set status = 'paid', paid_at = v_paid_at where id = p_invoice_id;
  perform _bypass_restore(v_previous);
end
$$;

create function mark_invoice_unpaid(p_invoice_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_invoice invoices;
  v_previous text;
begin
  perform _require_active();
  select * into v_invoice from invoices where id = p_invoice_id for update;
  if not found then
    raise exception 'Rechnung nicht gefunden.';
  end if;
  if v_invoice.status <> 'paid' then
    raise exception 'Nur bezahlte Rechnungen können wieder auf offen gesetzt werden.';
  end if;

  v_previous := _bypass_on();
  update invoices
  set status = case when due_date < berlin_today() then 'overdue'::invoice_status else 'open'::invoice_status end,
      paid_at = null
  where id = p_invoice_id;
  perform _bypass_restore(v_previous);
end
$$;

-- Neue Entwurfsrechnung mit Empfänger und Positionen aus einem Lieferschein.
create function invoice_from_delivery_note(p_delivery_note_id uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_note delivery_notes;
  v_invoice_id uuid;
begin
  perform _require_active();
  select * into v_note from delivery_notes where id = p_delivery_note_id;
  if not found then
    raise exception 'Lieferschein nicht gefunden.';
  end if;
  if exists (
    select 1 from invoices
    where delivery_note_id = p_delivery_note_id
      and cancels_invoice_id is null
      and status <> 'cancelled'
  ) then
    raise exception 'Für diesen Lieferschein gibt es bereits eine Rechnung.';
  end if;

  insert into invoices (recipient_name, recipient_address, delivery_note_id, tour_id)
  values (v_note.recipient_name, v_note.recipient_address, v_note.id, v_note.tour_id)
  returning id into v_invoice_id;

  insert into invoice_items (invoice_id, product_id, qty)
  select v_invoice_id, product_id, qty
  from delivery_note_items where delivery_note_id = p_delivery_note_id
  order by position;

  return v_invoice_id;
end
$$;

-- Täglich per Cron: offene Rechnungen nach Fälligkeit auf „überfällig“ setzen.
create function mark_overdue_invoices() returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_count integer;
  v_previous text;
begin
  v_previous := _bypass_on();
  update invoices set status = 'overdue' where status = 'open' and due_date < berlin_today();
  get diagnostics v_count = row_count;
  perform _bypass_restore(v_previous);
  return v_count;
end
$$;

create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('mark-overdue-invoices', '0 1 * * *', 'select public.mark_overdue_invoices()');

grant execute on function finalize_invoice(uuid) to authenticated;
grant execute on function cancel_invoice(uuid) to authenticated;
grant execute on function mark_invoice_paid(uuid, date) to authenticated;
grant execute on function mark_invoice_unpaid(uuid) to authenticated;
grant execute on function invoice_from_delivery_note(uuid) to authenticated;
