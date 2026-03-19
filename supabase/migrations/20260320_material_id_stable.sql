-- Replace fragile material_index (array position) with a stable material_id UUID.
-- Each material line item in the invoice JSON now carries its own UUID.

ALTER TABLE public.recognized_material_costs
  ADD COLUMN IF NOT EXISTS material_id TEXT;

-- material_index is no longer the canonical identifier.
-- Keep it for backward compat but stop relying on it.
