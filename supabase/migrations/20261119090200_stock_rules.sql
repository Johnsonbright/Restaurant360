alter table public.ingredients
add column low_stock_notified boolean not null default false;

create unique index stock_movements_order_deduction_once_idx
on public.stock_movements (order_id, ingredient_id)
where order_id is not null
  and movement_type = 'Used'::public.stock_movement_type
  and notes = 'Order confirmation stock deduction';

create unique index stock_movements_order_reversal_once_idx
on public.stock_movements (order_id, ingredient_id)
where order_id is not null
  and movement_type = 'Adjustment'::public.stock_movement_type
  and notes = 'Order cancellation stock reversal';

create or replace function public.apply_order_stock_rules()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  ingredient_requirement record;
  quantity_after numeric(12, 3);
  ingredient_name text;
  available_quantity numeric(12, 3);
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  if new.status = 'Confirmed'::public.order_status then
    if exists (
      select 1
      from public.stock_movements as movement
      where movement.order_id = new.id
        and movement.movement_type = 'Used'::public.stock_movement_type
        and movement.notes = 'Order confirmation stock deduction'
    ) then
      return new;
    end if;

    for ingredient_requirement in
      select
        recipe.ingredient_id,
        pg_catalog.sum(recipe.quantity_required * order_item.quantity)::numeric(12, 3)
          as required_quantity
      from public.order_items as order_item
      join public.recipes as recipe
        on recipe.menu_item_id = order_item.menu_item_id
      where order_item.order_id = new.id
      group by recipe.ingredient_id
      order by recipe.ingredient_id
    loop
      update public.ingredients as ingredient
      set quantity = ingredient.quantity - ingredient_requirement.required_quantity
      where ingredient.id = ingredient_requirement.ingredient_id
        and ingredient.quantity >= ingredient_requirement.required_quantity
      returning ingredient.quantity into quantity_after;

      if not found then
        select ingredient.name, ingredient.quantity
        into ingredient_name, available_quantity
        from public.ingredients as ingredient
        where ingredient.id = ingredient_requirement.ingredient_id;

        raise exception
          'Cannot confirm order %: ingredient "%" requires %, but only % is available',
          new.reference,
          coalesce(ingredient_name, 'unknown'),
          ingredient_requirement.required_quantity,
          coalesce(available_quantity, 0)
          using errcode = 'check_violation';
      end if;

      insert into public.stock_movements (
        ingredient_id,
        movement_type,
        quantity,
        quantity_before,
        quantity_after,
        order_id,
        performed_by_user_id,
        notes
      )
      values (
        ingredient_requirement.ingredient_id,
        'Used'::public.stock_movement_type,
        ingredient_requirement.required_quantity,
        quantity_after + ingredient_requirement.required_quantity,
        quantity_after,
        new.id,
        (select auth.uid()),
        'Order confirmation stock deduction'
      );
    end loop;

    return new;
  end if;

  if old.status = 'Confirmed'::public.order_status
    and new.status = 'Cancelled'::public.order_status
  then
    if exists (
      select 1
      from public.stock_movements as movement
      where movement.order_id = old.id
        and movement.movement_type = 'Adjustment'::public.stock_movement_type
        and movement.notes = 'Order cancellation stock reversal'
    ) then
      return new;
    end if;

    for ingredient_requirement in
      select
        movement.ingredient_id,
        pg_catalog.sum(movement.quantity)::numeric(12, 3) as required_quantity
      from public.stock_movements as movement
      where movement.order_id = old.id
        and movement.movement_type = 'Used'::public.stock_movement_type
        and movement.notes = 'Order confirmation stock deduction'
      group by movement.ingredient_id
      order by movement.ingredient_id
    loop
      update public.ingredients as ingredient
      set quantity = ingredient.quantity + ingredient_requirement.required_quantity
      where ingredient.id = ingredient_requirement.ingredient_id
      returning ingredient.quantity into quantity_after;

      if not found then
        raise exception
          'Cannot reverse stock for order %: ingredient % no longer exists',
          old.reference,
          ingredient_requirement.ingredient_id;
      end if;

      insert into public.stock_movements (
        ingredient_id,
        movement_type,
        quantity,
        quantity_before,
        quantity_after,
        order_id,
        performed_by_user_id,
        notes
      )
      values (
        ingredient_requirement.ingredient_id,
        'Adjustment'::public.stock_movement_type,
        ingredient_requirement.required_quantity,
        quantity_after - ingredient_requirement.required_quantity,
        quantity_after,
        old.id,
        (select auth.uid()),
        'Order cancellation stock reversal'
      );
    end loop;
  end if;

  return new;
end;
$$;

-- Deducts recipe stock on confirmation and reverses it only for pre-preparation cancellation.
create trigger apply_order_stock_after_status_change
after update of status on public.orders
for each row
when (
  old.status is distinct from new.status
  and new.status in (
    'Confirmed'::public.order_status,
    'Cancelled'::public.order_status
  )
)
execute procedure public.apply_order_stock_rules();

create or replace function public.notify_low_stock_breach()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  breach_id uuid := pg_catalog.gen_random_uuid();
begin
  if new.quantity > new.minimum_level then
    new.low_stock_notified := false;
    return new;
  end if;

  if tg_op = 'UPDATE' and old.low_stock_notified then
    new.low_stock_notified := true;
    return new;
  end if;

  new.low_stock_notified := true;

  insert into public.notifications (
    recipient_role,
    event_type,
    title,
    message,
    payload
  )
  values
    (
      'kitchen'::public.app_role,
      'ingredient_stock_low',
      'Ingredient stock is low',
      pg_catalog.format(
        '%s is at %s %s (minimum %s %s).',
        new.name,
        new.quantity,
        new.unit,
        new.minimum_level,
        new.unit
      ),
      pg_catalog.jsonb_build_object(
        'ingredient_id', new.id,
        'quantity', new.quantity,
        'minimum_level', new.minimum_level,
        'unit', new.unit,
        'breach_id', breach_id
      )
    ),
    (
      'manager'::public.app_role,
      'ingredient_stock_low',
      'Ingredient stock is low',
      pg_catalog.format(
        '%s is at %s %s (minimum %s %s).',
        new.name,
        new.quantity,
        new.unit,
        new.minimum_level,
        new.unit
      ),
      pg_catalog.jsonb_build_object(
        'ingredient_id', new.id,
        'quantity', new.quantity,
        'minimum_level', new.minimum_level,
        'unit', new.unit,
        'breach_id', breach_id
      )
    );

  return new;
end;
$$;

-- Sends one low-stock alert per breach and rearms it after stock rises above minimum.
create trigger notify_low_stock_before_ingredient_write
before insert or update on public.ingredients
for each row execute procedure public.notify_low_stock_breach();

update public.ingredients as ingredient
set quantity = ingredient.quantity
where ingredient.quantity <= ingredient.minimum_level;
