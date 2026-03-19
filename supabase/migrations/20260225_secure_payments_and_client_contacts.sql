-- Secure payment checkout + webhook tracking fields for jobs
-- Also adds optional client contact fields used on invoices.

alter table if exists public.jobs
  add column if not exists client_address text,
  add column if not exists client_phone text,
  add column if not exists client_email text,
  add column if not exists payment_provider text,
  add column if not exists payment_checkout_url text,
  add column if not exists payment_checkout_session_id text,
  add column if not exists payment_checkout_expires_at timestamptz,
  add column if not exists payment_status text,
  add column if not exists payment_currency text,
  add column if not exists payment_amount_minor integer,
  add column if not exists payment_paid_at timestamptz,
  add column if not exists last_payment_event_id text,
  add column if not exists secure_payment_methods jsonb;

create index if not exists jobs_payment_checkout_session_id_idx
  on public.jobs (payment_checkout_session_id);

create index if not exists jobs_payment_status_idx
  on public.jobs (payment_status);

create table if not exists public.stripe_webhook_events (
  id text primary key,
  event_type text not null,
  livemode boolean,
  payload jsonb not null,
  received_at timestamptz not null default now()
);

-- Helpful index for dashboard / troubleshooting lookups
create index if not exists stripe_webhook_events_received_at_idx
  on public.stripe_webhook_events (received_at desc);
