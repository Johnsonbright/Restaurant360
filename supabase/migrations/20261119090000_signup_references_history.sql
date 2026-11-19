create or replace function public.handle_new_customer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_name text;
begin
  resolved_name := coalesce(
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'name'), ''),
    nullif(pg_catalog.split_part(coalesce(new.email, ''), '@', 1), ''),
    'Customer'
  );

  insert into public.customers (auth_user_id, name, email)
  values (new.id, resolved_name, new.email)
  on conflict (auth_user_id) do nothing;

  return new;
end;
$$;

-- Creates a linked customer record alongside the existing profile signup trigger.
create trigger on_auth_user_created_customer
after insert on auth.users
for each row execute procedure public.handle_new_customer();

insert into public.customers (auth_user_id, name, email)
select
  auth_user.id,
  coalesce(
    nullif(pg_catalog.btrim(auth_user.raw_user_meta_data ->> 'full_name'), ''),
    nullif(pg_catalog.btrim(auth_user.raw_user_meta_data ->> 'name'), ''),
    nullif(pg_catalog.split_part(coalesce(auth_user.email, ''), '@', 1), ''),
    'Customer'
  ),
  auth_user.email
from auth.users as auth_user
where not exists (
  select 1
  from public.customers as customer
  where customer.auth_user_id = auth_user.id
)
on conflict (auth_user_id) do nothing;

create or replace function public.generate_order_reference()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  reference_day text := pg_catalog.to_char(
    pg_catalog.timezone('UTC', pg_catalog.now()),
    'YYYYMMDD'
  );
  next_number integer;
begin
  if new.reference is null then
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended('restaurant360:order:' || reference_day, 0)
    );

    select coalesce(
      pg_catalog.max(pg_catalog.substr(order_record.reference, 15)::integer),
      0
    ) + 1
    into next_number
    from public.orders as order_record
    where order_record.reference ~ ('^R360-' || reference_day || '-[0-9]+$');

    new.reference := 'R360-' || reference_day || '-'
      || pg_catalog.lpad(next_number::text, 4, '0');
  end if;

  return new;
end;
$$;

-- Assigns a unique daily order reference when the caller did not supply one.
create trigger generate_order_reference_before_insert
before insert on public.orders
for each row execute procedure public.generate_order_reference();

alter table public.reservations
alter column reference drop default;

create or replace function public.generate_reservation_reference()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  reference_day text := pg_catalog.to_char(
    pg_catalog.timezone('UTC', pg_catalog.now()),
    'YYYYMMDD'
  );
  next_number integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('restaurant360:reservation:' || reference_day, 0)
  );

  select coalesce(
    pg_catalog.max(pg_catalog.substr(reservation.reference, 14)::integer),
    0
  ) + 1
  into next_number
  from public.reservations as reservation
  where reservation.reference ~ ('^RSV-' || reference_day || '-[0-9]+$');

  new.reference := 'RSV-' || reference_day || '-'
    || pg_catalog.lpad(next_number::text, 4, '0');

  return new;
end;
$$;

-- Assigns a unique daily reservation reference, replacing the UUID default.
create trigger generate_reservation_reference_before_insert
before insert on public.reservations
for each row execute procedure public.generate_reservation_reference();

create or replace function public.snapshot_menu_item_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.menu_item_history (
    menu_item_id,
    menu_item_reference,
    snapshot,
    changed_by_user_id
  )
  values (
    new.id,
    new.reference,
    pg_catalog.to_jsonb(new),
    (select auth.uid())
  );

  return new;
end;
$$;

-- Records the complete menu item state and actor after each insert or update.
create trigger snapshot_menu_item_history_after_change
after insert or update on public.menu_items
for each row execute procedure public.snapshot_menu_item_history();
