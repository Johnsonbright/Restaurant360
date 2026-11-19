# Restaurant360: Project Specification

> Source of truth for the AI coding agent and the team. Read this file fully before every task. Build only the milestone you are asked to build. Do not build features from later milestones early.

## 1. Project summary

Restaurant360 is a restaurant offering dine-in, takeaway and delivery. This project builds one website that connects customers, menu, orders, kitchen, inventory, payments, deliveries, reservations, feedback and support, plus an admin dashboard with reports.

- Group project (Group 08). Sample data and simulated transactions only.
- No real customer data. No real payments.
- Free tools only. Do not depend on any paid plan for essential functionality.

## 2. Scope

### In scope (website only)

- Public site: home, menu, cart and checkout, reservations, contact, feedback, order tracking.
- Staff portal: kitchen board, menu admin, inventory, suppliers, payments, deliveries, reservations, complaints, support queue, notifications.
- Admin area: dashboards, management reports, user and role management, settings.
- In-app notifications stored in a `notifications` table and shown in the app.
- Light, dark and system theme with a manual toggle.

### Parked for later (do NOT build)

- n8n workflows and sending emails or SMS.
- Web scraping and the food market research report.
- AI features (meal categorisation, feedback summaries, enquiry classification, suggested replies).

The `notifications` table must be designed so n8n or an email service can be connected later without schema changes.

## 3. Tech stack

| Layer | Tool |
|---|---|
| Framework | Next.js (App Router) + TypeScript |
| Styling | Tailwind CSS, shadcn/ui, next-themes |
| Database | Supabase Postgres |
| Auth | Supabase Auth (email and password) using `@supabase/ssr` |
| Realtime | Supabase Realtime (kitchen board, order tracking) |
| Storage | Supabase Storage (menu and restaurant photos) |
| Hosting | Vercel free tier |
| Version control | Git and GitHub, feature branches and pull requests |

## 4. Coding and security rules

1. Never use the Supabase service-role key in client code or in any `NEXT_PUBLIC_` variable. The browser uses the anon key only.
2. Keep secrets in `.env.local`. Commit `.env.example` with empty values. Never commit `.env.local`.
3. Every table has Row Level Security enabled with explicit policies. Do not disable RLS to make something work.
4. All schema changes are SQL files in `supabase/migrations`, named with a timestamp prefix. Show each migration and policy for human review before it is run.
5. Business rules (status transitions, stock deduction, notification creation) live in the database as triggers or functions, not only in the UI.
6. Validate all form input on the server (for example with zod). Never trust the client.
7. Use small, typed components. Use server components by default and client components only where needed.
8. Every page works on mobile and in both themes.
9. State any assumption you make instead of silently choosing.
10. Never ask for keys or passwords in chat. Expect them in `.env.local`.

## 5. Roles and permissions

| Role | Access |
|---|---|
| customer | Own profile, orders, reservations, feedback, enquiries |
| kitchen | View orders and order items, update preparation status and timestamps |
| manager | Menu, orders, reservations, inventory, deliveries, reports |
| finance | Payment records, daily sales, payment reports |
| rider | Assigned deliveries and delivery status updates |
| support | Enquiries, complaints, responses |
| admin | Everything, including user and role management |

Route protection:

- `/staff/*`: kitchen, manager, finance, rider, support, admin.
- `/admin/*`: admin, manager.
- Logged-out users go to `/login`. Wrong role goes to `/unauthorized`.
- A user can never change their own role. Only admin can change roles.
- Middleware gives a good user experience, but RLS is the real enforcement.

## 6. Public website requirements

### 6.1 Homepage

- Restaurant name and branding.
- Introduction to Restaurant360.
- Featured meals.
- Popular food categories.
- Special offers.
- Restaurant photographs.
- Customer reviews.
- Opening hours.
- Location.
- Contact details.
- Clear ordering buttons.

### 6.2 Menu page

Each menu item shows: meal name, photograph, description, category, price, available variations, add-ons, dietary information where applicable, and availability status. Unavailable items are visible but cannot be added to the cart.

Categories: Breakfast, Main Meals, Snacks, Desserts, Drinks, Specials.

### 6.3 Online ordering

Customers can:

- Select meals and choose quantities.
- Select available variations and add-ons.
- Add special instructions.
- Add items to a cart and review the order.
- Choose dine-in, takeaway or delivery.
- Enter contact and delivery information (delivery address required only for delivery).
- Submit the order and see an order confirmation with the order reference.

### 6.4 Table reservation page

Collects: customer name, email, phone number, preferred date, preferred time, number of guests, special requests.

### 6.5 Contact page

A working customer enquiry form that creates a support enquiry.

### 6.6 Other public pages

- Track Order: enter order reference to see live status.
- Feedback form: rating, order reference, comments, suggestions.
- Login and Register.

## 7. Staff portal requirements

### 7.1 Menu administration (manager, admin)

- Add menu items, update prices, change descriptions, manage categories.
- Mark items available or unavailable.
- Retrieve previous menu records (history of every change in `menu_item_history`).

### 7.2 Order management and kitchen

- New orders trigger a notification to relevant staff.
- Kitchen board (realtime): view new orders, meal details and quantities, special instructions.
- Update preparation status, record preparation start time, record when an order is ready.
- Identify delayed orders (highlighted on the board).
- Authorised staff can modify an order after creation; every change is logged and the updated order is kept.
- Order history of completed and cancelled orders.

### 7.3 Inventory

- Ingredient records: name, reference, quantity available, unit, supplier, minimum stock level, expiry information where applicable.
- Recipes link each menu item to the ingredients and quantities it needs.
- Stock updates: new stock received, stock used, damaged, expired, manual adjustment. Each is a row in `stock_movements`.
- Low-stock detection notifies the responsible staff.
- Stock report: available ingredients, low-stock items, recent movements.
- Suppliers: details, ingredients supplied, purchase history.

### 7.4 Payments (finance, manager, admin)

- Payment record: order reference, customer, expected order amount, amount recorded, payment reference, payment date, payment status.
- Authorised staff record and update payments. Payments are simulated; no real transactions.
- Daily payment review and daily sales information.

### 7.5 Deliveries and reservations

- Delivery record: order reference, customer, delivery address, assigned rider, dispatch date, expected delivery time, delivery status.
- Reservation record: reference, customer, date, time, number of guests, table assignment, status.
- Staff review requests, confirm bookings, assign tables, reschedule, cancel and record changes.
- Riders see only deliveries assigned to them.

### 7.6 Feedback, complaints and support

- Complaint record: customer, order reference, category, description, supporting information, assigned staff, resolution status.
- Staff review complaints, record responses and update statuses.
- Support queue handles questions about menu items, meal availability, orders, delivery, reservations, opening hours, complaints and general information. Enquiries are categorised, assigned and tracked until resolved.

## 8. Admin requirements

### 8.1 Dashboards

- Sales: orders received, completed orders, cancelled orders, revenue records.
- Menu: available meals, unavailable meals, popular items.
- Kitchen: new orders, being prepared, ready, delayed.
- Inventory: available ingredients, low-stock ingredients, stock movements.
- Delivery and reservation: active deliveries, completed deliveries, upcoming reservations, cancelled reservations.

### 8.2 Management reports (date filters and export)

1. Daily sales report.
2. Monthly sales report.
3. Menu performance report.
4. Ingredient stock report.
5. Order processing report.
6. Delivery report.
7. Reservation report.
8. Customer feedback report.

### 8.3 Settings and users

- Manage user roles.
- Configure thresholds: delayed-order minutes, reservation slot length, opening hours, table capacity.

## 9. Statuses and categories (use exactly these)

Use Postgres enums.

**Order status:** New, Confirmed, Preparing, Ready for Collection, Ready for Delivery, Completed, Cancelled.

**Order type:** dine-in, takeaway, delivery.

**Payment status:** Pending, Paid, Partially Paid, Awaiting Verification, Refunded.

**Delivery status:** Awaiting Assignment, Assigned, Preparing for Dispatch, Out for Delivery, Delivered, Failed.

**Reservation status:** Requested, Confirmed, Rescheduled, Cancelled, Completed, No Show.

**Complaint category:** Incorrect Order, Missing Item, Delayed Order, Food Quality, Delivery Problem, Staff Service, Other.

**Complaint resolution status:** Open, In Progress, Resolved, Closed.

**Stock movement type:** Received, Used, Damaged, Expired, Adjustment.

**Enquiry categories:** Menu, Availability, Order, Delivery, Reservation, Opening Hours, Complaint, General.

**Menu categories:** Breakfast, Main Meals, Snacks, Desserts, Drinks, Specials.

## 10. Database tables

Every table has `id` (uuid), `created_at` and `updated_at`. Foreign keys link every record to the correct customer and order.

| Area | Tables |
|---|---|
| Users | profiles (linked to auth.users, role), customers |
| Menu | categories, menu_items, menu_variations, menu_addons, menu_item_history |
| Orders | orders, order_items, order_status_log, kitchen_records |
| Inventory | ingredients, recipes, stock_movements, suppliers, purchases |
| Payments | payments |
| Delivery and bookings | deliveries, tables, reservations |
| Feedback and support | feedback, complaints, enquiries, enquiry_responses |
| Notifications | notifications (event type, recipient, payload, read and sent status) |

Key fields:

- **customers:** name, email, phone, address, linked auth user (nullable for guest orders).
- **menu_items:** reference, name, description, category, price, photo URL, ingredient information, dietary flags, availability.
- **orders:** reference (human-readable, unique), customer, order type, total, status, special instructions, timestamps.
- **order_items:** order, menu item, quantity, variation, add-ons, special instructions, line price (price captured at order time).
- **kitchen_records:** order, assigned kitchen staff, preparation start time, ready time, delayed flag.
- **payments:** order, customer, expected amount, amount recorded, payment reference, payment date, status.
- **deliveries:** order, customer, delivery address, assigned rider, dispatch date, expected delivery time, status.
- **reservations:** reference, customer, date, time, guests, table, status, special requests.
- **feedback:** customer, order, rating (1 to 5), comments, suggestions.
- **complaints:** customer, order, category, description, supporting information, assigned staff, resolution status, response notes.

Reporting uses database views: daily sales, monthly sales, menu performance, stock summary, order processing times, delivery performance, reservation summary, feedback summary.

## 11. Business rules

Rules marked **PROPOSED** are awaiting team confirmation. Implement them as written unless the team changes them.

1. **Order status flow (CONFIRMED):** New → Confirmed → Preparing → Ready for Collection or Ready for Delivery → Completed. Cancelled is allowed from New, Confirmed or Preparing. A database trigger blocks skipped or invalid transitions and writes every change to `order_status_log` with user and timestamp.
2. **Payment and confirmation (PROPOSED):** dine-in and takeaway orders can be confirmed by staff at any time. Delivery orders can move to Confirmed only when payment is Paid or Awaiting Verification.
3. **Stock deduction (PROPOSED):** when an order becomes Confirmed, deduct ingredients using `recipes` and write `stock_movements` rows. Cancelling before Preparing reverses the deduction.
4. **Delayed orders (PROPOSED):** an order is delayed when it has been in Preparing longer than a configurable number of minutes (default 20).
5. **Low stock:** when ingredient quantity reaches or falls below its minimum level, create one notification for responsible staff per breach.
6. **Reservations (PROPOSED):** bookings must fall within opening hours and table capacity. Reminder notification created 24 hours before the booking.
7. **Deliveries:** a delivery-type order automatically creates a delivery record with status Awaiting Assignment.
8. **Order modifications:** only manager and admin can edit an order after it is Confirmed. Each change is logged.
9. **Prices:** order items store the price at order time, so later menu price changes do not alter past orders.
10. **Menu history:** every change to a menu item writes a snapshot to `menu_item_history`.
11. **Order reference:** human-readable and unique, for example `R360-20261119-0001`.

## 12. Notifications (in-app)

Each business event inserts a row into `notifications` with recipient, message built from dynamic customer, order, menu or reservation data, and a read status. Staff see a notification centre; customers see updates on their order and reservation pages.

| Business event | Message goes to |
|---|---|
| New customer registered | Customer (welcome) |
| Order submitted | Customer (acknowledgement) and kitchen and manager staff |
| Order confirmed | Customer |
| Order being prepared | Customer |
| Order ready | Customer (collection or delivery update) |
| Order dispatched | Customer (delivery notification) |
| Order delivered | Customer (completion confirmation) |
| Reservation requested | Customer (acknowledgement) and manager |
| Reservation confirmed | Customer |
| Reservation approaching | Customer (reminder) |
| Ingredient stock low | Responsible staff |
| New complaint received | Support staff |
| Complaint resolved | Customer |

## 13. Theme

- Modes: Light, Dark, System. Default is System, which follows the device live.
- Manual toggle in the public header and the staff portal; choice saved per browser.
- Use `next-themes` with class-based dark mode and CSS variables for all colours.
- `suppressHydrationWarning` on the html tag; no white flash on load.
- Both themes must have readable contrast, including charts and dashboards.
- Optional extra mode "Auto (by time)" is not required unless the team asks for it.

## 14. Project structure

```
app/
  (public)/      home, menu, cart, checkout, reserve, contact, feedback, track
  (staff)/       kitchen, orders, menu-admin, inventory, payments, deliveries, reservations, complaints, support
  (admin)/       dashboard, reports, users, settings
  login/ register/ unauthorized/
components/
lib/
  supabase/      client.ts, server.ts, middleware.ts
supabase/
  migrations/
SPEC.md
README.md
.env.example
```

## 15. Milestones

Build one milestone at a time. Each ends with a working slice the team reviews before the next begins.

| # | Milestone | Outcome |
|---|---|---|
| 1 | Foundation | Next.js app, theme, layouts, sign-in, profiles and roles, route protection |
| 2 | Database schema and seed | All tables, enums, triggers, RLS policies, sample data |
| 3 | Menu and menu admin | Public menu page, menu management, availability, history |
| 4 | Cart and ordering | Cart, checkout, order submission, order confirmation, customer records |
| 5 | Orders and kitchen | Status flow, realtime kitchen board, delayed orders, modifications, tracking page |
| 6 | Payments and inventory | Payment records, confirmation rule, ingredients, recipes, stock movements, low-stock alerts |
| 7 | Deliveries and reservations | Reservation flow, table assignment, delivery records, rider view |
| 8 | Feedback, complaints and support | Feedback form, complaint handling, support queue |
| 9 | Dashboards, reports and notifications | All dashboards, eight reports, notification centre for all 13 events |
| 10 | Testing and hand-over | End-to-end test, RLS tests per role, mobile and theme checks, documentation |

## 16. Free-tier constraints

- Supabase free projects pause after inactivity. Keep a seed script that can restore sample data.
- Free storage and database size are limited. Compress images.
- Realtime connection limits: subscribe only on the kitchen board and order tracking page.
- Vercel free limits on builds and serverless functions: prefer static rendering where possible.

## 17. Definition of done (final demo flow)

1. Customer registers, browses the menu and places a delivery order with a customised item.
2. The kitchen board shows the order instantly and the customer sees an in-app acknowledgement.
3. Finance records a simulated payment and the order is confirmed under the agreed rule.
4. Stock is deducted and a low-stock notification appears for staff.
5. Kitchen starts and finishes preparation, and a delayed order is highlighted.
6. A rider is assigned, dispatches and delivers, and the customer sees each update.
7. Customer makes a reservation and leaves feedback; staff confirm the booking and resolve a complaint.
8. Dashboards and reports reflect all of the above.
9. Light, dark and system themes and the manual toggle work on desktop and mobile.

## 18. Agent working agreement

- Before starting, restate the milestone goal and list the files you plan to create or change.
- Do only the tasks in the current milestone prompt.
- Show every migration and RLS policy for review before running it.
- When finished, reply with: what is done, anything skipped and why, files changed, and how to test it.
- Do not start the next milestone.
