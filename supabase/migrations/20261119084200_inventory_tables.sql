create table public.suppliers (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  name text not null,
  contact_name text,
  email text,
  phone text,
  address text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.ingredients (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  reference text not null unique,
  name text not null,
  unit text not null,
  quantity numeric(12, 3) not null default 0 check (quantity >= 0),
  minimum_level numeric(12, 3) not null default 0 check (minimum_level >= 0),
  expiry_date date,
  supplier_id uuid references public.suppliers (id) on delete set null,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.recipes (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items (id) on delete restrict,
  ingredient_id uuid not null references public.ingredients (id) on delete restrict,
  quantity_required numeric(12, 3) not null check (quantity_required > 0),
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  unique (menu_item_id, ingredient_id)
);

create table public.purchases (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  supplier_id uuid not null references public.suppliers (id) on delete restrict,
  reference text not null unique,
  purchase_date date not null default current_date,
  expected_delivery_date date,
  received_at timestamptz,
  total_cost numeric(10, 2) not null default 0 check (total_cost >= 0),
  notes text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.stock_movements (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  ingredient_id uuid not null references public.ingredients (id) on delete restrict,
  movement_type public.stock_movement_type not null,
  quantity numeric(12, 3) not null check (quantity > 0),
  quantity_before numeric(12, 3) check (quantity_before >= 0),
  quantity_after numeric(12, 3) check (quantity_after >= 0),
  order_id uuid references public.orders (id) on delete set null,
  purchase_id uuid references public.purchases (id) on delete set null,
  performed_by_user_id uuid references public.profiles (id) on delete set null,
  movement_date timestamptz not null default pg_catalog.now(),
  notes text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create index ingredients_supplier_id_idx on public.ingredients (supplier_id);
create index ingredients_expiry_date_idx on public.ingredients (expiry_date);
create index ingredients_quantity_idx on public.ingredients (quantity);
create index recipes_menu_item_id_idx on public.recipes (menu_item_id);
create index recipes_ingredient_id_idx on public.recipes (ingredient_id);
create index purchases_supplier_id_idx on public.purchases (supplier_id);
create index purchases_purchase_date_idx on public.purchases (purchase_date);
create index purchases_expected_delivery_date_idx on public.purchases (expected_delivery_date);
create index purchases_received_at_idx on public.purchases (received_at);
create index stock_movements_ingredient_id_idx on public.stock_movements (ingredient_id);
create index stock_movements_order_id_idx on public.stock_movements (order_id);
create index stock_movements_purchase_id_idx on public.stock_movements (purchase_id);
create index stock_movements_performed_by_user_id_idx on public.stock_movements (performed_by_user_id);
create index stock_movements_type_idx on public.stock_movements (movement_type);
create index stock_movements_movement_date_idx on public.stock_movements (movement_date);

create trigger set_suppliers_updated_at
before update on public.suppliers
for each row execute procedure public.set_updated_at();

create trigger set_ingredients_updated_at
before update on public.ingredients
for each row execute procedure public.set_updated_at();

create trigger set_recipes_updated_at
before update on public.recipes
for each row execute procedure public.set_updated_at();

create trigger set_purchases_updated_at
before update on public.purchases
for each row execute procedure public.set_updated_at();

create trigger set_stock_movements_updated_at
before update on public.stock_movements
for each row execute procedure public.set_updated_at();

alter table public.suppliers enable row level security;
alter table public.ingredients enable row level security;
alter table public.recipes enable row level security;
alter table public.purchases enable row level security;
alter table public.stock_movements enable row level security;

grant select, insert, update, delete on public.suppliers to authenticated;
grant select, insert, update, delete on public.ingredients to authenticated;
grant select, insert, update, delete on public.recipes to authenticated;
grant select, insert, update, delete on public.purchases to authenticated;
grant select, insert, update, delete on public.stock_movements to authenticated;

create policy suppliers_manager_admin_all
on public.suppliers
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy ingredients_manager_admin_all
on public.ingredients
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy recipes_manager_admin_all
on public.recipes
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy purchases_manager_admin_all
on public.purchases
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy stock_movements_manager_admin_all
on public.stock_movements
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));
