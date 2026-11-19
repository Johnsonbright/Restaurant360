drop policy if exists notifications_recipient_read on public.notifications;
drop policy if exists notifications_manager_admin_all on public.notifications;

revoke insert, update, delete
on public.notifications
from public, anon, authenticated, service_role;

revoke select
on public.notifications
from public, anon;

grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

create policy notifications_recipient_read
on public.notifications
for select
to authenticated
using (
  recipient_user_id = (select auth.uid())
  or (
    recipient_user_id is null
    and recipient_role = (select public.current_app_role())
    and (select public.current_app_role()) <> 'customer'::public.app_role
  )
);

create policy notifications_recipient_mark_read
on public.notifications
for update
to authenticated
using (
  read_at is null
  and (
    recipient_user_id = (select auth.uid())
    or (
      recipient_user_id is null
      and recipient_role = (select public.current_app_role())
      and (select public.current_app_role()) <> 'customer'::public.app_role
    )
  )
)
with check (
  read_at is not null
  and (
    recipient_user_id = (select auth.uid())
    or (
      recipient_user_id is null
      and recipient_role = (select public.current_app_role())
      and (select public.current_app_role()) <> 'customer'::public.app_role
    )
  )
);

create policy notifications_manager_admin_read
on public.notifications
for select
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy notifications_manager_admin_mark_read
on public.notifications
for update
to authenticated
using (
  read_at is null
  and (select public.has_role('manager'::public.app_role, 'admin'::public.app_role))
)
with check (
  read_at is not null
  and (select public.has_role('manager'::public.app_role, 'admin'::public.app_role))
);

create or replace function public.create_notification_once(
  p_event_type text,
  p_recipient_user_id uuid,
  p_recipient_role public.app_role,
  p_title text,
  p_message text,
  p_payload jsonb,
  p_event_key text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  notification_id uuid;
  notification_payload jsonb;
begin
  if (p_recipient_user_id is null) = (p_recipient_role is null) then
    raise exception 'A notification must have exactly one user or role recipient';
  end if;

  if p_event_key is null or p_event_key = '' then
    raise exception 'A notification event key is required';
  end if;

  notification_payload := coalesce(p_payload, '{}'::jsonb)
    || pg_catalog.jsonb_build_object('_event_key', p_event_key);

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'restaurant360:notification:'
        || p_event_type
        || ':'
        || coalesce(p_recipient_user_id::text, p_recipient_role::text)
        || ':'
        || p_event_key,
      0
    )
  );

  select notification.id
  into notification_id
  from public.notifications as notification
  where notification.event_type = p_event_type
    and notification.recipient_user_id is not distinct from p_recipient_user_id
    and notification.recipient_role is not distinct from p_recipient_role
    and notification.payload ->> '_event_key' = p_event_key
  limit 1;

  if found then
    update public.notifications as notification
    set title = p_title,
        message = p_message,
        payload = notification_payload
    where notification.id = notification_id;

    return false;
  end if;

  insert into public.notifications (
    recipient_user_id,
    recipient_role,
    event_type,
    title,
    message,
    payload
  )
  values (
    p_recipient_user_id,
    p_recipient_role,
    p_event_type,
    p_title,
    p_message,
    notification_payload
  );

  return true;
end;
$$;

revoke all on function public.create_notification_once(
  text,
  uuid,
  public.app_role,
  text,
  text,
  jsonb,
  text
) from public, anon, authenticated, service_role;

create or replace function public.notify_new_customer()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.create_notification_once(
    'welcome',
    new.auth_user_id,
    null,
    'Welcome to Restaurant360',
    pg_catalog.format('Welcome, %s! Your Restaurant360 account is ready.', new.name),
    pg_catalog.jsonb_build_object(
      'customer_id', new.id,
      'customer_name', new.name
    ),
    new.id::text
  );

  return new;
end;
$$;

-- Sends the welcome notification to each newly linked customer account.
create trigger notify_new_customer_after_insert
after insert on public.customers
for each row
when (new.auth_user_id is not null)
execute procedure public.notify_new_customer();

create or replace function public.notify_order_submitted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  order_reference text;
  order_customer_id uuid;
  customer_user_id uuid;
  customer_name text;
  item_names text;
  order_payload jsonb;
begin
  select
    order_record.reference,
    order_record.customer_id,
    customer.auth_user_id,
    coalesce(customer.name, 'Guest')
  into
    order_reference,
    order_customer_id,
    customer_user_id,
    customer_name
  from public.orders as order_record
  left join public.customers as customer
    on customer.id = order_record.customer_id
  where order_record.id = new.order_id;

  select coalesce(
    pg_catalog.string_agg(
      pg_catalog.format('%s x %s', order_item.quantity, order_item.menu_item_name),
      ', ' order by order_item.created_at, order_item.id
    ),
    'No items'
  )
  into item_names
  from public.order_items as order_item
  where order_item.order_id = new.order_id;

  order_payload := pg_catalog.jsonb_build_object(
    'order_id', new.order_id,
    'customer_id', order_customer_id,
    'customer_name', customer_name,
    'order_reference', order_reference,
    'item_names', item_names
  );

  if customer_user_id is not null then
    perform public.create_notification_once(
      'order_submitted',
      customer_user_id,
      null,
      'Order submitted',
      pg_catalog.format(
        'Hi %s, order %s was submitted. Items: %s.',
        customer_name,
        order_reference,
        item_names
      ),
      order_payload,
      new.order_id::text
    );
  end if;

  perform public.create_notification_once(
    'order_submitted',
    null,
    'kitchen'::public.app_role,
    'New order submitted',
    pg_catalog.format(
      'New order %s from %s: %s.',
      order_reference,
      customer_name,
      item_names
    ),
    order_payload,
    new.order_id::text
  );

  perform public.create_notification_once(
    'order_submitted',
    null,
    'manager'::public.app_role,
    'New order submitted',
    pg_catalog.format(
      'New order %s from %s: %s.',
      order_reference,
      customer_name,
      item_names
    ),
    order_payload,
    new.order_id::text
  );

  return new;
end;
$$;

-- Notifies the customer and staff as order items are submitted, refreshing the item list.
create trigger notify_order_submitted_after_item_insert
after insert on public.order_items
for each row execute procedure public.notify_order_submitted();

create or replace function public.notify_order_status_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  customer_user_id uuid;
  customer_name text;
  order_reference text;
  item_names text;
  event_type text;
  notification_title text;
  notification_message text;
begin
  if new.status = 'Confirmed'::public.order_status then
    event_type := 'order_confirmed';
    notification_title := 'Order confirmed';
    notification_message := 'has been confirmed';
  elsif new.status = 'Preparing'::public.order_status then
    event_type := 'order_preparing';
    notification_title := 'Order being prepared';
    notification_message := 'is being prepared';
  elsif new.status = 'Ready for Collection'::public.order_status then
    event_type := 'order_ready';
    notification_title := 'Order ready for collection';
    notification_message := 'is ready for collection';
  elsif new.status = 'Ready for Delivery'::public.order_status then
    event_type := 'order_ready';
    notification_title := 'Order ready for delivery';
    notification_message := 'is ready for delivery';
  else
    return new;
  end if;

  select
    customer.auth_user_id,
    coalesce(customer.name, 'Guest'),
    order_record.reference
  into customer_user_id, customer_name, order_reference
  from public.orders as order_record
  left join public.customers as customer
    on customer.id = order_record.customer_id
  where order_record.id = new.id;

  if customer_user_id is null then
    return new;
  end if;

  select coalesce(
    pg_catalog.string_agg(
      pg_catalog.format('%s x %s', order_item.quantity, order_item.menu_item_name),
      ', ' order by order_item.created_at, order_item.id
    ),
    'No items'
  )
  into item_names
  from public.order_items as order_item
  where order_item.order_id = new.id;

  perform public.create_notification_once(
    event_type,
    customer_user_id,
    null,
    notification_title,
    pg_catalog.format(
      'Hi %s, order %s %s. Items: %s.',
      customer_name,
      order_reference,
      notification_message,
      item_names
    ),
    pg_catalog.jsonb_build_object(
      'order_id', new.id,
      'customer_id', new.customer_id,
      'customer_name', customer_name,
      'order_reference', order_reference,
      'item_names', item_names,
      'status', new.status
    ),
    new.id::text
  );

  return new;
end;
$$;

-- Notifies the customer when an order is confirmed, preparing, or ready.
create trigger notify_order_status_after_change
after update of status on public.orders
for each row
when (old.status is distinct from new.status)
execute procedure public.notify_order_status_event();

create or replace function public.notify_delivery_status_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  customer_user_id uuid;
  customer_name text;
  customer_id uuid;
  order_reference text;
  item_names text;
  event_type text;
  notification_title text;
  notification_message text;
  order_id uuid;
begin
  if new.status = 'Out for Delivery'::public.delivery_status then
    event_type := 'order_dispatched';
    notification_title := 'Order dispatched';
    notification_message := 'is out for delivery';
  elsif new.status = 'Delivered'::public.delivery_status then
    event_type := 'order_delivered';
    notification_title := 'Order delivered';
    notification_message := 'has been delivered';
  else
    return new;
  end if;

  select
    order_record.id,
    order_record.reference,
    coalesce(customer.id, order_record.customer_id),
    coalesce(customer.name, 'Guest'),
    customer.auth_user_id
  into
    order_id,
    order_reference,
    customer_id,
    customer_name,
    customer_user_id
  from public.orders as order_record
  left join public.customers as customer
    on customer.id = coalesce(new.customer_id, order_record.customer_id)
  where order_record.id = new.order_id;

  if customer_user_id is null then
    return new;
  end if;

  select coalesce(
    pg_catalog.string_agg(
      pg_catalog.format('%s x %s', order_item.quantity, order_item.menu_item_name),
      ', ' order by order_item.created_at, order_item.id
    ),
    'No items'
  )
  into item_names
  from public.order_items as order_item
  where order_item.order_id = order_id;

  perform public.create_notification_once(
    event_type,
    customer_user_id,
    null,
    notification_title,
    pg_catalog.format(
      'Hi %s, order %s %s. Items: %s.',
      customer_name,
      order_reference,
      notification_message,
      item_names
    ),
    pg_catalog.jsonb_build_object(
      'order_id', order_id,
      'customer_id', customer_id,
      'customer_name', customer_name,
      'order_reference', order_reference,
      'item_names', item_names,
      'delivery_status', new.status
    ),
    order_id::text
  );

  return new;
end;
$$;

-- Notifies the customer when a delivery is dispatched or delivered.
create trigger notify_delivery_status_after_change
after update of status on public.deliveries
for each row
when (old.status is distinct from new.status)
execute procedure public.notify_delivery_status_event();

create or replace function public.notify_reservation_requested()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  customer_user_id uuid;
  reservation_payload jsonb;
  reservation_message text;
begin
  select customer.auth_user_id
  into customer_user_id
  from public.customers as customer
  where customer.id = new.customer_id;

  reservation_message := pg_catalog.format(
    'Reservation requested for %s on %s at %s (%s guests).',
    new.customer_name,
    new.reservation_date,
    new.reservation_time,
    new.number_of_guests
  );

  reservation_payload := pg_catalog.jsonb_build_object(
    'reservation_id', new.id,
    'reservation_reference', new.reference,
    'customer_id', new.customer_id,
    'customer_name', new.customer_name,
    'reservation_date', new.reservation_date,
    'reservation_time', new.reservation_time,
    'number_of_guests', new.number_of_guests
  );

  if customer_user_id is not null then
    perform public.create_notification_once(
      'reservation_requested',
      customer_user_id,
      null,
      'Reservation request received',
      pg_catalog.format(
        'Hi %s, %s',
        new.customer_name,
        reservation_message
      ),
      reservation_payload,
      new.id::text
    );
  end if;

  perform public.create_notification_once(
    'reservation_requested',
    null,
    'manager'::public.app_role,
    'New reservation request',
    reservation_message,
    reservation_payload,
    new.id::text
  );

  return new;
end;
$$;

-- Acknowledges requested reservations and alerts manager staff.
create trigger notify_reservation_requested_after_insert
after insert on public.reservations
for each row
when (new.status = 'Requested'::public.reservation_status)
execute procedure public.notify_reservation_requested();

create or replace function public.notify_reservation_confirmed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  customer_user_id uuid;
  customer_name text;
begin
  select customer.auth_user_id, coalesce(customer.name, new.customer_name)
  into customer_user_id, customer_name
  from public.customers as customer
  where customer.id = new.customer_id;

  if customer_user_id is not null then
    perform public.create_notification_once(
      'reservation_confirmed',
      customer_user_id,
      null,
      'Reservation confirmed',
      pg_catalog.format(
        'Hi %s, reservation %s is confirmed for %s at %s.',
        customer_name,
        new.reference,
        new.reservation_date,
        new.reservation_time
      ),
      pg_catalog.jsonb_build_object(
        'reservation_id', new.id,
        'reservation_reference', new.reference,
        'customer_id', new.customer_id,
        'customer_name', customer_name,
        'reservation_date', new.reservation_date,
        'reservation_time', new.reservation_time
      ),
      new.id::text
    );
  end if;

  return new;
end;
$$;

-- Notifies the linked customer after a reservation is confirmed.
create trigger notify_reservation_confirmed_after_update
after update of status on public.reservations
for each row
when (
  old.status is distinct from new.status
  and new.status = 'Confirmed'::public.reservation_status
)
execute procedure public.notify_reservation_confirmed();

create or replace function public.notify_new_complaint()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  customer_name text;
  order_reference text;
begin
  select
    coalesce(customer.name, 'Guest'),
    order_record.reference
  into customer_name, order_reference
  from public.complaints as complaint
  left join public.customers as customer
    on customer.id = complaint.customer_id
  left join public.orders as order_record
    on order_record.id = complaint.order_id
  where complaint.id = new.id;

  perform public.create_notification_once(
    'complaint_received',
    null,
    'support'::public.app_role,
    'New customer complaint',
    pg_catalog.format(
      '%s submitted a %s complaint%s.',
      customer_name,
      new.category,
      case
        when order_reference is null then ''
        else pg_catalog.format(' about order %s', order_reference)
      end
    ),
    pg_catalog.jsonb_build_object(
      'complaint_id', new.id,
      'customer_id', new.customer_id,
      'customer_name', customer_name,
      'order_id', new.order_id,
      'order_reference', order_reference,
      'category', new.category,
      'status', new.status
    ),
    new.id::text
  );

  return new;
end;
$$;

-- Alerts support staff whenever a new complaint is received.
create trigger notify_new_complaint_after_insert
after insert on public.complaints
for each row execute procedure public.notify_new_complaint();

create or replace function public.notify_complaint_resolved()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  customer_user_id uuid;
  customer_name text;
  order_reference text;
begin
  select
    customer.auth_user_id,
    coalesce(customer.name, 'Guest'),
    order_record.reference
  into customer_user_id, customer_name, order_reference
  from public.complaints as complaint
  left join public.customers as customer
    on customer.id = complaint.customer_id
  left join public.orders as order_record
    on order_record.id = complaint.order_id
  where complaint.id = new.id;

  if customer_user_id is not null then
    perform public.create_notification_once(
      'complaint_resolved',
      customer_user_id,
      null,
      'Complaint resolved',
      pg_catalog.format(
        'Hi %s, your complaint%s has been resolved.',
        customer_name,
        case
          when order_reference is null then ''
          else pg_catalog.format(' for order %s', order_reference)
        end
      ),
      pg_catalog.jsonb_build_object(
        'complaint_id', new.id,
        'customer_id', new.customer_id,
        'customer_name', customer_name,
        'order_id', new.order_id,
        'order_reference', order_reference,
        'status', new.status
      ),
      new.id::text
    );
  end if;

  return new;
end;
$$;

-- Notifies the linked customer when their complaint is resolved.
create trigger notify_complaint_resolved_after_update
after update of status on public.complaints
for each row
when (
  old.status is distinct from new.status
  and new.status = 'Resolved'::public.complaint_status
)
execute procedure public.notify_complaint_resolved();

create or replace function public.create_reservation_reminders()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  reminder_window_hours integer;
  reminder_record record;
  reminder_count integer := 0;
  customer_name text;
  notification_created boolean;
begin
  select (setting.value #>> '{}'::text[])::integer
  into reminder_window_hours
  from public.app_settings as setting
  where setting.key = 'reminder_hours';

  if not found or reminder_window_hours is null or reminder_window_hours < 0 then
    raise exception 'app_settings.reminder_hours must contain a non-negative integer';
  end if;

  for reminder_record in
    select
      reservation.id,
      reservation.reference,
      reservation.customer_id,
      reservation.customer_name,
      reservation.reservation_date,
      reservation.reservation_time,
      reservation.number_of_guests,
      customer.auth_user_id,
      customer.name as linked_customer_name
    from public.reservations as reservation
    left join public.customers as customer
      on customer.id = reservation.customer_id
    where reservation.status = 'Confirmed'::public.reservation_status
      and reservation.reservation_date + reservation.reservation_time >= pg_catalog.now()
      and reservation.reservation_date + reservation.reservation_time
        <= pg_catalog.now() + reminder_window_hours * interval '1 hour'
    order by reservation.reservation_date, reservation.reservation_time, reservation.id
  loop
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        'restaurant360:reservation-reminder:' || reminder_record.id::text,
        0
      )
    );

    if exists (
      select 1
      from public.notifications as notification
      where notification.event_type = 'reservation_approaching'
        and notification.payload ->> '_event_key' = reminder_record.id::text
    ) then
      continue;
    end if;

    customer_name := coalesce(
      reminder_record.linked_customer_name,
      reminder_record.customer_name
    );

    if reminder_record.auth_user_id is not null then
      notification_created := public.create_notification_once(
        'reservation_approaching',
        reminder_record.auth_user_id,
        null,
        'Reservation reminder',
        pg_catalog.format(
          'Hi %s, your reservation %s is on %s at %s.',
          customer_name,
          reminder_record.reference,
          reminder_record.reservation_date,
          reminder_record.reservation_time
        ),
        pg_catalog.jsonb_build_object(
          'reservation_id', reminder_record.id,
          'reservation_reference', reminder_record.reference,
          'customer_id', reminder_record.customer_id,
          'customer_name', customer_name,
          'reservation_date', reminder_record.reservation_date,
          'reservation_time', reminder_record.reservation_time,
          'number_of_guests', reminder_record.number_of_guests
        ),
        reminder_record.id::text
      );
    else
      notification_created := public.create_notification_once(
        'reservation_approaching',
        null,
        'manager'::public.app_role,
        'Reservation reminder',
        pg_catalog.format(
          'Reminder: %s has a reservation %s on %s at %s.',
          customer_name,
          reminder_record.reference,
          reminder_record.reservation_date,
          reminder_record.reservation_time
        ),
        pg_catalog.jsonb_build_object(
          'reservation_id', reminder_record.id,
          'reservation_reference', reminder_record.reference,
          'customer_id', reminder_record.customer_id,
          'customer_name', customer_name,
          'reservation_date', reminder_record.reservation_date,
          'reservation_time', reminder_record.reservation_time,
          'number_of_guests', reminder_record.number_of_guests
        ),
        reminder_record.id::text
      );
    end if;

    if notification_created then
      reminder_count := reminder_count + 1;
    end if;
  end loop;

  return reminder_count;
end;
$$;

revoke all on function public.create_reservation_reminders()
from public, anon, authenticated, service_role;
