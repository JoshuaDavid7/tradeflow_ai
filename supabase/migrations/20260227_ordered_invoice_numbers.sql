-- Ordered invoice numbers + editable invoice_number field.
-- Adds a per-user atomic sequence reserver so invoice numbers are deterministic.

alter table if exists public.jobs
  add column if not exists invoice_sequence bigint,
  add column if not exists invoice_number text;

create unique index if not exists jobs_user_invoice_sequence_unique
  on public.jobs (user_id, invoice_sequence)
  where invoice_sequence is not null;

create index if not exists jobs_invoice_number_idx
  on public.jobs (invoice_number);

alter table if exists public.profiles
  add column if not exists invoice_prefix text not null default 'INV',
  add column if not exists next_invoice_number bigint not null default 1;

update public.profiles
set invoice_prefix = 'INV'
where invoice_prefix is null or btrim(invoice_prefix) = '';

update public.profiles
set next_invoice_number = 1
where next_invoice_number is null or next_invoice_number < 1;

create or replace function public.reserve_invoice_sequence()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  reserved_sequence bigint;
  reserved_prefix text;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  insert into public.profiles (id)
  values (current_user_id)
  on conflict (id) do nothing;

  update public.profiles
  set next_invoice_number = greatest(coalesce(next_invoice_number, 1), 1) + 1,
      invoice_prefix = coalesce(nullif(invoice_prefix, ''), 'INV')
  where id = current_user_id
  returning next_invoice_number - 1, invoice_prefix
  into reserved_sequence, reserved_prefix;

  if reserved_sequence is null then
    raise exception 'Unable to reserve invoice number';
  end if;

  return jsonb_build_object(
    'invoice_sequence', reserved_sequence,
    'invoice_prefix', reserved_prefix
  );
end;
$$;

revoke all on function public.reserve_invoice_sequence() from public;
grant execute on function public.reserve_invoice_sequence() to authenticated;
