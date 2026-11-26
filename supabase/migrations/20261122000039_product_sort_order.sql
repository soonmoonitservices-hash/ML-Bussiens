-- Eigene Reihenfolge der Produkte: Der Chef zieht Produkte in der Liste nach
-- oben oder unten. Die Reihenfolge gilt für die ganze Firma und für alle
-- Auswahllisten. Neue Produkte kommen ans Ende.
create sequence products_sort_seq;

alter table products add column sort_order bigint;

-- Bestehende Produkte: bisherige Reihenfolge (nach Name) je Firma übernehmen.
update products p
  set sort_order = s.rn
  from (
    select id, row_number() over (order by name, id) as rn
    from products
  ) s
  where p.id = s.id;

select setval('products_sort_seq', coalesce((select max(sort_order) from products), 0) + 1, false);

alter table products
  alter column sort_order set default nextval('products_sort_seq'),
  alter column sort_order set not null;

alter sequence products_sort_seq owned by products.sort_order;
grant usage on sequence products_sort_seq to authenticated;

create index products_sort_order_idx on products (tenant_id, sort_order);

-- Neue Reihenfolge speichern. Die Liste [p_ids] steht in der neuen Reihenfolge.
-- Die vorhandenen Positionen dieser Produkte werden in der neuen Reihenfolge
-- neu verteilt; so bleiben Produkte, die nicht in der Liste sind (Suche, Filter,
-- noch nicht geladene Seiten), an ihrem Platz. Läuft mit den Rechten des
-- Aufrufers, die Zeilensicherheit (Firma) gilt also.
create function reorder_products(p_ids uuid[])
returns void
language sql security invoker set search_path = public as $$
  with slots as (
    select sort_order, row_number() over (order by sort_order) as rn
    from products
    where id = any (p_ids)
  ),
  wanted as (
    select id, ord from unnest(p_ids) with ordinality as t (id, ord)
  )
  update products p
    set sort_order = s.sort_order
    from wanted w
    join slots s on s.rn = w.ord
    where p.id = w.id
      and p.sort_order is distinct from s.sort_order;
$$;

revoke all on function reorder_products(uuid[]) from public, anon;
grant execute on function reorder_products(uuid[]) to authenticated;
