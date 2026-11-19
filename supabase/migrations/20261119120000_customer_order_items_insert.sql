create policy order_items_customer_insert_own_new
on public.order_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.orders as order_record
    join public.customers as customer
      on customer.id = order_record.customer_id
    where order_record.id = order_items.order_id
      and order_record.status = 'New'::public.order_status
      and customer.auth_user_id = (select auth.uid())
  )
);
