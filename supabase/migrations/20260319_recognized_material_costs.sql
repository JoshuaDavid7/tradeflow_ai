-- Canonical material-cost accounting model.
-- Each real material cost is represented once by a recognized_material_costs
-- record.  Analytics sums canonical_cost (not raw invoice materials or raw
-- expenses), preventing double-counting.

-- ── recognized_material_costs ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.recognized_material_costs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL,
  job_id           UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
  material_index   INTEGER,
  description      TEXT NOT NULL,
  provisional_cost DOUBLE PRECISION NOT NULL,
  canonical_cost   DOUBLE PRECISION NOT NULL,
  recognition_date TIMESTAMPTZ NOT NULL,
  source           TEXT NOT NULL DEFAULT 'invoice',
  status           TEXT NOT NULL DEFAULT 'active',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  synced           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_rmc_user_status
  ON public.recognized_material_costs (user_id, status);
CREATE INDEX IF NOT EXISTS idx_rmc_job
  ON public.recognized_material_costs (job_id) WHERE job_id IS NOT NULL;

ALTER TABLE public.recognized_material_costs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own recognized costs') THEN
    CREATE POLICY "Users can view own recognized costs" ON public.recognized_material_costs FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can create own recognized costs') THEN
    CREATE POLICY "Users can create own recognized costs" ON public.recognized_material_costs FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own recognized costs') THEN
    CREATE POLICY "Users can update own recognized costs" ON public.recognized_material_costs FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete own recognized costs') THEN
    CREATE POLICY "Users can delete own recognized costs" ON public.recognized_material_costs FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ── material_cost_links ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.material_cost_links (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recognized_material_cost_id UUID NOT NULL
    REFERENCES public.recognized_material_costs(id) ON DELETE CASCADE,
  expense_id                  TEXT NOT NULL,
  allocated_amount            DOUBLE PRECISION NOT NULL,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mcl_rmc
  ON public.material_cost_links (recognized_material_cost_id);
CREATE INDEX IF NOT EXISTS idx_mcl_expense
  ON public.material_cost_links (expense_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_mcl_unique_pair
  ON public.material_cost_links (recognized_material_cost_id, expense_id);

ALTER TABLE public.material_cost_links ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage links for own costs') THEN
    CREATE POLICY "Users can manage links for own costs" ON public.material_cost_links FOR ALL
      USING (EXISTS (
        SELECT 1 FROM public.recognized_material_costs rmc
        WHERE rmc.id = material_cost_links.recognized_material_cost_id
          AND rmc.user_id = auth.uid()
      ));
  END IF;
END $$;
