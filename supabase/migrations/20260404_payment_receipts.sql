-- Payment receipts: one receipt per payment event
CREATE TABLE IF NOT EXISTS payment_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id TEXT NOT NULL,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receipt_number TEXT NOT NULL,

  -- Business info
  business_name TEXT NOT NULL DEFAULT '',
  business_address TEXT,
  business_phone TEXT,
  business_email TEXT,

  -- Customer info
  customer_name TEXT NOT NULL DEFAULT '',
  customer_email TEXT,

  -- Invoice info
  invoice_number TEXT NOT NULL DEFAULT '',
  invoice_total NUMERIC(12,2) NOT NULL DEFAULT 0,

  -- Payment info
  payment_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'other',
  transaction_reference TEXT,
  payment_date TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Balance info
  balance_before NUMERIC(12,2) NOT NULL DEFAULT 0,
  balance_after NUMERIC(12,2) NOT NULL DEFAULT 0,
  is_fully_paid BOOLEAN NOT NULL DEFAULT false,

  -- Storage
  pdf_url TEXT,
  pdf_path TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Prevent duplicate receipts for the same payment event
  UNIQUE(payment_id)
);

-- RLS policies
ALTER TABLE payment_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own receipts"
  ON payment_receipts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own receipts"
  ON payment_receipts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Index for fast lookups by job
CREATE INDEX IF NOT EXISTS idx_payment_receipts_job_id ON payment_receipts(job_id);
CREATE INDEX IF NOT EXISTS idx_payment_receipts_user_id ON payment_receipts(user_id);
