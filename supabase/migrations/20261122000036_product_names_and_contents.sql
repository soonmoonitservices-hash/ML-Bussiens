-- Produkte mit zwei Namen (Deutsch und Arabisch) und Karton-Inhalt.
--   name     = Hauptname (Deutsch; wenn nur Arabisch angegeben wird, steht er hier)
--   name_ar  = arabischer Name (freiwillig)
-- Mindestens ein Name ist Pflicht (name ist nie leer). Die App zeigt den Namen in der Sprache
-- der Oberfläche und fällt auf den anderen zurück. Dokumente (Lieferschein, Rechnung) behalten
-- den Hauptnamen.
--
-- Ein Produkt mit der Einheit „Karton“ hat einen Inhalt: welche Produkte in welcher Menge
-- darin stecken. Er ist nur eine Beschreibung (es gibt keinen Bestand, der abgebucht würde);
-- der Karton wird als ein Produkt mit eigenem Preis geladen und verkauft. Das ersetzt die
-- getrennten „Mischkartons“.

alter table products add column name_ar text
  check (name_ar is null or (btrim(name_ar) <> '' and char_length(name_ar) <= 200));
comment on column products.name_ar is 'Arabischer Name des Produkts (freiwillig). name bleibt der Hauptname.';
create index products_name_ar_trgm_idx on products using gin (name_ar extensions.gin_trgm_ops);

create table product_contents (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references products (id) on delete cascade,
  content_product_id uuid not null references products (id) on delete restrict,
  -- Menge in der Basiseinheit des enthaltenen Produkts (Stück, Gläser oder Gramm) je Karton
  qty bigint not null check (qty > 0),
  tenant_id uuid not null default current_tenant() references tenants (id) on delete restrict,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (product_id, content_product_id),
  check (product_id <> content_product_id)
);
create index product_contents_product_idx on product_contents (product_id);
create index product_contents_content_idx on product_contents (content_product_id);
create index product_contents_tenant_idx on product_contents (tenant_id);

comment on table product_contents is 'Inhalt eines Kartons: Produkt und Menge je Karton (nur Beschreibung).';
comment on column product_contents.qty is 'Menge je Karton in der Basiseinheit des enthaltenen Produkts.';

create trigger a_audit before insert or update on product_contents
  for each row execute function _set_audit_columns();
create trigger a0_tenant before insert or update on product_contents
  for each row execute function _tenant_guard('product_id:products', 'content_product_id:products');

-- Nur Karton-Produkte haben einen Inhalt.
create function _product_contents_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select unit from products where id = new.product_id) <> 'carton' then
    raise exception 'Nur Produkte mit der Einheit Karton haben einen Inhalt.';
  end if;
  return new;
end
$$;
create trigger b_guard before insert or update on product_contents
  for each row execute function _product_contents_guard();

alter table product_contents enable row level security;
create policy product_contents_select on product_contents for select to authenticated
  using (tenant_id = (select current_tenant()));
create policy product_contents_insert on product_contents for insert to authenticated
  with check (tenant_id = (select current_tenant()));
create policy product_contents_update on product_contents for update to authenticated
  using (tenant_id = (select current_tenant())) with check (tenant_id = (select current_tenant()));
create policy product_contents_delete on product_contents for delete to authenticated
  using (tenant_id = (select current_tenant()));
grant select, insert, update, delete on product_contents to authenticated;

-- Die getrennten Mischkartons entfallen.
drop table product_bundle_items;
drop table product_bundles;
