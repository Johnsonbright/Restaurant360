alter table public.menu_items
  add column if not exists subcategory text,
  add column if not exists contains_alcohol boolean not null default false;

do $$
begin
  if not exists (
    select 1
    from pg_catalog.pg_constraint as constraint_record
    where constraint_record.conrelid = 'public.categories'::regclass
      and constraint_record.contype = 'u'
      and constraint_record.conkey = array[
        (
          select attribute.attnum
          from pg_catalog.pg_attribute as attribute
          where attribute.attrelid = 'public.categories'::regclass
            and attribute.attname = 'name'
            and not attribute.attisdropped
        )
      ]::smallint[]
  ) then
    alter table public.categories
      add constraint categories_name_key unique (name);
  end if;
end;
$$;

insert into public.app_settings (key, value)
values ('currency', '"NGN"'::jsonb)
on conflict (key) do update
set value = excluded.value;
