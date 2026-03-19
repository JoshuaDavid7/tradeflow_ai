-- Receipt cloud backup + metadata persistence.
-- Safe to run repeatedly.

create table if not exists public.receipts (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  expense_id text,
  job_id text,
  image_path text not null,
  image_url text,
  thumbnail_path text,
  ocr_text text,
  extracted_amount numeric,
  extracted_vendor text,
  extracted_date timestamptz,
  ocr_status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.receipts
  add column if not exists expense_id text,
  add column if not exists job_id text,
  add column if not exists image_path text,
  add column if not exists image_url text,
  add column if not exists thumbnail_path text,
  add column if not exists ocr_text text,
  add column if not exists extracted_amount numeric,
  add column if not exists extracted_vendor text,
  add column if not exists extracted_date timestamptz,
  add column if not exists ocr_status text,
  add column if not exists created_at timestamptz,
  add column if not exists updated_at timestamptz;

create index if not exists receipts_user_id_created_at_idx
  on public.receipts (user_id, created_at desc);

create index if not exists receipts_expense_id_idx
  on public.receipts (expense_id);

create index if not exists receipts_job_id_idx
  on public.receipts (job_id);

alter table public.receipts enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'receipts'
      and policyname = 'Receipts select own'
  ) then
    create policy "Receipts select own"
      on public.receipts
      for select
      using (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'receipts'
      and policyname = 'Receipts insert own'
  ) then
    create policy "Receipts insert own"
      on public.receipts
      for insert
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'receipts'
      and policyname = 'Receipts update own'
  ) then
    create policy "Receipts update own"
      on public.receipts
      for update
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'receipts'
      and policyname = 'Receipts delete own'
  ) then
    create policy "Receipts delete own"
      on public.receipts
      for delete
      using (auth.uid() = user_id);
  end if;
end
$$;

-- Private storage bucket for receipt images.
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do update set public = excluded.public;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Receipts objects select own'
  ) then
    create policy "Receipts objects select own"
      on storage.objects
      for select
      using (
        bucket_id = 'receipts'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Receipts objects insert own'
  ) then
    create policy "Receipts objects insert own"
      on storage.objects
      for insert
      with check (
        bucket_id = 'receipts'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Receipts objects update own'
  ) then
    create policy "Receipts objects update own"
      on storage.objects
      for update
      using (
        bucket_id = 'receipts'
        and (storage.foldername(name))[1] = auth.uid()::text
      )
      with check (
        bucket_id = 'receipts'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Receipts objects delete own'
  ) then
    create policy "Receipts objects delete own"
      on storage.objects
      for delete
      using (
        bucket_id = 'receipts'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end
$$;
