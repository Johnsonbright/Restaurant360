begin;

set local search_path = '';

create temporary table rls_check_context (
  run_id uuid not null default pg_catalog.gen_random_uuid(),
  customer_uid uuid not null default pg_catalog.gen_random_uuid(),
  other_customer_uid uuid not null default pg_catalog.gen_random_uuid(),
  kitchen_uid uuid not null default pg_catalog.gen_random_uuid(),
  customer_id uuid,
  other_customer_id uuid,
  own_order_id uuid,
  total_order_id uuid,
  other_order_id uuid,
  menu_item_id uuid,
  menu_price_before numeric(10, 2),
  order_total_before numeric(10, 2),
  item_price_before numeric(10, 2)
) on commit drop;

create temporary table rls_check_results (
  check_name text not null,
  result text not null check (result in ('PASS', 'FAIL')),
  detail text
) on commit drop;

insert into pg_temp.rls_check_context default values;

grant select, insert, update on pg_temp.rls_check_context to anon, authenticated;
grant insert, select on pg_temp.rls_check_results to anon, authenticated;

insert into auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data
)
select
  user_record.user_id,
  'authenticated',
  'authenticated',
  context.run_id::text || '-' || user_record.user_kind || '@example.test',
  '',
  pg_catalog.now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  pg_catalog.jsonb_build_object('full_name', 'RLS check ' || user_record.user_kind)
from pg_temp.rls_check_context as context
cross join (
  values
    ('customer', (select customer_uid from pg_temp.rls_check_context)),
    ('other', (select other_customer_uid from pg_temp.rls_check_context)),
    ('kitchen', (select kitchen_uid from pg_temp.rls_check_context))
) as user_record(user_kind, user_id);

update public.profiles as profile
set role = 'kitchen'::public.app_role
from pg_temp.rls_check_context as context
where profile.id = context.kitchen_uid;

update pg_temp.rls_check_context as context
set customer_id = customer.id
from public.customers as customer
where customer.auth_user_id = context.customer_uid;

update pg_temp.rls_check_context as context
set other_customer_id = customer.id
from public.customers as customer
where customer.auth_user_id = context.other_customer_uid;

with new_order as (
  insert into public.orders (
    reference,
    customer_id,
    order_type,
    total,
    status
  )
  select null, context.customer_id, 'takeaway'::public.order_type, 0,
         'New'::public.order_status
  from pg_temp.rls_check_context as context
  returning id, customer_id
)
update pg_temp.rls_check_context as context
set own_order_id = new_order.id
from new_order
where new_order.customer_id = context.customer_id;

with new_order as (
  insert into public.orders (
    reference,
    customer_id,
    order_type,
    total,
    status
  )
  select null, context.customer_id, 'takeaway'::public.order_type, 0,
         'New'::public.order_status
  from pg_temp.rls_check_context as context
  returning id, customer_id
)
update pg_temp.rls_check_context as context
set total_order_id = new_order.id
from new_order
where new_order.customer_id = context.customer_id;

with new_order as (
  insert into public.orders (
    reference,
    customer_id,
    order_type,
    total,
    status
  )
  select null, context.other_customer_id, 'takeaway'::public.order_type, 0,
         'New'::public.order_status
  from pg_temp.rls_check_context as context
  returning id, customer_id
)
update pg_temp.rls_check_context as context
set other_order_id = new_order.id
from new_order
where new_order.customer_id = context.other_customer_id;

update pg_temp.rls_check_context as context
set menu_item_id = item.id
from public.menu_items as item
where item.reference = 'MI-MAIN-001';

insert into public.order_items (
  order_id,
  menu_item_id,
  menu_item_name,
  quantity,
  unit_price,
  line_total
)
select
  context.own_order_id,
  context.menu_item_id,
  'client supplied name',
  1,
  1,
  1
from pg_temp.rls_check_context as context;

update pg_temp.rls_check_context as context
set menu_price_before = item.price,
    item_price_before = order_item.unit_price
from public.menu_items as item
join public.order_items as order_item on order_item.menu_item_id = item.id
where item.id = context.menu_item_id
  and order_item.order_id = context.own_order_id;

update pg_temp.rls_check_context as context
set order_total_before = order_record.total
from public.orders as order_record
where order_record.id = context.total_order_id;

insert into public.payments (
  order_id,
  customer_id,
  expected_amount,
  amount_recorded
)
select context.own_order_id, context.customer_id, 1, 0
from pg_temp.rls_check_context as context;

set local role authenticated;
select pg_catalog.set_config(
  'request.jwt.claims',
  (
    select pg_catalog.jsonb_build_object(
      'sub', context.customer_uid,
      'role', 'authenticated'
    )::text
    from pg_temp.rls_check_context as context
  ),
  true
);

do $$
declare
  visible_count bigint;
begin
  select pg_catalog.count(*)
  into visible_count
  from public.orders as order_record
  cross join pg_temp.rls_check_context as context
  where order_record.id = context.other_order_id;

  insert into pg_temp.rls_check_results (check_name, result, detail)
  values (
    'Customer cannot read another customer order',
    case when visible_count = 0 then 'PASS' else 'FAIL' end,
    pg_catalog.format('Visible rows: %s', visible_count)
  );
exception when others then
  insert into pg_temp.rls_check_results (check_name, result, detail)
  values ('Customer cannot read another customer order', 'FAIL', sqlerrm);
end;
$$;

do $$
declare
  context record;
  resulting_status public.order_status;
  cancel_count integer;
  other_cancel_count integer;
begin
  select * into context from pg_temp.rls_check_context;

  begin
    update public.orders
    set status = 'Confirmed'::public.order_status
    where id = context.own_order_id;
  exception when insufficient_privilege or raise_exception then
    null;
  end;

  select status into resulting_status
  from public.orders
  where id = context.own_order_id;

  begin
    update public.orders
    set status = 'Cancelled'::public.order_status
    where id = context.other_order_id;
  exception when insufficient_privilege or raise_exception then
    null;
  end;
  get diagnostics other_cancel_count = row_count;

  update public.orders
  set status = 'Cancelled'::public.order_status
  where id = context.own_order_id;
  get diagnostics cancel_count = row_count;

  insert into pg_temp.rls_check_results (check_name, result, detail)
  values (
    'Customer may only cancel own New order',
    case
      when resulting_status = 'New'::public.order_status
        and other_cancel_count = 0
        and cancel_count = 1
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'Non-cancel status remained %s; other-order cancellation rows: %s; own cancellation rows: %s',
      resulting_status,
      other_cancel_count,
      cancel_count
    )
  );
exception when others then
  insert into pg_temp.rls_check_results (check_name, result, detail)
  values ('Customer may only cancel own New order', 'FAIL', sqlerrm);
end;
$$;

do $$
declare
  context record;
  menu_price numeric(10, 2);
  order_total numeric(10, 2);
  item_price numeric(10, 2);
  profile_role public.app_role;
begin
  select * into context from pg_temp.rls_check_context;

  begin
    update public.menu_items
    set price = price + 100
    where id = context.menu_item_id;
  exception when insufficient_privilege then
    null;
  end;

  begin
    update public.orders
    set total = total + 100
    where id = context.total_order_id;
  exception when insufficient_privilege then
    null;
  end;

  begin
    update public.order_items
    set unit_price = unit_price + 100
    where order_id = context.own_order_id;
  exception when insufficient_privilege then
    null;
  end;

  begin
    update public.profiles
    set role = 'admin'::public.app_role
    where id = context.customer_uid;
  exception when insufficient_privilege then
    null;
  end;

  select price into menu_price from public.menu_items where id = context.menu_item_id;
  select total into order_total from public.orders where id = context.total_order_id;
  select unit_price into item_price
  from public.order_items
  where order_id = context.own_order_id;
  select role into profile_role
  from public.profiles
  where id = context.customer_uid;

  insert into pg_temp.rls_check_results (check_name, result, detail)
  values (
    'Customer cannot change price, total, or role',
    case
      when menu_price = context.menu_price_before
      and order_total = context.order_total_before
      and item_price = context.item_price_before
      and profile_role = 'customer'::public.app_role
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'Menu price %s; order total %s; line price %s; profile role %s',
      menu_price,
      order_total,
      item_price,
      profile_role
    )
  );
exception when others then
  insert into pg_temp.rls_check_results (check_name, result, detail)
  values ('Customer cannot change price, total, or role', 'FAIL', sqlerrm);
end;
$$;

reset role;
set local role anon;
select pg_catalog.set_config('request.jwt.claims', '{"role":"anon"}', true);

do $$
declare
  available_count bigint;
  inserted_count integer;
  visible_order_count bigint;
begin
  select pg_catalog.count(*)
  into available_count
  from public.menu_items
  where is_available;

  insert into public.reservations (
    customer_id,
    customer_name,
    customer_email,
    customer_phone,
    reservation_date,
    reservation_time,
    number_of_guests,
    status
  )
  values (
    null,
    'RLS test guest',
    'guest-' || pg_catalog.gen_random_uuid()::text || '@example.test',
    '0000000000',
    current_date + 7,
    time '18:00',
    2,
    'Requested'::public.reservation_status
  );
  get diagnostics inserted_count = row_count;

  select pg_catalog.count(*)
  into visible_order_count
  from public.orders;

  insert into pg_temp.rls_check_results (check_name, result, detail)
  values (
    'Anonymous reads available menu, inserts reservation, cannot read orders',
    case
      when available_count > 0
        and inserted_count = 1
        and visible_order_count = 0
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'Available items: %s; reservations inserted: %s; visible orders: %s',
      available_count,
      inserted_count,
      visible_order_count
    )
  );
exception when others then
  insert into pg_temp.rls_check_results (check_name, result, detail)
  values (
    'Anonymous reads available menu, inserts reservation, cannot read orders',
    'FAIL',
    sqlerrm
  );
end;
$$;

reset role;
set local role authenticated;
select pg_catalog.set_config(
  'request.jwt.claims',
  (
    select pg_catalog.jsonb_build_object(
      'sub', context.kitchen_uid,
      'role', 'authenticated'
    )::text
    from pg_temp.rls_check_context as context
  ),
  true
);

do $$
declare
  visible_count bigint;
begin
  select pg_catalog.count(*) into visible_count
  from public.payments;

  insert into pg_temp.rls_check_results (check_name, result, detail)
  values (
    'Kitchen cannot read payments',
    case when visible_count = 0 then 'PASS' else 'FAIL' end,
    pg_catalog.format('Visible payment rows: %s', visible_count)
  );
exception when others then
  insert into pg_temp.rls_check_results (check_name, result, detail)
  values ('Kitchen cannot read payments', 'FAIL', sqlerrm);
end;
$$;

reset role;
set local role authenticated;
select pg_catalog.set_config(
  'request.jwt.claims',
  (
    select pg_catalog.jsonb_build_object(
      'sub', context.customer_uid,
      'role', 'authenticated'
    )::text
    from pg_temp.rls_check_context as context
  ),
  true
);

do $$
declare
  notification_insert_denied boolean := false;
begin
  begin
    insert into public.notifications (
      recipient_user_id,
      event_type,
      title,
      message
    )
    select
      context.customer_uid,
      'rls_test',
      'RLS test',
      'This row must not be inserted by a customer.'
    from pg_temp.rls_check_context as context;
  exception when insufficient_privilege then
    notification_insert_denied := true;
  end;

  insert into pg_temp.rls_check_results (check_name, result, detail)
  values (
    'Customer cannot insert a notification',
    case when notification_insert_denied then 'PASS' else 'FAIL' end,
    pg_catalog.format('Notification insert denied: %s', notification_insert_denied)
  );
exception when others then
  insert into pg_temp.rls_check_results (check_name, result, detail)
  values ('Customer cannot insert a notification', 'FAIL', sqlerrm);
end;
$$;

reset role;

select report.check_name, report.result, report.detail
from (
  select
    result.check_name,
    result.result,
    result.detail,
    0 as sort_order
  from pg_temp.rls_check_results as result

  union all

  select
    'TOTAL' as check_name,
    case
      when pg_catalog.count(*) filter (where result.result = 'FAIL') = 0
        then 'PASS'
      else 'FAIL'
    end as result,
    pg_catalog.format(
      '%s PASS; %s FAIL',
      pg_catalog.count(*) filter (where result.result = 'PASS'),
      pg_catalog.count(*) filter (where result.result = 'FAIL')
    ) as detail,
    1 as sort_order
  from pg_temp.rls_check_results as result
) as report
order by report.sort_order, report.check_name;

rollback;
