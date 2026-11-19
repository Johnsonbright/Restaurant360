insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'menu-images',
  'menu-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/avif']::text[]
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy menu_images_manager_admin_upload
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'menu-images'
  and name like 'menu-items/%'
  and (select public.has_role('manager'::public.app_role, 'admin'::public.app_role))
);

create policy menu_images_manager_admin_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'menu-images'
  and name like 'menu-items/%'
  and (select public.has_role('manager'::public.app_role, 'admin'::public.app_role))
);
