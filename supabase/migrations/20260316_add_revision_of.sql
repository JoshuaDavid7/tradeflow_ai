-- Add revision_of column to jobs table.
-- When a sent invoice is "edited", the app clones it into a new draft row
-- and stores the original job's id here so the lineage is preserved.

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS revision_of UUID REFERENCES public.jobs(id);

-- Partial index — only rows that actually have a revision link.
CREATE INDEX IF NOT EXISTS idx_jobs_revision_of
  ON public.jobs (revision_of)
  WHERE revision_of IS NOT NULL;
