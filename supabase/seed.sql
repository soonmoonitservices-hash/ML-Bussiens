-- Beispieldaten für die lokale Entwicklung und die Tests: 2 Fahrer, 3 Produkte.
-- Preise in Cent pro Basiseinheit (bei kg: pro Kilogramm),

insert into drivers (tenant_id, name, phone, vehicle) values
  ('a0000000-0000-4000-8000-000000000001', 'Ahmad Khalil', '+49 170 1234567', 'Sprinter B-WB 101'),
  ('a0000000-0000-4000-8000-000000000001', 'Samir Haddad', '+49 171 7654321', 'Sprinter B-WB 102');

insert into products (
  tenant_id, name, category, unit, units_per_carton, buy_price_net_cents, sell_price_net_cents,
  vat_rate
) values
  -- 1 Karton = 4 Gläser
  ('a0000000-0000-4000-8000-000000000001', 'Grüne Oliven', 'Oliven', 'jar', 4, 300, 450, 7),
  -- Preis pro kg
  ('a0000000-0000-4000-8000-000000000001', 'Baladi-Käse', 'Käse', 'kg', null, 600, 900, 7),
  -- 1 Karton = 12 Stück
  ('a0000000-0000-4000-8000-000000000001', 'Olivenöl 1 l', 'Öle & Feinkost', 'piece', 12, 720, 1250, 7);
