begin;

set local search_path = '';

create temporary table order_flow_context (
  run_id uuid not null default pg_catalog.gen_random_uuid(),
  customer_uid uuid not null default pg_catalog.gen_random_uuid(),
  manager_uid uuid not null default pg_catalog.gen_random_uuid(),
  customer_id uuid,
  jollof_id uuid,
  unavailable_item_id uuid,
  onion_id uuid,
  regular_order_id uuid,
  cancellation_order_id uuid,
  delivery_order_id uuid,
  verification_delivery_order_id uuid,
  customer_item_inserted boolean not null default false
) on commit drop;

create temporary table order_flow_results (
  check_name text not null,
  result text not null check (result in ('PASS', 'FAIL')),
  detail text
) on commit drop;

create temporary table order_flow_stock_before (
  ingredient_id uuid primary key,
  quantity numeric(12, 3) not null
) on commit drop;

create temporary table cancellation_stock_before (
  ingredient_id uuid primary key,
  quantity numeric(12, 3) not null
) on commit drop;

insert into pg_temp.order_flow_context default values;

grant select, insert, update on pg_temp.order_flow_context to authenticated;
grant insert, select on pg_temp.order_flow_results to authenticated;
grant select, insert, delete on
  pg_temp.order_flow_stock_before,
  pg_temp.cancellation_stock_before
to authenticated;

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
  pg_catalog.jsonb_build_object('full_name', 'Order flow ' || user_record.user_kind)
from pg_temp.order_flow_context as context
cross join lateral (
  values
    ('customer', context.customer_uid),
    ('manager', context.manager_uid)
) as user_record(user_kind, user_id);

update public.profiles as profile
set role = 'manager'::public.app_role
from pg_temp.order_flow_context as context
where profile.id = context.manager_uid;

update pg_temp.order_flow_context as context
set customer_id = customer.id
from public.customers as customer
where customer.auth_user_id = context.customer_uid;

update pg_temp.order_flow_context as context
set jollof_id = item.id
from public.menu_items as item
where item.reference = 'MI-MAIN-001';

update pg_temp.order_flow_context as context
set unavailable_item_id = item.id
from public.menu_items as item
where item.reference = 'MI-DRK-024';

update pg_temp.order_flow_context as context
set onion_id = ingredient.id
from public.ingredients as ingredient
where ingredient.reference = 'ING-045';

set local role authenticated;
select pg_catalog.set_config(
  'request.jwt.claims',
  (
    select pg_catalog.jsonb_build_object(
      'sub', context.customer_uid,
      'role', 'authenticated'
    )::text
    from pg_temp.order_flow_context as context
  ),
  true
);

do $$
declare
  context record;
  customer_order_rows integer := 0;
  customer_item_denied boolean := false;
  customer_item_price numeric(10, 2);
  expected_price numeric(10, 2);
begin
  select * into context from pg_temp.order_flow_context;

  insert into public.orders (
    reference,
    customer_id,
    order_type,
    total,
    status
  )
  values (
    null,
    context.customer_id,
    'takeaway'::public.order_type,
    0,
    'New'::public.order_status
  )
  returning id into context.regular_order_id;
  update pg_temp.order_flow_context
  set regular_order_id = context.regular_order_id;
  customer_order_rows := customer_order_rows + 1;

  insert into public.orders (
    reference,
    customer_id,
    order_type,
    total,
    status
  )
  values (
    null,
    context.customer_id,
    'takeaway'::public.order_type,
    0,
    'New'::public.order_status
  )
  returning id into context.cancellation_order_id;
  update pg_temp.order_flow_context
  set cancellation_order_id = context.cancellation_order_id;
  customer_order_rows := customer_order_rows + 1;

  insert into public.orders (
    reference,
    customer_id,
    order_type,
    total,
    status,
    delivery_address
  )
  values (
    null,
    context.customer_id,
    'delivery'::public.order_type,
    0,
    'New'::public.order_status,
    '1 Sample Street'
  )
  returning id into context.delivery_order_id;
  update pg_temp.order_flow_context
  set delivery_order_id = context.delivery_order_id;
  customer_order_rows := customer_order_rows + 1;

  insert into public.orders (
    reference,
    customer_id,
    order_type,
    total,
    status,
    delivery_address
  )
  values (
    null,
    context.customer_id,
    'delivery'::public.order_type,
    0,
    'New'::public.order_status,
    '2 Sample Street'
  )
  returning id into context.verification_delivery_order_id;
  update pg_temp.order_flow_context
  set verification_delivery_order_id = context.verification_delivery_order_id;
  customer_order_rows := customer_order_rows + 1;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Customer can create own New takeaway and delivery orders',
    case when customer_order_rows = 4 then 'PASS' else 'FAIL' end,
    pg_catalog.format('Customer order rows created: %s', customer_order_rows)
  );

  -- The current policies omit customer order_items inserts; keep that visible as a FAIL.
  select item.price into expected_price
  from public.menu_items as item
  where item.id = context.jollof_id;

  begin
    insert into public.order_items (
      order_id,
      menu_item_id,
      menu_item_name,
      quantity,
      unit_price,
      line_total
    )
    values (
      context.regular_order_id,
      context.jollof_id,
      'Client supplied price',
      2,
      1,
      2
    );
    select order_item.unit_price into customer_item_price
    from public.order_items as order_item
    where order_item.order_id = context.regular_order_id;
    update pg_temp.order_flow_context set customer_item_inserted = true;
  exception when others then
    customer_item_denied := true;
  end;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Customer checkout item insert replaces client-sent price',
    case
      when not customer_item_denied and customer_item_price = expected_price
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'Customer item insert denied: %s; item price: %s; database price: %s',
      customer_item_denied,
      customer_item_price,
      expected_price
    )
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values ('Customer can create own New takeaway and delivery orders', 'FAIL', sqlerrm);
end;
$$;

reset role;
set local role authenticated;
select pg_catalog.set_config(
  'request.jwt.claims',
  (
    select pg_catalog.jsonb_build_object(
      'sub', context.manager_uid,
      'role', 'authenticated'
    )::text
    from pg_temp.order_flow_context as context
  ),
  true
);

do $$
declare
  context record;
begin
  select * into context from pg_temp.order_flow_context;

  if not context.customer_item_inserted then
    insert into public.order_items (
      order_id,
      menu_item_id,
      menu_item_name,
      quantity,
      unit_price,
      line_total
    )
    values (
      context.regular_order_id,
      context.jollof_id,
      'Client supplied price',
      2,
      1,
      2
    );
  end if;

  insert into public.order_items (
    order_id,
    menu_item_id,
    menu_item_name,
    quantity,
    unit_price,
    line_total
  )
  values
    (
      context.cancellation_order_id,
      context.jollof_id,
      'Client supplied price',
      1,
      1,
      1
    ),
    (
      context.delivery_order_id,
      context.jollof_id,
      'Client supplied price',
      1,
      1,
      1
    ),
    (
      context.verification_delivery_order_id,
      context.jollof_id,
      'Client supplied price',
      1,
      1,
      1
    );

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Manager fixture items inserted for downstream checks',
    'PASS',
    'The sample Jollof item was created for each order.'
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values ('Manager fixture items inserted for downstream checks', 'FAIL', sqlerrm);
end;
$$;

do $$
declare
  context record;
  menu_price numeric(10, 2);
  item_price numeric(10, 2);
  order_total numeric(10, 2);
  item_total numeric(10, 2);
begin
  select * into context from pg_temp.order_flow_context;

  select price into menu_price
  from public.menu_items
  where id = context.jollof_id;

  select unit_price, line_total into item_price, item_total
  from public.order_items
  where order_id = context.regular_order_id;

  select total into order_total
  from public.orders
  where id = context.regular_order_id;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Database replaces a client-sent price with menu price',
    case when item_price = menu_price then 'PASS' else 'FAIL' end,
    pg_catalog.format('Stored item price: %s; menu price: %s', item_price, menu_price)
  );

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Order total equals the sum of its items',
    case when order_total = item_total then 'PASS' else 'FAIL' end,
    pg_catalog.format('Order total: %s; item sum: %s', order_total, item_total)
  );

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Generated order reference matches R360-YYYYMMDD-NNNN',
    case
      when (
        select reference ~ '^R360-[0-9]{8}-[0-9]{4}$'
        from public.orders
        where id = context.regular_order_id
      ) then 'PASS'
      else 'FAIL'
    end,
    (
      select reference
      from public.orders
      where id = context.regular_order_id
    )
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values ('Database replaces client-sent price with menu price', 'FAIL', sqlerrm);
end;
$$;

do $$
declare
  context record;
  resulting_status public.order_status;
begin
  select * into context from pg_temp.order_flow_context;

  begin
    update public.orders
    set status = 'Completed'::public.order_status
    where id = context.regular_order_id;
  exception when others then
    null;
  end;

  select status into resulting_status
  from public.orders
  where id = context.regular_order_id;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'New to Completed transition is rejected',
    case when resulting_status = 'New'::public.order_status then 'PASS' else 'FAIL' end,
    pg_catalog.format('Order remains %s', resulting_status)
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values ('New to Completed transition is rejected', 'FAIL', sqlerrm);
end;
$$;

do $$
declare
  context record;
  record_count integer;
begin
  select * into context from pg_temp.order_flow_context;

  insert into pg_temp.order_flow_stock_before (ingredient_id, quantity)
  select ingredient.id, ingredient.quantity
  from public.ingredients as ingredient
  join public.recipes as recipe
    on recipe.ingredient_id = ingredient.id
  where recipe.menu_item_id = context.jollof_id;

  update public.orders
  set status = 'Confirmed'::public.order_status
  where id = context.regular_order_id;

  select pg_catalog.count(*) into record_count
  from public.stock_movements as movement
  where movement.order_id = context.regular_order_id
    and movement.movement_type = 'Used'::public.stock_movement_type
    and movement.notes = 'Order confirmation stock deduction';

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Confirming order deducts recipe quantities and writes movements',
    case
      when record_count = (
        select pg_catalog.count(*) from pg_temp.order_flow_stock_before
      )
      and not exists (
        select 1
        from public.recipes as recipe
        join public.order_items as order_item
          on order_item.menu_item_id = recipe.menu_item_id
        join public.stock_movements as movement
          on movement.order_id = order_item.order_id
         and movement.ingredient_id = recipe.ingredient_id
         and movement.movement_type = 'Used'::public.stock_movement_type
         and movement.notes = 'Order confirmation stock deduction'
        join pg_temp.order_flow_stock_before as before_stock
          on before_stock.ingredient_id = recipe.ingredient_id
        join public.ingredients as ingredient
          on ingredient.id = recipe.ingredient_id
        where order_item.order_id = context.regular_order_id
          and (
            before_stock.quantity - ingredient.quantity
              <> recipe.quantity_required * order_item.quantity
            or movement.quantity
              <> recipe.quantity_required * order_item.quantity
            or movement.quantity_before - movement.quantity_after
              <> movement.quantity
          )
      ) then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format('Stock movement rows: %s', record_count)
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Confirming order deducts recipe quantities and writes movements',
    'FAIL',
    sqlerrm
  );
end;
$$;

do $$
declare
  context record;
  transition_count integer;
begin
  select * into context from pg_temp.order_flow_context;

  update public.orders
  set status = 'Preparing'::public.order_status
  where id = context.regular_order_id;

  update public.orders
  set status = 'Ready for Collection'::public.order_status
  where id = context.regular_order_id;

  update public.orders
  set status = 'Completed'::public.order_status
  where id = context.regular_order_id;

  select pg_catalog.count(*) into transition_count
  from public.order_status_log
  where order_id = context.regular_order_id;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Confirmed to Preparing to Ready to Completed is logged',
    case
      when transition_count = 4
        and (
          select status = 'Completed'::public.order_status
          from public.orders
          where id = context.regular_order_id
        ) then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format('Status log rows: %s', transition_count)
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Confirmed to Preparing to Ready to Completed is logged',
    'FAIL',
    sqlerrm
  );
end;
$$;

do $$
declare
  context record;
  expected_movements integer;
  adjustment_count integer;
  restoration_exact boolean;
begin
  select * into context from pg_temp.order_flow_context;

  delete from pg_temp.cancellation_stock_before;
  insert into pg_temp.cancellation_stock_before (ingredient_id, quantity)
  select ingredient.id, ingredient.quantity
  from public.ingredients as ingredient
  join public.recipes as recipe
    on recipe.ingredient_id = ingredient.id
  where recipe.menu_item_id = context.jollof_id;

  update public.orders
  set status = 'Confirmed'::public.order_status
  where id = context.cancellation_order_id;

  update public.orders
  set status = 'Cancelled'::public.order_status
  where id = context.cancellation_order_id;

  select pg_catalog.count(*) into expected_movements
  from pg_temp.cancellation_stock_before;

  select pg_catalog.count(*) into adjustment_count
  from public.stock_movements as movement
  where movement.order_id = context.cancellation_order_id
    and movement.movement_type = 'Adjustment'::public.stock_movement_type
    and movement.notes = 'Order cancellation stock reversal';

  select not exists (
    select 1
    from pg_temp.cancellation_stock_before as before_stock
    join public.ingredients as ingredient
      on ingredient.id = before_stock.ingredient_id
    where ingredient.quantity <> before_stock.quantity
  )
  into restoration_exact;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Cancelling Confirmed order restores stock exactly once',
    case
      when restoration_exact and adjustment_count = expected_movements
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'Restored exactly: %s; adjustment rows: %s; expected: %s',
      restoration_exact,
      adjustment_count,
      expected_movements
    )
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values ('Cancelling Confirmed order restores stock exactly once', 'FAIL', sqlerrm);
end;
$$;

do $$
declare
  context record;
  resulting_status public.order_status;
  payment_id uuid;
  delivery_status public.delivery_status;
begin
  select * into context from pg_temp.order_flow_context;

  begin
    update public.orders
    set status = 'Confirmed'::public.order_status
    where id = context.delivery_order_id;
  exception when others then
    null;
  end;

  select status into resulting_status
  from public.orders
  where id = context.delivery_order_id;

  select status into delivery_status
  from public.deliveries
  where order_id = context.delivery_order_id;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Delivery order requires eligible payment and starts Awaiting Assignment',
    case
      when resulting_status = 'New'::public.order_status
        and delivery_status = 'Awaiting Assignment'::public.delivery_status
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'Order status: %s; delivery status: %s',
      resulting_status,
      delivery_status
    )
  );

  insert into public.payments (
    order_id,
    customer_id,
    expected_amount,
    amount_recorded,
    status
  )
  values (
    context.delivery_order_id,
    context.customer_id,
    (
      select total from public.orders where id = context.delivery_order_id
    ),
    (
      select total from public.orders where id = context.delivery_order_id
    ),
    'Paid'::public.payment_status
  )
  returning id into payment_id;

  update public.orders
  set status = 'Confirmed'::public.order_status
  where id = context.delivery_order_id;

  select status into resulting_status
  from public.orders
  where id = context.delivery_order_id;

  select status into delivery_status
  from public.deliveries
  where order_id = context.delivery_order_id;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Paid delivery order can be confirmed',
    case
      when payment_id is not null
        and resulting_status = 'Confirmed'::public.order_status
        and delivery_status = 'Awaiting Assignment'::public.delivery_status
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'Payment %s; order status: %s; delivery status: %s',
      payment_id,
      resulting_status,
      delivery_status
    )
  );

  insert into public.payments (
    order_id,
    customer_id,
    expected_amount,
    amount_recorded,
    status
  )
  values (
    context.verification_delivery_order_id,
    context.customer_id,
    (
      select total from public.orders where id = context.verification_delivery_order_id
    ),
    0,
    'Awaiting Verification'::public.payment_status
  )
  returning id into payment_id;

  update public.orders
  set status = 'Confirmed'::public.order_status
  where id = context.verification_delivery_order_id;

  select status into resulting_status
  from public.orders
  where id = context.verification_delivery_order_id;

  select status into delivery_status
  from public.deliveries
  where order_id = context.verification_delivery_order_id;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Awaiting Verification delivery payment permits confirmation',
    case
      when payment_id is not null
        and resulting_status = 'Confirmed'::public.order_status
        and delivery_status = 'Awaiting Assignment'::public.delivery_status
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'Payment %s; order status: %s; delivery status: %s',
      payment_id,
      resulting_status,
      delivery_status
    )
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Delivery order requires eligible payment and starts Awaiting Assignment',
    'FAIL',
    sqlerrm
  );
end;
$$;

do $$
declare
  context record;
  insert_denied boolean := false;
  item_count bigint;
begin
  select * into context from pg_temp.order_flow_context;

  begin
    insert into public.order_items (
      order_id,
      menu_item_id,
      menu_item_name,
      quantity,
      unit_price,
      line_total
    )
    values (
      context.regular_order_id,
      context.unavailable_item_id,
      'Unavailable item',
      1,
      1,
      1
    );
  exception when others then
    insert_denied := true;
  end;

  select pg_catalog.count(*) into item_count
  from public.order_items
  where order_id = context.regular_order_id
    and menu_item_id = context.unavailable_item_id;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Unavailable menu item cannot be ordered',
    case when insert_denied and item_count = 0 then 'PASS' else 'FAIL' end,
    pg_catalog.format('Insert rejected: %s; matching order items: %s', insert_denied, item_count)
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values ('Unavailable menu item cannot be ordered', 'FAIL', sqlerrm);
end;
$$;

do $$
declare
  context record;
  notifications_before bigint;
  notifications_after bigint;
  kitchen_count bigint;
  manager_count bigint;
begin
  select * into context from pg_temp.order_flow_context;

  select pg_catalog.count(*) into notifications_before
  from public.notifications
  where event_type = 'ingredient_stock_low'
    and payload ->> 'ingredient_id' = context.onion_id::text;

  update public.ingredients
  set quantity = minimum_level
  where id = context.onion_id;

  update public.ingredients
  set quantity = minimum_level
  where id = context.onion_id;

  select
    pg_catalog.count(*) filter (
      where recipient_role = 'kitchen'::public.app_role
    ),
    pg_catalog.count(*) filter (
      where recipient_role = 'manager'::public.app_role
    ),
    pg_catalog.count(*)
  into kitchen_count, manager_count, notifications_after
  from public.notifications
  where event_type = 'ingredient_stock_low'
    and payload ->> 'ingredient_id' = context.onion_id::text;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Minimum stock creates one notification per intended staff role',
    case
      when notifications_after - notifications_before = 2
        and kitchen_count = 1
        and manager_count = 1
        then 'PASS'
      else 'FAIL'
    end,
    pg_catalog.format(
      'New alerts: %s; kitchen: %s; manager: %s',
      notifications_after - notifications_before,
      kitchen_count,
      manager_count
    )
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Minimum stock creates one notification per intended staff role',
    'FAIL',
    sqlerrm
  );
end;
$$;

do $$
declare
  context record;
  notifications_present boolean;
  missing_events text;
begin
  select * into context from pg_temp.order_flow_context;

  select string_agg(required.event_description, ', ')
  into missing_events
  from (
    values
      ('order_submitted', context.customer_uid, null::public.app_role, 'customer order_submitted'),
      ('order_submitted', null::uuid, 'kitchen'::public.app_role, 'kitchen order_submitted'),
      ('order_submitted', null::uuid, 'manager'::public.app_role, 'manager order_submitted'),
      ('order_confirmed', context.customer_uid, null::public.app_role, 'customer order_confirmed'),
      ('order_preparing', context.customer_uid, null::public.app_role, 'customer order_preparing'),
      ('order_ready', context.customer_uid, null::public.app_role, 'customer order_ready'),
      ('order_submitted', context.customer_uid, null::public.app_role, 'delivery customer order_submitted'),
      ('order_submitted', null::uuid, 'kitchen'::public.app_role, 'delivery kitchen order_submitted'),
      ('order_submitted', null::uuid, 'manager'::public.app_role, 'delivery manager order_submitted'),
      ('order_confirmed', context.customer_uid, null::public.app_role, 'delivery customer order_confirmed'),
      ('order_submitted', context.customer_uid, null::public.app_role, 'verification customer order_submitted'),
      ('order_submitted', null::uuid, 'kitchen'::public.app_role, 'verification kitchen order_submitted'),
      ('order_submitted', null::uuid, 'manager'::public.app_role, 'verification manager order_submitted'),
      ('order_confirmed', context.customer_uid, null::public.app_role, 'verification customer order_confirmed')
  ) as required(event_type, recipient_user_id, recipient_role, event_description)
  where not exists (
    select 1
    from public.notifications as notification
    where notification.event_type = required.event_type
      and notification.recipient_user_id
        is not distinct from required.recipient_user_id
      and notification.recipient_role
        is not distinct from required.recipient_role
      and notification.payload ->> 'order_id' = case
        when required.event_description like 'delivery %'
          then context.delivery_order_id::text
        when required.event_description like 'verification %'
          then context.verification_delivery_order_id::text
        else context.regular_order_id::text
      end
  );

  notifications_present := missing_events is null;

  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Order submit, confirm, prepare, and ready notifications exist',
    case when notifications_present then 'PASS' else 'FAIL' end,
    coalesce(missing_events, 'All expected notifications exist.')
  );
exception when others then
  insert into pg_temp.order_flow_results (check_name, result, detail)
  values (
    'Order submit, confirm, prepare, and ready notifications exist',
    'FAIL',
    sqlerrm
  );
end;
$$;

select report.check_name, report.result, report.detail
from (
  select
    result.check_name,
    result.result,
    result.detail,
    0 as sort_order
  from pg_temp.order_flow_results as result

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
  from pg_temp.order_flow_results as result
) as report
order by report.sort_order, report.check_name;

rollback;
