-- Summarizes completed orders by creation date and recorded payment amounts.
create or replace view public.daily_sales
with (security_invoker = true)
as
with payment_totals as (
  select payment.order_id, pg_catalog.sum(payment.amount_recorded) as amount_recorded
  from public.payments as payment
  group by payment.order_id
)
select
  order_record.created_at::date as sale_date,
  pg_catalog.count(*) as completed_orders,
  coalesce(pg_catalog.sum(payment_totals.amount_recorded), 0)::numeric(12, 2)
    as amount_recorded,
  coalesce(pg_catalog.sum(order_record.total), 0)::numeric(12, 2)
    as completed_order_total
from public.orders as order_record
left join payment_totals
  on payment_totals.order_id = order_record.id
where order_record.status = 'Completed'::public.order_status
group by order_record.created_at::date;

comment on view public.daily_sales is
  'Columns: sale_date is the order creation date; completed_orders counts only Completed orders; amount_recorded sums payments.amount_recorded for those orders; completed_order_total sums their order totals.';

-- Summarizes completed orders by creation month and recorded payment amounts.
create or replace view public.monthly_sales
with (security_invoker = true)
as
with payment_totals as (
  select payment.order_id, pg_catalog.sum(payment.amount_recorded) as amount_recorded
  from public.payments as payment
  group by payment.order_id
)
select
  pg_catalog.date_trunc('month', order_record.created_at)::date as sale_month,
  pg_catalog.count(*) as completed_orders,
  coalesce(pg_catalog.sum(payment_totals.amount_recorded), 0)::numeric(12, 2)
    as amount_recorded,
  coalesce(pg_catalog.sum(order_record.total), 0)::numeric(12, 2)
    as completed_order_total
from public.orders as order_record
left join payment_totals
  on payment_totals.order_id = order_record.id
where order_record.status = 'Completed'::public.order_status
group by pg_catalog.date_trunc('month', order_record.created_at)::date;

comment on view public.monthly_sales is
  'Columns: sale_month is the first date of the order creation month; completed_orders counts only Completed orders; amount_recorded sums payments.amount_recorded for those orders; completed_order_total sums their order totals.';

-- Reports completed item sales by menu item, including items with no sales.
create or replace view public.menu_performance
with (security_invoker = true)
as
select
  item.id as menu_item_id,
  item.reference as menu_item_reference,
  item.name as menu_item_name,
  category.name as category_name,
  coalesce(pg_catalog.sum(sales.quantity), 0)::bigint as quantity_sold,
  pg_catalog.count(distinct sales.order_id) as completed_orders,
  coalesce(pg_catalog.sum(sales.line_total), 0)::numeric(12, 2)
    as completed_sales
from public.menu_items as item
join public.categories as category
  on category.id = item.category_id
left join (
  select
    order_item.menu_item_id,
    order_item.order_id,
    order_item.quantity,
    order_item.line_total
  from public.order_items as order_item
  join public.orders as order_record
    on order_record.id = order_item.order_id
  where order_record.status = 'Completed'::public.order_status
) as sales
  on sales.menu_item_id = item.id
group by item.id, item.reference, item.name, category.name;

comment on view public.menu_performance is
  'Columns: menu_item_id, menu_item_reference, menu_item_name, and category_name identify the item; quantity_sold sums its quantities on Completed orders; completed_orders counts distinct Completed orders containing it; completed_sales sums order_items.line_total for those orders.';

-- Shows current ingredient quantities, minimums, expiry and supplier.
create or replace view public.stock_summary
with (security_invoker = true)
as
select
  ingredient.id as ingredient_id,
  ingredient.reference as ingredient_reference,
  ingredient.name as ingredient_name,
  ingredient.unit,
  ingredient.quantity,
  ingredient.minimum_level,
  (ingredient.quantity <= ingredient.minimum_level) as is_low_stock,
  ingredient.expiry_date,
  ingredient.supplier_id,
  supplier.name as supplier_name
from public.ingredients as ingredient
left join public.suppliers as supplier
  on supplier.id = ingredient.supplier_id;

comment on view public.stock_summary is
  'Columns: ingredient_id, ingredient_reference, ingredient_name and unit identify the ingredient; quantity and minimum_level show stock; is_low_stock indicates quantity at or below minimum_level; expiry_date and supplier_id/supplier_name show expiry and supplier details.';

-- Calculates kitchen preparation durations from existing order timestamps.
create or replace view public.order_processing_times
with (security_invoker = true)
as
select
  order_record.id as order_id,
  order_record.reference as order_reference,
  order_record.status,
  order_record.order_type,
  order_record.created_at as order_created_at,
  kitchen_record.preparation_started_at,
  kitchen_record.ready_at,
  case
    when kitchen_record.preparation_started_at is null then null
    else pg_catalog.round(
      extract(
        epoch from kitchen_record.preparation_started_at - order_record.created_at
      ) / 60.0,
      2
    )
  end as minutes_to_preparation,
  case
    when kitchen_record.preparation_started_at is null
      or kitchen_record.ready_at is null then null
    else pg_catalog.round(
      extract(
        epoch from kitchen_record.ready_at - kitchen_record.preparation_started_at
      ) / 60.0,
      2
    )
  end as minutes_in_preparation,
  case
    when kitchen_record.ready_at is null then null
    else pg_catalog.round(
      extract(epoch from kitchen_record.ready_at - order_record.created_at)
        / 60.0,
      2
    )
  end as minutes_to_ready
from public.orders as order_record
left join public.kitchen_records as kitchen_record
  on kitchen_record.order_id = order_record.id;

comment on view public.order_processing_times is
  'Columns: order_id, order_reference, status and order_type identify the order; order_created_at, preparation_started_at and ready_at are source timestamps; minutes_to_preparation, minutes_in_preparation and minutes_to_ready are elapsed minutes when their timestamps exist.';

-- Reports delivery status and elapsed/expected delivery performance.
create or replace view public.delivery_performance
with (security_invoker = true)
as
select
  delivery.id as delivery_id,
  delivery.order_id,
  order_record.reference as order_reference,
  delivery.status,
  delivery.dispatch_date,
  delivery.expected_delivery_at,
  delivery.delivered_at,
  case
    when delivery.dispatch_date is null or delivery.delivered_at is null then null
    else pg_catalog.round(
      extract(epoch from delivery.delivered_at - delivery.dispatch_date)
        / 60.0,
      2
    )
  end as minutes_out_for_delivery,
  case
    when delivery.delivered_at is null or delivery.expected_delivery_at is null then null
    else delivery.delivered_at <= delivery.expected_delivery_at
  end as delivered_on_time
from public.deliveries as delivery
join public.orders as order_record
  on order_record.id = delivery.order_id;

comment on view public.delivery_performance is
  'Columns: delivery_id, order_id and order_reference identify the order delivery; status, dispatch_date, expected_delivery_at and delivered_at describe its state and timestamps; minutes_out_for_delivery is elapsed dispatch-to-delivery time; delivered_on_time compares actual and expected timestamps when both exist.';

-- Counts reservations and guests by requested date and booking status.
create or replace view public.reservation_summary
with (security_invoker = true)
as
select
  reservation.reservation_date,
  reservation.status,
  pg_catalog.count(*) as reservation_count,
  pg_catalog.sum(reservation.number_of_guests)::bigint as guest_count
from public.reservations as reservation
group by reservation.reservation_date, reservation.status;

comment on view public.reservation_summary is
  'Columns: reservation_date and status group reservations; reservation_count counts bookings in each group; guest_count sums number_of_guests in each group.';

-- Summarizes feedback volume and ratings by submission date.
create or replace view public.feedback_summary
with (security_invoker = true)
as
select
  feedback.created_at::date as feedback_date,
  pg_catalog.count(*) as feedback_count,
  pg_catalog.round(pg_catalog.avg(feedback.rating)::numeric, 2) as average_rating,
  pg_catalog.count(*) filter (where feedback.comments is not null) as comments_count,
  pg_catalog.count(*) filter (where feedback.suggestions is not null)
    as suggestions_count
from public.feedback as feedback
group by feedback.created_at::date;

comment on view public.feedback_summary is
  'Columns: feedback_date is the submission date; feedback_count counts records; average_rating averages rating; comments_count and suggestions_count count rows containing comments or suggestions.';

grant select on
  public.daily_sales,
  public.monthly_sales,
  public.menu_performance,
  public.stock_summary,
  public.order_processing_times,
  public.delivery_performance,
  public.reservation_summary,
  public.feedback_summary
to authenticated;
