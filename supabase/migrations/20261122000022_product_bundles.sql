-- Mischkartons: eine Zusammenstellung aus mehreren Produkten (z. B. 2 Gläser Oliven +
-- 1 Glas Makdous). Sie ist nur eine Vorlage: Beim Beladen löst die App sie in die
-- Einzelprodukte auf, der Bestand dieser Produkte wird wie immer von der Datenbank
-- gebucht. Der Mischkarton selbst hat keinen Bestand.

create table product_bundles (
  id uuid primary key default gen_random_uuid(),
  name text not null check (btrim(name) <> '' and char_length(name) <= 200),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create table product_bundle_items (
  id uuid primary key default gen_random_uuid(),
  bundle_id uuid not null references product_bundles (id) on delete cascade,
  product_id uuid not null references products (id) on delete restrict,
  -- Menge in der Basiseinheit des Produkts (Gläser, Stück, Gramm), pro Mischkarton
  qty bigint not null check (qty > 0),
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (bundle_id, product_id)
);

create index product_bundle_items_product_idx on product_bundle_items (product_id);

create trigger a_audit before insert or update on product_bundles
  for each row execute function _set_audit_columns();
create trigger a_audit before insert or update on product_bundle_items
  for each row execute function _set_audit_columns();

alter table product_bundles enable row level security;
alter table product_bundle_items enable row level security;

do $$
declare
  v_table text;
begin
  foreach v_table in array array['product_bundles', 'product_bundle_items'] loop
    execute format('create policy %I on %I for select to authenticated using ((select is_active_user()))',
      v_table || '_select', v_table);
    execute format('create policy %I on %I for insert to authenticated with check ((select is_active_user()))',
      v_table || '_insert', v_table);
    execute format('create policy %I on %I for update to authenticated using ((select is_active_user())) with check ((select is_active_user()))',
      v_table || '_update', v_table);
    execute format('create policy %I on %I for delete to authenticated using ((select is_active_user()))',
      v_table || '_delete', v_table);
    execute format('grant select, insert, update, delete on public.%I to authenticated', v_table);
  end loop;
end
$$;

comment on table product_bundles is 'Mischkarton: Vorlage aus mehreren Produkten, wird beim Beladen aufgelöst.';
comment on table product_bundle_items is 'Inhalt eines Mischkartons: Produkt und Menge in Basiseinheit.';
comment on column product_bundle_items.qty is 'Menge pro Mischkarton in der Basiseinheit des Produkts.';
