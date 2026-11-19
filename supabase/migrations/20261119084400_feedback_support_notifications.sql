create table public.feedback (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  customer_id uuid references public.customers (id) on delete set null,
  order_id uuid references public.orders (id) on delete set null,
  rating integer not null check (rating between 1 and 5),
  comments text,
  suggestions text,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.complaints (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  customer_id uuid references public.customers (id) on delete set null,
  order_id uuid references public.orders (id) on delete set null,
  category public.complaint_category not null,
  description text not null,
  supporting_information text,
  assigned_staff_id uuid references public.profiles (id) on delete set null,
  status public.complaint_status not null default 'Open',
  response_notes text,
  resolved_at timestamptz,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.enquiries (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  customer_id uuid references public.customers (id) on delete set null,
  customer_name text not null,
  customer_email text not null,
  customer_phone text,
  category public.enquiry_category not null,
  subject text not null,
  message text not null,
  status public.enquiry_status not null default 'New',
  assigned_staff_id uuid references public.profiles (id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.enquiry_responses (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  enquiry_id uuid not null references public.enquiries (id) on delete cascade,
  responder_user_id uuid references public.profiles (id) on delete set null,
  message text not null,
  is_internal boolean not null default false,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table public.notifications (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  recipient_user_id uuid references public.profiles (id) on delete cascade,
  recipient_role public.app_role,
  event_type text not null,
  title text not null,
  message text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  check ((recipient_user_id is not null) <> (recipient_role is not null))
);

create index feedback_customer_id_idx on public.feedback (customer_id);
create index feedback_order_id_idx on public.feedback (order_id);
create index feedback_rating_idx on public.feedback (rating);
create index feedback_created_at_idx on public.feedback (created_at);

create index complaints_customer_id_idx on public.complaints (customer_id);
create index complaints_order_id_idx on public.complaints (order_id);
create index complaints_assigned_staff_id_idx on public.complaints (assigned_staff_id);
create index complaints_category_idx on public.complaints (category);
create index complaints_status_idx on public.complaints (status);
create index complaints_created_at_idx on public.complaints (created_at);
create index complaints_resolved_at_idx on public.complaints (resolved_at);

create index enquiries_customer_id_idx on public.enquiries (customer_id);
create index enquiries_assigned_staff_id_idx on public.enquiries (assigned_staff_id);
create index enquiries_category_idx on public.enquiries (category);
create index enquiries_status_idx on public.enquiries (status);
create index enquiries_created_at_idx on public.enquiries (created_at);
create index enquiries_resolved_at_idx on public.enquiries (resolved_at);

create index enquiry_responses_enquiry_id_idx on public.enquiry_responses (enquiry_id);
create index enquiry_responses_responder_user_id_idx on public.enquiry_responses (responder_user_id);
create index enquiry_responses_created_at_idx on public.enquiry_responses (created_at);

create index notifications_recipient_user_id_idx on public.notifications (recipient_user_id);
create index notifications_recipient_role_idx on public.notifications (recipient_role);
create index notifications_event_type_idx on public.notifications (event_type);
create index notifications_read_at_idx on public.notifications (read_at);
create index notifications_sent_at_idx on public.notifications (sent_at);
create index notifications_created_at_idx on public.notifications (created_at);

create trigger set_feedback_updated_at
before update on public.feedback
for each row execute procedure public.set_updated_at();

create trigger set_complaints_updated_at
before update on public.complaints
for each row execute procedure public.set_updated_at();

create trigger set_enquiries_updated_at
before update on public.enquiries
for each row execute procedure public.set_updated_at();

create trigger set_enquiry_responses_updated_at
before update on public.enquiry_responses
for each row execute procedure public.set_updated_at();

create trigger set_notifications_updated_at
before update on public.notifications
for each row execute procedure public.set_updated_at();

alter table public.feedback enable row level security;
alter table public.complaints enable row level security;
alter table public.enquiries enable row level security;
alter table public.enquiry_responses enable row level security;
alter table public.notifications enable row level security;

grant select, insert, update, delete on public.feedback to authenticated;
grant select, insert, update, delete on public.complaints to authenticated;
grant select, insert, update, delete on public.enquiries to authenticated;
grant select, insert, update, delete on public.enquiry_responses to authenticated;
grant select, insert, update, delete on public.notifications to authenticated;
grant insert on public.enquiries to anon;

create policy feedback_customer_read_own
on public.feedback
for select
to authenticated
using (
  exists (
    select 1
    from public.customers as customer
    where customer.id = feedback.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
  and (
    feedback.order_id is null
    or exists (
      select 1
      from public.orders as order_record
      where order_record.id = feedback.order_id
        and order_record.customer_id = feedback.customer_id
    )
  )
);

create policy feedback_customer_insert_own
on public.feedback
for insert
to authenticated
with check (
  exists (
    select 1
    from public.customers as customer
    where customer.id = feedback.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
  and (
    feedback.order_id is null
    or exists (
      select 1
      from public.orders as order_record
      where order_record.id = feedback.order_id
        and order_record.customer_id = feedback.customer_id
    )
  )
);

create policy feedback_manager_admin_all
on public.feedback
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));

create policy complaints_customer_read_own
on public.complaints
for select
to authenticated
using (
  exists (
    select 1
    from public.customers as customer
    where customer.id = complaints.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy complaints_customer_insert_own_open
on public.complaints
for insert
to authenticated
with check (
  status = 'Open'::public.complaint_status
  and assigned_staff_id is null
  and response_notes is null
  and exists (
    select 1
    from public.customers as customer
    where customer.id = complaints.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
  and (
    complaints.order_id is null
    or exists (
      select 1
      from public.orders as order_record
      where order_record.id = complaints.order_id
        and order_record.customer_id = complaints.customer_id
    )
  )
);

create policy complaints_support_manager_admin_all
on public.complaints
for all
to authenticated
using (
  (select public.has_role(
    'support'::public.app_role,
    'manager'::public.app_role,
    'admin'::public.app_role
  ))
)
with check (
  (select public.has_role(
    'support'::public.app_role,
    'manager'::public.app_role,
    'admin'::public.app_role
  ))
);

create policy enquiries_customer_read_own
on public.enquiries
for select
to authenticated
using (
  exists (
    select 1
    from public.customers as customer
    where customer.id = enquiries.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy enquiries_customer_insert_own_new
on public.enquiries
for insert
to authenticated
with check (
  status = 'New'::public.enquiry_status
  and assigned_staff_id is null
  and exists (
    select 1
    from public.customers as customer
    where customer.id = enquiries.customer_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy enquiries_anon_insert_new
on public.enquiries
for insert
to anon
with check (
  status = 'New'::public.enquiry_status
  and customer_id is null
  and assigned_staff_id is null
);

create policy enquiries_support_manager_admin_all
on public.enquiries
for all
to authenticated
using (
  (select public.has_role(
    'support'::public.app_role,
    'manager'::public.app_role,
    'admin'::public.app_role
  ))
)
with check (
  (select public.has_role(
    'support'::public.app_role,
    'manager'::public.app_role,
    'admin'::public.app_role
  ))
);

create policy enquiry_responses_customer_read_own
on public.enquiry_responses
for select
to authenticated
using (
  not is_internal
  and exists (
    select 1
    from public.enquiries as enquiry
    join public.customers as customer on customer.id = enquiry.customer_id
    where enquiry.id = enquiry_responses.enquiry_id
      and customer.auth_user_id = (select auth.uid())
  )
);

create policy enquiry_responses_support_manager_admin_all
on public.enquiry_responses
for all
to authenticated
using (
  (select public.has_role(
    'support'::public.app_role,
    'manager'::public.app_role,
    'admin'::public.app_role
  ))
)
with check (
  (select public.has_role(
    'support'::public.app_role,
    'manager'::public.app_role,
    'admin'::public.app_role
  ))
);

create policy notifications_recipient_read
on public.notifications
for select
to authenticated
using (
  recipient_user_id = (select auth.uid())
  or (
    recipient_user_id is null
    and recipient_role = (select public.current_app_role())
  )
);

create policy notifications_manager_admin_all
on public.notifications
for all
to authenticated
using ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)))
with check ((select public.has_role('manager'::public.app_role, 'admin'::public.app_role)));
