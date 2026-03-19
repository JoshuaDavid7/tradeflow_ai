-- Separate document state from payment state.
-- The `status` column now tracks document lifecycle only: draft → sent → cancelled.
-- Payment state is derived from amount_paid vs total_amount.
-- Existing 'paid' rows are reverted to 'sent' (they were sent documents that
-- happened to be fully paid).

UPDATE public.jobs
   SET status = 'sent'
 WHERE status = 'paid';
