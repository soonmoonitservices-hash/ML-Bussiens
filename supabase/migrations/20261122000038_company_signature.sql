-- Gespeicherte Unterschrift der Firma (Bild im Speicher "signatures").
-- Je Dokumentart einstellbar, ob sie auf Lieferschein bzw. Rechnung gedruckt wird.
alter table company_settings
  add column signature_path text,
  add column signature_on_delivery_note boolean not null default true,
  add column signature_on_invoice boolean not null default true;
