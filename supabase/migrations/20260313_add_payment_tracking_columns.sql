-- Add payment tracking columns to the jobs table.
-- These are needed by recordPayment() to track partial payments and
-- by the dashboard to compute Awaiting Payment and Collected correctly.

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS amount_paid NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS amount_due  NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS paid_at     TIMESTAMPTZ;

-- Backfill existing paid jobs: amount_paid = total, amount_due = 0
UPDATE public.jobs
SET amount_paid = total_amount,
    amount_due  = 0
WHERE status = 'paid'
  AND (amount_paid IS NULL OR amount_paid = 0);

-- Backfill existing unpaid jobs: amount_due = total_amount
UPDATE public.jobs
SET amount_due = total_amount
WHERE status != 'paid'
  AND (amount_due IS NULL OR amount_due = 0);
