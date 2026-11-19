create type public.order_type as enum (
  'dine-in',
  'takeaway',
  'delivery'
);

create type public.order_status as enum (
  'New',
  'Confirmed',
  'Preparing',
  'Ready for Collection',
  'Ready for Delivery',
  'Completed',
  'Cancelled'
);

create type public.payment_status as enum (
  'Pending',
  'Paid',
  'Partially Paid',
  'Awaiting Verification',
  'Refunded'
);

create type public.delivery_status as enum (
  'Awaiting Assignment',
  'Assigned',
  'Preparing for Dispatch',
  'Out for Delivery',
  'Delivered',
  'Failed'
);

create type public.reservation_status as enum (
  'Requested',
  'Confirmed',
  'Rescheduled',
  'Cancelled',
  'Completed',
  'No Show'
);

create type public.complaint_category as enum (
  'Incorrect Order',
  'Missing Item',
  'Delayed Order',
  'Food Quality',
  'Delivery Problem',
  'Staff Service',
  'Other'
);

create type public.complaint_status as enum (
  'Open',
  'In Progress',
  'Resolved',
  'Closed'
);

create type public.stock_movement_type as enum (
  'Received',
  'Used',
  'Damaged',
  'Expired',
  'Adjustment'
);

create type public.enquiry_category as enum (
  'Menu',
  'Availability',
  'Order',
  'Delivery',
  'Reservation',
  'Opening Hours',
  'Complaint',
  'General'
);

create type public.enquiry_status as enum (
  'New',
  'In Progress',
  'Resolved',
  'Closed'
);
