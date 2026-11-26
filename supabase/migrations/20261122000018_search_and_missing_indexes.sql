-- Schnelle Suche („enthält“) und die letzten fehlenden Indizes.

create extension if not exists pg_trgm with schema extensions;

create index products_name_trgm_idx on products using gin (name extensions.gin_trgm_ops);
create index delivery_notes_recipient_trgm_idx on delivery_notes using gin (recipient_name extensions.gin_trgm_ops);
create index invoices_recipient_trgm_idx on invoices using gin (recipient_name extensions.gin_trgm_ops);

create index invoices_cancelled_by_idx on invoices (cancelled_by_invoice_id);
create index tours_closed_at_idx on tours (closed_at);
create index products_active_name_idx on products (active, name);
