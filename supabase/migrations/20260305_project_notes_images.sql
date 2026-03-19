-- Add images support to project_notes for photo attachments
-- Images stored as JSONB array: [{"url": "signed_url", "path": "storage_path", "created_at": "iso8601"}]

ALTER TABLE public.project_notes
  ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.project_notes.images IS
  'JSON array of image objects: [{"url": "signed_url", "path": "storage_path", "created_at": "iso8601"}]';
