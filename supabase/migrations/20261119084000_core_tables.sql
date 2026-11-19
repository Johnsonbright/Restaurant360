create or replace function public.current_app_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select profile.role
  from public.profiles as profile
  where profile.id = (select auth.uid())
  limit 1;
$$;

create or replace function public.has_role(variadic requested_roles public.app_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from pg_catalog.unnest(requested_roles) as requested(role)
    where requested.role = public.current_app_role()
  );
$$;

revoke all on function public.current_app_role() from public;
revoke all on function public.has_role(public.app_role[]) from public;
grant execute on function public.current_app_role() to authenticated;
grant execute on function public.has_role(public.app_role[]) to authenticated;

create table public.customers (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  auth_user_id uuid unique references auth.users (id) on delete set null,
  name text not null,
  email text,
  phone text,
  address text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.categories (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  name text not null unique
    check (name in ('Breakfast', 'Main Meals', 'Snacks', 'Desserts', 'Drinks', 'Specials')),
  description text,
  display_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.menu_items (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  reference text not null unique,
  category_id uuid not null references public.categories (id) on delete restrict,
  name text not null,
  description text,
  price numeric(10, 2) not null check (price >= 0),
  photo_url text,
  ingredient_information text,
  dietary_flags text[] not null default array[]::text[],
  is_available boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.menu_variations (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items (id) on delete cascade,
  name text not null,
  description text,
  price_adjustment numeric(10, 2) not null default 0,
  is_available boolean not null default true,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  unique (menu_item_id, name)
);

create table public.menu_addons (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  menu_item_id uuid not null references public.menu_items (id) on delete cascade,
  name text not null,
  description text,
  price numeric(10, 2) not null default 0 check (price >= 0),
  is_available boolean not null default true,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  unique (menu_item_id, name)
);

create table public.menu_item_history (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  menu_item_id uuid references public.menu_items (id) on delete set null,
  menu_item_reference text not null,
  snapshot jsonb not null,
  changed_by_user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.app_settings (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  key text not null unique,
  value jsonb not null check (value <> 'null'::jsonb),
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

insert into public.app_settings (key, value)
values
  ('opening_hours', '{}'::jsonb),
  ('delayed_order_minutes', '20'::jsonb),
  ('reservation_slot_minutes', '60'::jsonb),
  ('reminder_hours', '24'::jsonb);

create index customers_created_at_idx on public.customers (created_at);
create index menu_items_category_id_idx on public.menu_items (category_id);
create index menu_items_available_idx on public.menu_items (is_available);
create index menu_variations_menu_item_id_idx on public.menu_variations (menu_item_id);
create index menu_variations_available_idx on public.menu_variations (is_available);
create index menu_addons_menu_item_id_idx on public.menu_addons (menu_item_id);
create index menu_addons_available_idx on public.menu_addons (is_available);
create index menu_item_history_menu_item_id_idx on public.menu_item_history (menu_item_id);
create index menu_item_history_changed_by_user_id_idx on public.menu_item_history (changed_by_user_id);
create index menu_item_history_created_at_idx on public.menu_item_history (created_at);
create trigger set_customers_updated_at
before update on public.customers
for each row execute procedure public.set_updated_at();

create trigger set_categories_updated_at
before update on public.categories
for each row execute procedure public.set_updated_at();

create trigger set_menu_items_updated_at
before update on public.menu_items
for each row execute procedure public.set_updated_at();

create trigger set_menu_variations_updated_at
before update on public.menu_variations
for each row execute procedure public.set_updated_at();

create trigger set_menu_addons_updated_at
before update on public.menu_addons
for each row execute procedure public.set_updated_at();

create trigger set_menu_item_history_updated_at
before update on public.menu_item_history
for each row execute procedure public.set_updated_at();

create trigger set_app_settings_updated_at
before update on public.app_settings
for each row execute procedure public.set_updated_at();

alter table public.customers enable row level security;
alter table public.categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.menu_variations enable row level security;
alter table public.menu_addons enable row level security;
alter table public.menu_item_history enable row level security;
alter table public.app_settings enable row level security;

grant select, insert, update, delete on public.customers to authenticated;
grant select, insert, update, delete on public.categories to authenticated;
grant select, insert, update, delete on public.menu_items to authenticated;
grant select, insert, update, delete on public.menu_variations to authenticated;
grant select, insert, update, delete on public.menu_addons to authenticated;
grant select on public.menu_item_history to authenticated;
grant select, insert, update, delete on public.app_settings to authenticated;

grant select on public.categories to anon;
grant select on public.menu_items to anon;
grant select on public.menu_variations to anon;
grant select on public.menu_addons to anon;

create policy customers_read_own
on public.customers
for select
to authenticated
using (auth_user_id = (select auth.uid()));

create policy customers_insert_own
on public.customers
for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

create policy customers_update_own
on public.customers
for update
to authenticated
using (auth_user_id = (select auth.uid()))
with check (auth_user_id = (select auth.uid()));

create policy customers_manager_admin_all
on public.customers
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy categories_public_read_active
on public.categories
for select
to anon, authenticated
using (is_active);

create policy categories_manager_admin_all
on public.categories
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy menu_items_public_read_available
on public.menu_items
for select
to anon, authenticated
using (
  is_available
  and exists (
    select 1
    from public.categories as category
    where category.id = menu_items.category_id
      and category.is_active
  )
);

create policy menu_items_manager_admin_all
on public.menu_items
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy menu_variations_public_read_available
on public.menu_variations
for select
to anon, authenticated
using (
  is_available
  and exists (
    select 1
    from public.menu_items as item
    join public.categories as category on category.id = item.category_id
    where item.id = menu_variations.menu_item_id
      and item.is_available
      and category.is_active
  )
);

create policy menu_variations_manager_admin_all
on public.menu_variations
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy menu_addons_public_read_available
on public.menu_addons
for select
to anon, authenticated
using (
  is_available
  and exists (
    select 1
    from public.menu_items as item
    join public.categories as category on category.id = item.category_id
    where item.id = menu_addons.menu_item_id
      and item.is_available
      and category.is_active
  )
);

create policy menu_addons_manager_admin_all
on public.menu_addons
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy menu_item_history_manager_admin_read
on public.menu_item_history
for select
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy app_settings_manager_admin_all
on public.app_settings
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));
