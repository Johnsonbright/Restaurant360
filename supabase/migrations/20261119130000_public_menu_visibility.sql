create policy menu_items_public_read_active_categories
on public.menu_items
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.categories as category
    where category.id = menu_items.category_id
      and category.is_active
  )
);
