create table public.orders (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  reference text not null unique,
  customer_id uuid references public.customers (id) on delete set null,
  order_type public.order_type not null,
  total numeric(10, 2) not null default 0 check (total >= 0),
  status public.order_status not null default 'New',
  special_instructions text,
  delivery_address text,
  delivery_city text,
  delivery_region text,
  delivery_postal_code text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  check (order_type = 'delivery' or delivery_address is null)
);

create table public.order_items (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  menu_item_id uuid not null references public.menu_items (id) on delete restrict,
  menu_item_name text not null,
  quantity integer not null check (quantity > 0),
  variation_id uuid references public.menu_variations (id) on delete set null,
  variation_snapshot jsonb not null default '{}'::jsonb,
  addons_snapshot jsonb not null default '[]'::jsonb
    check (pg_catalog.jsonb_typeof(addons_snapshot) = 'array'),
  special_instructions text,
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  line_total numeric(10, 2) not null check (line_total >= 0),
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.order_status_log (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  previous_status public.order_status,
  new_status public.order_status not null,
  changed_by_user_id uuid references public.profiles (id) on delete set null,
  changed_at timestamptz not null default pg_catalog.now(),
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.kitchen_records (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  order_id uuid not null unique references public.orders (id) on delete cascade,
  assigned_staff_id uuid references public.profiles (id) on delete set null,
  preparation_started_at timestamptz,
  ready_at timestamptz,
  is_delayed boolean not null default false,
  notes text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create index orders_customer_id_idx on public.orders (customer_id);
create index orders_order_type_idx on public.orders (order_type);
create index orders_status_idx on public.orders (status);
create index orders_created_at_idx on public.orders (created_at);
create index order_items_order_id_idx on public.order_items (order_id);
create index order_items_menu_item_id_idx on public.order_items (menu_item_id);
create index order_items_variation_id_idx on public.order_items (variation_id);
create index order_items_created_at_idx on public.order_items (created_at);
create index order_status_log_order_id_idx on public.order_status_log (order_id);
create index order_status_log_changed_by_user_id_idx on public.order_status_log (changed_by_user_id);
create index order_status_log_changed_at_idx on public.order_status_log (changed_at);
create index kitchen_records_assigned_staff_id_idx on public.kitchen_records (assigned_staff_id);
create index kitchen_records_preparation_started_at_idx on public.kitchen_records (preparation_started_at);
create index kitchen_records_ready_at_idx on public.kitchen_records (ready_at);
create index kitchen_records_is_delayed_idx on public.kitchen_records (is_delayed);

create trigger set_orders_updated_at
before update on public.orders
for each row execute procedure public.set_updated_at();

create trigger set_order_items_updated_at
before update on public.order_items
for each row execute procedure public.set_updated_at();

create trigger set_order_status_log_updated_at
before update on public.order_status_log
for each row execute procedure public.set_updated_at();

create trigger set_kitchen_records_updated_at
before update on public.kitchen_records
for each row execute procedure public.set_updated_at();

alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_log enable row level security;
alter table public.kitchen_records enable row level security;

grant select, insert, update, delete on public.orders to authenticated;
grant select, insert, update, delete on public.order_items to authenticated;
grant select on public.order_status_log to authenticated;
grant select, insert, update, delete on public.kitchen_records to authenticated;

create policy orders_customer_read_own
on public.orders
for select
to authenticated
using (
  exists (
    select 1
    from public.customers as customer
    where customer.id = orders.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy orders_customer_insert_own_new
on public.orders
for insert
to authenticated
with check (
  status = 'New'::public.order_status
  and total = 0
  and exists (
    select 1
    from public.customers as customer
    where customer.id = orders.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy orders_kitchen_read
on public.orders
for select
to authenticated
using ((select public.has_role('kitchen'::public.app_role)));

create policy orders_manager_admin_all
on public.orders
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy order_items_customer_read_own
on public.order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.orders as order_record
    join public.customers as customer on customer.id = order_record.customer_id
    where order_record.id = order_items.order_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy order_items_kitchen_read
on public.order_items
for select
to authenticated
using ((select public.has_role('kitchen'::public.app_role)));

create policy order_items_manager_admin_all
on public.order_items
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy order_status_log_customer_read_own
on public.order_status_log
for select
to authenticated
using (
  exists (
    select 1
    from public.orders as order_record
    join public.customers as customer on customer.id = order_record.customer_id
    where order_record.id = order_status_log.order_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy order_status_log_staff_read
on public.order_status_log
for select
to authenticated
using (
  (select public.has_role('kitchen'::public.app_role, 'manager'::public.app_role, 'admin'::public.app_role))
);

create policy kitchen_records_kitchen_read
on public.kitchen_records
for select
to authenticated
using ((select public.has_role('kitchen'::public.app_role)));

create policy kitchen_records_manager_admin_all
on public.kitchen_records
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));
