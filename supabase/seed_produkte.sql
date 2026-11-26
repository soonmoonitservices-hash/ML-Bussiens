-- Startsortiment mit deutschem und arabischem Namen. Es gibt keinen Lagerbestand.
-- WICHTIG: Unten 'DEINE-EMAIL' durch die E-Mail des Chefs der Firma ersetzen, die die Produkte
-- bekommen soll. Jede Firma hat ihre eigenen Produkte.
-- Einmal im Supabase-Dashboard unter SQL Editor einfügen und ausführen. Läuft mehrfach
-- ohne Doppelte: Produkte mit gleichem Namen werden übersprungen.
--
-- Einheiten: kg = Käse, jar = Glas, piece = Flasche/Stück. Bei Glas und Stück gilt:
-- units_per_carton = so viele stecken in einem Karton. Bei der Tour lassen sich Kartons
-- und einzelne Gläser getrennt eingeben.
--
-- ACHTUNG: Die Preise stehen auf 0,00 €. Bitte in der App unter Produkte > Produkt
-- bearbeiten die echten Preise eintragen, sonst werden Touren mit 0 € bewertet.
-- Bei „دوبركة“ und „موصنارة“ bin ich beim deutschen Namen nicht sicher: Dort steht der
-- arabische Name auch als Hauptname. Bitte in der App korrigieren.

insert into products (
  tenant_id, name, name_ar, category, unit, units_per_carton, buy_price_net_cents,
  sell_price_net_cents, vat_rate
)
select t.tenant_id, v.name, v.name_ar, v.category, v.unit::product_unit, v.units_per_carton, 0, 0, 7
from (values
  -- Käse und Milchprodukte, pro kg
  ('Baladi-Käse', 'جبنة بلدي', 'Käse', 'kg', null::bigint),
  ('دوبركة', 'دوبركة', 'Käse', 'kg', null),
  ('Labneh', 'لبنة', 'Käse', 'kg', null),
  ('Mishallal-Käse', 'مشلل', 'Käse', 'kg', null),
  ('موصنارة', 'موصنارة', 'Käse', 'kg', null),
  ('Kaymak', 'قشطة', 'Käse', 'kg', null),
  ('Shanklish', 'شنكليش', 'Käse', 'kg', null),
  -- Gläser mit Karton
  ('Oliven', 'زيتون', 'Oliven & Eingelegtes', 'jar', 6),
  ('Makdous', 'مكدوس', 'Oliven & Eingelegtes', 'jar', 6),
  ('Paprikapaste', 'معجون الفلفل', 'Pasten', 'jar', 12),
  ('Tomatenmark', 'معجون الطماطم', 'Pasten', 'jar', 12),
  -- Flaschen mit Karton
  ('Olivenöl', 'زيت زيتون', 'Öle & Feinkost', 'piece', 6)
) as v(name, name_ar, category, unit, units_per_carton)
cross join (select tenant_id from profiles where email = 'DEINE-EMAIL') as t
where not exists (
  select 1 from products p where p.name = v.name and p.tenant_id = t.tenant_id
);
