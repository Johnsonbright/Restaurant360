# Restaurant360

Restaurant360 is a Next.js App Router application backed by Supabase Auth and Postgres.
This repository contains the Foundation and Milestone 1b design/auth refresh. Later
business features remain intentionally out of scope.

## Requirements

- Node.js and npm
- A Supabase project (the free tier is sufficient)
- Supabase CLI only if you prefer the CLI migration workflow

## Local setup

1. Install dependencies:

   ```sh
   npm install
   ```

2. Copy `.env.example` to `.env.local` and fill in the Supabase project URL and anon
   key. Find them in the Supabase project's API settings.

   ```dotenv
   NEXT_PUBLIC_SUPABASE_URL=
   NEXT_PUBLIC_SUPABASE_ANON_KEY=
   ```

   The browser uses only the anon key. Do not put a service-role key in client code
   or in any `NEXT_PUBLIC_` variable. No service-role key is needed for this
   milestone. Keep real values in `.env.local`; never commit that file.

3. The profiles/roles migration,
   [`supabase/migrations/20261119000000_profiles_and_roles.sql`](./supabase/migrations/20261119000000_profiles_and_roles.sql),
   is the existing Foundation migration. The new Google profile-name fallback is
   in [`supabase/migrations/20261119011600_profile_name_fallback.sql`](./supabase/migrations/20261119011600_profile_name_fallback.sql).
   Review that new migration before applying it; it has not been run.

   For a linked Supabase project, install the Supabase CLI, run `supabase init`
   once if the project is not initialized, link the project, and apply reviewed
   migrations:

   ```sh
   supabase link --project-ref YOUR_PROJECT_REF
   supabase db push
   ```

   For local development, run `supabase start` and then `supabase migration up`.
   You can also paste the reviewed SQL into the Supabase SQL Editor.

4. Start the development server:

   ```sh
   npm run dev
   ```

   Visit `http://localhost:3000`.

## Authentication and sample roles

Register or log in at `/register` and `/login`. Registration creates a customer
profile. Supabase email confirmation behavior is controlled by the Supabase Auth
settings; `example.test` addresses below are reserved examples and do not receive
email. For local demos, use Supabase local or disable email confirmation in a
non-production test project.

To create one demo user per role, register these accounts through the app with a
local-only test password of your choice:

| Role | Example email |
|---|---|
| customer | `customer@example.test` |
| kitchen | `kitchen@example.test` |
| manager | `manager@example.test` |
| finance | `finance@example.test` |
| rider | `rider@example.test` |
| support | `support@example.test` |
| admin | `admin@example.test` |

After confirming/creating the users, run this role-assignment SQL in the Supabase
SQL Editor. It uses only these example addresses and contains no real user data.
The migration restricts role updates to admins at the application level; use the
trusted SQL Editor only for initial test-user setup.

```sql
update public.profiles as p
set role = case u.email
  when 'kitchen@example.test' then 'kitchen'::public.app_role
  when 'manager@example.test' then 'manager'::public.app_role
  when 'finance@example.test' then 'finance'::public.app_role
  when 'rider@example.test' then 'rider'::public.app_role
  when 'support@example.test' then 'support'::public.app_role
  when 'admin@example.test' then 'admin'::public.app_role
  else p.role
end
from auth.users as u
where p.id = u.id
  and u.email in (
    'kitchen@example.test',
    'manager@example.test',
    'finance@example.test',
    'rider@example.test',
    'support@example.test',
    'admin@example.test'
  );
```

The customer account keeps the default `customer` role. Log in using the matching
email and the local test password chosen during registration. `/staff/*` is
available to kitchen, manager, finance, rider, support, and admin; `/admin/*` is
available to manager and admin.

## Theme

Use the theme selector in the public header or staff/admin sidebar to switch
between Light, Dark, and System. System is the default.

The design tokens are in `app/globals.css` and map to the shadcn/ui tokens:

| Token | Dark | Light |
|---|---|---|
| Background | `#0B1424` | `#FBF6EE` |
| Surface | `#14213A` | `#FFFFFF` |
| Border | `#24334F` | `#E7DCCB` |
| Text | `#F4EDE2` | `#1B2433` |
| Muted text | `#A9B4C7` | `#5A6578` |
| Accent | `#F0A54B` | `#9A5A10` |
| Accent text | `#0B1424` | `#FFFFFF` |
| Secondary | `#2F6B8F` | `#2F6B8F` |

Headings use Fraunces; body and UI use Inter. Entrance and hover motion respects
the system reduced-motion preference.

Restaurant hours, meal descriptions, offers, and guest reviews on the homepage
are sample design content. Address, email, and phone details are placeholders.

## Photography

The meal cards and gallery currently use original flat SVG placeholder artwork in
`public/images/`. Replace those placeholders with approved restaurant photography
before launch. Add the hero photograph at `public/images/hero.jpg`; if it is
absent, the hero uses a soft amber radial glow on navy instead. Keep image files
optimized for the free hosting/storage limits.

## Google sign-in

Google sign-in is implemented through Supabase Auth. In the Supabase dashboard,
enable Google under **Authentication → Providers** and enter the Google OAuth
credentials there; do not put a Google client ID or secret in this repository or
in chat. Configure the Supabase project URL/site URL and add the local and
deployed `/auth/callback` URLs to the Supabase redirect allowlist. In the Google
OAuth configuration, allow the Supabase project's callback URL shown by Supabase
(typically `https://<project-ref>.supabase.co/auth/v1/callback`).

The app sends users to `${site-origin}/auth/callback` after Google consent. The
callback exchanges the code for a session, then sends customers home, staff to
`/staff`, and managers/admins to `/admin`.

## Foundation routes

- Public: `/`, `/menu`, `/reserve`, `/contact`
- Auth: `/register`, `/login`
- Staff: `/staff`, `/staff/kitchen`, `/staff/orders`
- Admin: `/admin`, `/admin/dashboard`

Menu, ordering, kitchen workflows, payments, and other later-milestone features
are intentionally not implemented.
