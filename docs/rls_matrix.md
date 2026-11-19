# Row-level security matrix

This matrix describes the direct table access granted by the policies in the
migrations through `20261119090300_notifications_events.sql`. `R`, `I`, `U`
and `D` mean read, insert, update and delete are allowed; `-` means denied.
An allowed operation can still be limited to rows, columns, or values stated
below. Role columns refer to an authenticated user with that one `profiles.role`.
Anonymous access is via the `anon` database role.

| Table | Anonymous | Customer | Kitchen | Manager | Finance | Rider | Support | Admin |
|---|---|---|---|---|---|---|---|---|
| profiles | - | R | R | R | R | R | R | R/U |
| customers | - | R/I/U | - | R/I/U/D | - | - | - | R/I/U/D |
| categories | R | R | R | R/I/U/D | R | R | R | R/I/U/D |
| menu_items | R | R | R | R/I/U/D | R | R | R | R/I/U/D |
| menu_variations | R | R | R | R/I/U/D | R | R | R | R/I/U/D |
| menu_addons | R | R | R | R/I/U/D | R | R | R | R/I/U/D |
| menu_item_history | - | - | - | R | - | - | - | R |
| app_settings | - | - | R | R/I/U/D | - | - | - | R/I/U/D |
| orders | - | R/I/U | R | R/I/U/D | - | - | - | R/I/U/D |
| order_items | - | R | R | R/I/U/D | - | - | - | R/I/U/D |
| order_status_log | - | R | R | R | - | - | - | R |
| kitchen_records | - | - | R | R/I/U/D | - | - | - | R/I/U/D |
| suppliers | - | - | - | R/I/U/D | - | - | - | R/I/U/D |
| ingredients | - | - | - | R/I/U/D | - | - | - | R/I/U/D |
| recipes | - | - | - | R/I/U/D | - | - | - | R/I/U/D |
| purchases | - | - | - | R/I/U/D | - | - | - | R/I/U/D |
| stock_movements | - | - | - | R/I/U/D | - | - | - | R/I/U/D |
| payments | - | R | - | R/I/U/D | R/I/U | - | - | R/I/U/D |
| deliveries | - | R | - | R/I/U/D | - | R/U | - | R/I/U/D |
| tables | - | - | - | R/I/U/D | - | - | - | R/I/U/D |
| reservations | I | R/I | - | R/I/U/D | - | - | - | R/I/U/D |
| feedback | - | R/I | - | R/I/U/D | - | - | - | R/I/U/D |
| complaints | - | R/I | - | R/I/U/D | - | - | R/I/U/D | R/I/U/D |
| enquiries | I | R/I | - | R/I/U/D | - | - | R/I/U/D | R/I/U/D |
| enquiry_responses | - | R | - | R/I/U/D | - | - | R/I/U/D | R/I/U/D |
| notifications | - | R/U | R/U | R/U | R/U | R/U | R/U | R/U |

## Row and column scope

- Public menu reads expose active categories and available menu items,
  variations, and add-ons associated with active categories/items.
- Profiles are readable by their owner and by admins. Only admins may update
  profiles; there are no profile insert or delete policies. The trigger blocks
  a user from changing their own role.
- Customers may read, insert and update only their own customer row. Managers
  and admins have all four operations on customer rows.
- Manager/admin access shown for menu, inventory, tables, and other staff
  tables is provided by the corresponding `FOR ALL` policies. Menu item
  history is read-only through RLS.
- Kitchen can read orders, order items, order status history, kitchen records,
  and only the `delayed_order_minutes` setting. It has no direct write policy
  for order status or kitchen records.
- Customers may read their own orders, order items, status history, payments,
  deliveries, reservations, feedback, complaints, enquiries and public
  enquiry responses. Their order insert policy requires a new order with
  total zero; their only order update is changing their own `New` order to
  `Cancelled`. They can insert requested reservations, own feedback,
  complaints initially `Open`, and new enquiries.
- Finance can read, insert and update payment rows but cannot delete them.
- Riders can read and update only deliveries whose `assigned_rider_id` equals
  their authenticated user ID.
- Support has all operations on complaints, enquiries and enquiry responses.
- Anonymous users can insert requested reservations only with null customer
  and table IDs, and new enquiries only with a null customer and unassigned
  staff. They cannot read either table.
- Notifications are readable by the addressed user or matching staff role
  (role-recipient reads exclude customers). Users can only mark eligible
  unread notifications read, and only the `read_at` column is granted for
  updates. Managers/admins can read and mark notifications read across the
  table. No direct insert or delete policy exists.
- `-` in the matrix applies where no matching RLS policy exists, irrespective
  of table grants.

## Gaps against SPEC.md section 5

- **Kitchen order updates:** kitchen is required to update preparation status
  and timestamps, but has read-only policies on `orders` and `kitchen_records`.
  The order-status trigger recognizes kitchen transitions, but RLS provides
  no kitchen update policy to exercise them.
- **Admin profile lifecycle:** admin can read and update profiles (including
  role assignment, subject to the self-role trigger), but cannot insert or
  delete profile rows under current grants/policies.
- **Customer profile updates:** customers can read their own profile but have
  no update policy on `profiles`, despite section 5 granting customers access
  to their own profile.
- **Anonymous flows:** the policies support anonymous enquiry and reservation
  inserts. Anonymous menu reads are available, while order creation and
  feedback require authenticated customers; if the intended public checkout
  includes guests, that is not supported by these policies.
- **Route protection:** route-level access rules in the spec are not expressed
  by these table policies and must be enforced separately by application
  routing/middleware.
- **Reporting:** this matrix covers tables, not views; section 5's finance
  reporting access cannot be confirmed from table policies alone.

No policies were changed as part of this review.
