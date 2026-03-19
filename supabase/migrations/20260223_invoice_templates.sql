-- Invoice Templates table: stores user-customisable invoice/quote templates
create table if not exists public.invoice_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  name text default 'My Template',
  settings jsonb default '{}',
  updated_at timestamp with time zone default now()
);

-- RLS: each user can only access their own templates
alter table public.invoice_templates enable row level security;

create policy "Users can view own templates"
  on public.invoice_templates for select
  using (auth.uid() = user_id);

create policy "Users can insert own templates"
  on public.invoice_templates for insert
  with check (auth.uid() = user_id);

create policy "Users can update own templates"
  on public.invoice_templates for update
  using (auth.uid() = user_id);

create policy "Users can delete own templates"
  on public.invoice_templates for delete
  using (auth.uid() = user_id);

-- Logos storage bucket (public so the PDF renderer can fetch images)
insert into storage.buckets (id, name, public)
values ('logos', 'logos', true)
on conflict (id) do nothing;

-- Storage RLS: users can upload/overwrite their own logo (path starts with their user id)
create policy "Users can upload own logo"
  on storage.objects for insert
  with check (bucket_id = 'logos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can update own logo"
  on storage.objects for update
  using (bucket_id = 'logos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Anyone can view logos"
  on storage.objects for select
  using (bucket_id = 'logos');
