-- Add document default columns to profiles table
-- These drive invoice/quote generation, PDF due dates, and material markup.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS quote_prefix TEXT NOT NULL DEFAULT 'QUO',
  ADD COLUMN IF NOT EXISTS default_due_days INTEGER NOT NULL DEFAULT 14,
  ADD COLUMN IF NOT EXISTS default_markup_percent DOUBLE PRECISION NOT NULL DEFAULT 0.0;

-- Ensure invoice_prefix has a sane default for any existing rows that are NULL
UPDATE public.profiles
  SET invoice_prefix = 'INV'
  WHERE invoice_prefix IS NULL;
