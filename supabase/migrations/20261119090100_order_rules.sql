create or replace function public.capture_order_item_price()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  menu_item_record public.menu_items%rowtype;
  variation_record public.menu_variations%rowtype;
  addon_record public.menu_addons%rowtype;
  addon_request jsonb;
  addon_id uuid;
  variation_adjustment numeric(10, 2) := 0;
  addons_total numeric(10, 2) := 0;
  calculated_unit_price numeric(10, 2);
  normalized_addons jsonb := '[]'::jsonb;
begin
  if new.quantity is null or new.quantity <= 0 then
    raise exception 'Order item quantity must be greater than zero';
  end if;

  if new.addons_snapshot is null
    or pg_catalog.jsonb_typeof(new.addons_snapshot) <> 'array'
  then
    raise exception 'Order item add-ons must be supplied as an array';
  end if;

  select item.*
  into menu_item_record
  from public.menu_items as item
  join public.categories as category on category.id = item.category_id
  where item.id = new.menu_item_id
    and item.is_available
    and category.is_active;

  if not found then
    raise exception 'Menu item % is unavailable', new.menu_item_id;
  end if;

  if new.variation_id is not null then
    select variation.*
    into variation_record
    from public.menu_variations as variation
    where variation.id = new.variation_id
      and variation.menu_item_id = new.menu_item_id
      and variation.is_available;

    if not found then
      raise exception 'Selected variation is unavailable for menu item %', new.menu_item_id;
    end if;

    variation_adjustment := variation_record.price_adjustment;
    new.variation_snapshot := pg_catalog.jsonb_build_object(
      'id', variation_record.id,
      'name', variation_record.name,
      'price_adjustment', variation_record.price_adjustment
    );
  else
    new.variation_snapshot := '{}'::jsonb;
  end if;

  for addon_request in
    select requested.value
    from pg_catalog.jsonb_array_elements(new.addons_snapshot) as requested(value)
  loop
    if pg_catalog.jsonb_typeof(addon_request) = 'string' then
      addon_id := nullif(addon_request #>> '{}'::text[], '')::uuid;
    else
      addon_id := nullif(addon_request ->> 'id', '')::uuid;
    end if;

    if addon_id is null then
      raise exception 'Each selected add-on must include a valid id';
    end if;

    select addon.*
    into addon_record
    from public.menu_addons as addon
    where addon.id = addon_id
      and addon.menu_item_id = new.menu_item_id
      and addon.is_available;

    if not found then
      raise exception 'Selected add-on % is unavailable for menu item %',
        addon_id,
        new.menu_item_id;
    end if;

    addons_total := addons_total + addon_record.price;
    normalized_addons := normalized_addons || pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object(
        'id', addon_record.id,
        'name', addon_record.name,
        'price', addon_record.price
      )
    );
  end loop;

  calculated_unit_price :=
    menu_item_record.price + variation_adjustment + addons_total;

  if calculated_unit_price < 0 then
    raise exception 'Calculated order item price cannot be negative';
  end if;

  new.menu_item_name := menu_item_record.name;
  new.unit_price := calculated_unit_price;
  new.line_total := pg_catalog.round(calculated_unit_price * new.quantity, 2);
  new.addons_snapshot := normalized_addons;

  return new;
end;
$$;

-- Replaces client-sent order item prices with current available menu prices.
create trigger capture_order_item_price_before_insert
before insert on public.order_items
for each row execute procedure public.capture_order_item_price();

create or replace function public.sync_order_total_from_items()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_order_ids uuid[];
  affected_order_id uuid;
begin
  if tg_op = 'INSERT' then
    affected_order_ids := array[new.order_id];
  elsif tg_op = 'DELETE' then
    affected_order_ids := array[old.order_id];
  else
    affected_order_ids := array[old.order_id, new.order_id];
  end if;

  for affected_order_id in
    select distinct changed_order.id
    from pg_catalog.unnest(affected_order_ids) as changed_order(id)
    where changed_order.id is not null
    order by changed_order.id
  loop
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        'restaurant360:order-items:' || affected_order_id::text,
        0
      )
    );

    update public.orders as order_record
    set total = coalesce(
      (
        select pg_catalog.sum(order_item.line_total)
        from public.order_items as order_item
        where order_item.order_id = affected_order_id
      ),
      0
    )
    where order_record.id = affected_order_id;
  end loop;

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

-- Keeps each affected order total equal to the sum of its item line totals.
create trigger sync_order_total_after_item_change
after insert or update or delete on public.order_items
for each row execute procedure public.sync_order_total_from_items();

update public.orders as order_record
set total = coalesce(
  (
    select pg_catalog.sum(order_item.line_total)
    from public.order_items as order_item
    where order_item.order_id = order_record.id
  ),
  0
);

create or replace function public.validate_order_status_transition()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_role public.app_role := public.current_app_role();
  latest_payment_status public.payment_status;
  transition_allowed boolean := false;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  if actor_role = 'customer'::public.app_role then
    if old.status <> 'New'::public.order_status
      or new.status <> 'Cancelled'::public.order_status
    then
      raise exception 'Customers may only cancel their own New orders';
    end if;

    if not exists (
      select 1
      from public.customers as customer
      where customer.id = old.customer_id
        and customer.auth_user_id = (select auth.uid())
    ) then
      raise exception 'Customers may only cancel their own orders';
    end if;

    if (pg_catalog.to_jsonb(new) - 'status' - 'updated_at')
      is distinct from
      (pg_catalog.to_jsonb(old) - 'status' - 'updated_at')
    then
      raise exception 'Customers may only change the status when cancelling an order';
    end if;
  elsif actor_role is not null
    and actor_role not in (
      'kitchen'::public.app_role,
      'manager'::public.app_role,
      'admin'::public.app_role
    )
  then
    raise exception 'Role % is not allowed to change order status', actor_role;
  end if;

  if old.status = 'New'::public.order_status then
    transition_allowed := new.status in (
      'Confirmed'::public.order_status,
      'Cancelled'::public.order_status
    );
  elsif old.status = 'Confirmed'::public.order_status then
    transition_allowed := new.status in (
      'Preparing'::public.order_status,
      'Cancelled'::public.order_status
    );
  elsif old.status = 'Preparing'::public.order_status then
    transition_allowed := new.status in (
      'Ready for Collection'::public.order_status,
      'Ready for Delivery'::public.order_status,
      'Cancelled'::public.order_status
    );
  elsif old.status in (
    'Ready for Collection'::public.order_status,
    'Ready for Delivery'::public.order_status
  ) then
    transition_allowed := new.status = 'Completed'::public.order_status;
  end if;

  if not transition_allowed then
    raise exception 'Invalid order status transition from % to %',
      old.status,
      new.status;
  end if;

  if new.status = 'Confirmed'::public.order_status
    and new.order_type = 'delivery'::public.order_type
  then
    select payment.status
    into latest_payment_status
    from public.payments as payment
    where payment.order_id = old.id
    order by payment.created_at desc, payment.id desc
    limit 1;

    if latest_payment_status is null
      or latest_payment_status not in (
        'Paid'::public.payment_status,
        'Awaiting Verification'::public.payment_status
      )
    then
      raise exception
        'Delivery order % cannot be confirmed until its latest payment is Paid or Awaiting Verification',
        old.reference;
    end if;
  end if;

  return new;
end;
$$;

create policy orders_customer_cancel_own_new
on public.orders
for update
to authenticated
using (
  status = 'New'::public.order_status
  and exists (
    select 1
    from public.customers as customer
    where customer.id = orders.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
)
with check (
  status = 'Cancelled'::public.order_status
  and exists (
    select 1
    from public.customers as customer
    where customer.id = orders.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

-- Enforces allowed order status transitions and the delivery payment rule.
create trigger validate_order_status_before_update
before update of status on public.orders
for each row execute procedure public.validate_order_status_transition();

create or replace function public.log_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.order_status_log (
    order_id,
    previous_status,
    new_status,
    changed_by_user_id,
    changed_at
  )
  values (
    new.id,
    old.status,
    new.status,
    (select auth.uid()),
    pg_catalog.now()
  );

  return new;
end;
$$;

-- Writes the actor and timestamp for every order status change.
create trigger log_order_status_after_update
after update of status on public.orders
for each row
when (old.status is distinct from new.status)
execute procedure public.log_order_status_change();

create or replace function public.sync_kitchen_record_with_order_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  preparation_started_at timestamptz;
  ready_at timestamptz;
  assigned_staff_id uuid;
begin
  if new.status = 'Preparing'::public.order_status then
    preparation_started_at := pg_catalog.now();
  elsif new.status in (
    'Ready for Collection'::public.order_status,
    'Ready for Delivery'::public.order_status
  ) then
    ready_at := pg_catalog.now();
  else
    return new;
  end if;

  if public.current_app_role() = 'kitchen'::public.app_role then
    assigned_staff_id := (select auth.uid());
  end if;

  insert into public.kitchen_records (
    order_id,
    assigned_staff_id,
    preparation_started_at,
    ready_at
  )
  values (
    new.id,
    assigned_staff_id,
    preparation_started_at,
    ready_at
  )
  on conflict (order_id) do update
  set assigned_staff_id = coalesce(
        public.kitchen_records.assigned_staff_id,
        excluded.assigned_staff_id
      ),
      preparation_started_at = coalesce(
        public.kitchen_records.preparation_started_at,
        excluded.preparation_started_at
      ),
      ready_at = coalesce(
        public.kitchen_records.ready_at,
        excluded.ready_at
      );

  return new;
end;
$$;

-- Stamps preparation and ready times, creating a kitchen record if needed.
create trigger sync_kitchen_record_after_order_status
after update of status on public.orders
for each row
when (old.status is distinct from new.status)
execute procedure public.sync_kitchen_record_with_order_status();

create or replace function public.create_delivery_for_delivery_order()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.order_type = 'delivery'::public.order_type then
    insert into public.deliveries (
      order_id,
      customer_id,
      delivery_address,
      delivery_city,
      delivery_region,
      delivery_postal_code,
      status
    )
    values (
      new.id,
      new.customer_id,
      new.delivery_address,
      new.delivery_city,
      new.delivery_region,
      new.delivery_postal_code,
      'Awaiting Assignment'::public.delivery_status
    );
  end if;

  return new;
end;
$$;

-- Creates an awaiting-assignment delivery for each newly inserted delivery order.
create trigger create_delivery_after_order_insert
after insert on public.orders
for each row execute procedure public.create_delivery_for_delivery_order();

create policy app_settings_kitchen_delayed_order_read
on public.app_settings
for select
to authenticated
using (
  key = 'delayed_order_minutes'
  and (select public.has_role('kitchen'::public.app_role))
);

create view public.delayed_orders
with (security_invoker = true)
as
select
  order_record.id,
  order_record.reference,
  order_record.customer_id,
  order_record.order_type,
  order_record.status,
  kitchen_record.preparation_started_at,
  (setting.value #>> '{}'::text[])::integer as delayed_order_minutes
from public.orders as order_record
join public.kitchen_records as kitchen_record
  on kitchen_record.order_id = order_record.id
join public.app_settings as setting
  on setting.key = 'delayed_order_minutes'
where order_record.status = 'Preparing'::public.order_status
  and kitchen_record.preparation_started_at is not null
  and pg_catalog.now() > kitchen_record.preparation_started_at
    + ((setting.value #>> '{}'::text[])::integer * interval '1 minute');

grant select on public.delayed_orders to authenticated;
