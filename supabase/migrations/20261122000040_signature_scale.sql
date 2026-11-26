-- Größe der Unterschrift im PDF in Prozent (100 = Standard). Gilt für beide
-- Unterschriftsfelder auf Lieferschein und Rechnung.
alter table company_settings
  add column signature_scale int not null default 100
  check (signature_scale between 50 and 200);
