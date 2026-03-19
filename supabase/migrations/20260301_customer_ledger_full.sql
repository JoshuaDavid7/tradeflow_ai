-- Customer Ledger: Add missing columns to customers, project_notes tables
-- and create the projects table for full ledger functionality.

-- ========================================================================
-- 1. CUSTOMERS TABLE: add financial summary & updated_at columns
-- ========================================================================
ALTER TABLE public.customers
  ADD COLUMN IF NOT EXISTS total_billed NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_paid   NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS balance      NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS job_count    INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at   TIMESTAMPTZ DEFAULT now();

-- Index for ledger list (ordered by last update)
CREATE INDEX IF NOT EXISTS idx_customers_user_updated
  ON public.customers(user_id, updated_at DESC);

-- ========================================================================
-- 2. PROJECT_NOTES TABLE: add customer_id and project_id columns
-- ========================================================================
ALTER TABLE public.project_notes
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS project_id  UUID;

-- Index for customer-scoped note lookups
CREATE INDEX IF NOT EXISTS idx_project_notes_customer
  ON project_notes(customer_id);

-- ========================================================================
-- 3. PROJECTS TABLE: create if it does not exist
-- ========================================================================
CREATE TABLE IF NOT EXISTS public.projects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  description TEXT,
  status      TEXT DEFAULT 'active',   -- 'active', 'completed', 'archived'
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_projects_user
  ON public.projects(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_customer
  ON public.projects(customer_id);

-- RLS
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own projects"
  ON public.projects FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own projects"
  ON public.projects FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects"
  ON public.projects FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own projects"
  ON public.projects FOR DELETE
  USING (auth.uid() = user_id);

-- ========================================================================
-- 4. Add project_id foreign key to project_notes (now that projects exists)
-- ========================================================================
-- We do NOT add a FK constraint here because project_id may reference
-- projects that are later deleted. The column was already added above.

-- ========================================================================
-- 5. Backfill: update customers.updated_at to created_at where NULL
-- ========================================================================
UPDATE public.customers
SET updated_at = COALESCE(created_at, now())
WHERE updated_at IS NULL;
