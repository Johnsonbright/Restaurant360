create table public.payments (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete restrict,
  customer_id uuid references public.customers (id) on delete set null,
  expected_amount numeric(10, 2) not null check (expected_amount >= 0),
  amount_recorded numeric(10, 2) not null default 0 check (amount_recorded >= 0),
  payment_reference text,
  payment_date timestamptz,
  status public.payment_status not null default 'Pending',
  recorded_by_user_id uuid references public.profiles (id) on delete set null,
  notes text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.deliveries (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  order_id uuid not null unique references public.orders (id) on delete cascade,
  customer_id uuid references public.customers (id) on delete set null,
  delivery_address text not null,
  delivery_city text,
  delivery_region text,
  delivery_postal_code text,
  assigned_rider_id uuid references public.profiles (id) on delete set null,
  dispatch_date timestamptz,
  expected_delivery_at timestamptz,
  delivered_at timestamptz,
  status public.delivery_status not null default 'Awaiting Assignment',
  notes text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.tables (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  table_number text not null unique,
  capacity integer not null check (capacity > 0),
  is_active boolean not null default true,
  notes text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.reservations (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  reference text not null unique default (
    'RSV-' || pg_catalog.upper(
      pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', '')
    )
  ),
  customer_id uuid references public.customers (id) on delete set null,
  customer_name text not null,
  customer_email text not null,
  customer_phone text not null,
  reservation_date date not null,
  reservation_time time without time zone not null,
  number_of_guests integer not null check (number_of_guests > 0),
  table_id uuid references public.tables (id) on delete set null,
  status public.reservation_status not null default 'Requested',
  special_requests text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create index payments_order_id_idx on public.payments (order_id);
create index payments_customer_id_idx on public.payments (customer_id);
create index payments_recorded_by_user_id_idx on public.payments (recorded_by_user_id);
create index payments_status_idx on public.payments (status);
create index payments_payment_date_idx on public.payments (payment_date);
create index payments_created_at_idx on public.payments (created_at);

create index deliveries_customer_id_idx on public.deliveries (customer_id);
create index deliveries_assigned_rider_id_idx on public.deliveries (assigned_rider_id);
create index deliveries_status_idx on public.deliveries (status);
create index deliveries_dispatch_date_idx on public.deliveries (dispatch_date);
create index deliveries_expected_delivery_at_idx on public.deliveries (expected_delivery_at);
create index deliveries_delivered_at_idx on public.deliveries (delivered_at);

create index tables_is_active_idx on public.tables (is_active);

create index reservations_customer_id_idx on public.reservations (customer_id);
create index reservations_table_id_idx on public.reservations (table_id);
create index reservations_status_idx on public.reservations (status);
create index reservations_reservation_date_idx on public.reservations (reservation_date);
create index reservations_created_at_idx on public.reservations (created_at);

create trigger set_payments_updated_at
before update on public.payments
for each row execute procedure public.set_updated_at();

create trigger set_deliveries_updated_at
before update on public.deliveries
for each row execute procedure public.set_updated_at();

create trigger set_tables_updated_at
before update on public.tables
for each row execute procedure public.set_updated_at();

create trigger set_reservations_updated_at
before update on public.reservations
for each row execute procedure public.set_updated_at();

alter table public.payments enable row level security;
alter table public.deliveries enable row level security;
alter table public.tables enable row level security;
alter table public.reservations enable row level security;

grant select, insert, update, delete on public.payments to authenticated;
grant select, insert, update, delete on public.deliveries to authenticated;
grant select, insert, update, delete on public.tables to authenticated;
grant select, insert, update, delete on public.reservations to authenticated;
grant insert on public.reservations to anon;

create policy payments_customer_read_own
on public.payments
for select
to authenticated
using (
  exists (
    select 1
    from public.customers as customer
    where customer.id = payments.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy payments_finance_read
on public.payments
for select
to authenticated
using ((select public.has_role('finance'::public.app_role)));

create policy payments_finance_insert
on public.payments
for insert
to authenticated
with check ((select public.has_role('finance'::public.app_role)));

create policy payments_finance_update
on public.payments
for update
to authenticated
using ((select public.has_role('finance'::public.app_role)))
with check ((select public.has_role('finance'::public.app_role)));

create policy payments_manager_admin_all
on public.payments
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy deliveries_customer_read_own
on public.deliveries
for select
to authenticated
using (
  exists (
    select 1
    from public.customers as customer
    where customer.id = deliveries.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy deliveries_rider_read_assigned
on public.deliveries
for select
to authenticated
using (assigned_rider_id = (select auth.uid()));

create policy deliveries_rider_update_assigned
on public.deliveries
for update
to authenticated
using (assigned_rider_id = (select auth.uid()))
with check (assigned_rider_id = (select auth.uid()));

create policy deliveries_manager_admin_all
on public.deliveries
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy tables_manager_admin_all
on public.tables
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy reservations_customer_read_own
on public.reservations
for select
to authenticated
using (
  exists (
    select 1
    from public.customers as customer
    where customer.id = reservations.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy reservations_customer_insert_requested
on public.reservations
for insert
to authenticated
with check (
  status = 'Requested'::public.reservation_status
  and table_id is null
  and exists (
    select 1
    from public.customers as customer
    where customer.id = reservations.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy reservations_anon_insert_requested
on public.reservations
for insert
to anon
with check (
  status = 'Requested'::public.reservation_status
  and customer_id is null
  and table_id is null
);

create policy reservations_manager_admin_all
on public.reservations
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));
