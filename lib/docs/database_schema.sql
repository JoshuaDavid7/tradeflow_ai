-- TRADEFLOW AI - DATABASE SCHEMA V1.2 (SUBSCRIPTION READY)
-- Purpose: Support SaaS features, AI-extracted job data, and CRM linking.

-- Cleanup existing tables (WARNING: This deletes existing data)
DROP TABLE IF EXISTS public.jobs;
DROP TABLE IF EXISTS public.customers;
DROP TABLE IF EXISTS public.profiles;

-- 1. Profiles: Business details and subscription tier
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  business_name text default 'My Trade Business',
  business_address text,
  business_phone text,
  business_email text,
  tax_id text,
  hourly_rate numeric default 85.0,
  tax_rate numeric default 0.0,
  currency_symbol text default '$',
  
  -- Subscription & Pro Logic
  is_pro boolean default false,
  subscription_status text default 'none', -- e.g., 'active', 'trialing', 'none'
  
  updated_at timestamp with time zone default now()
);

-- 2. Customers: Basic CRM for client tracking
create table public.customers (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  email text,
  phone text,
  address text,
  notes text,
  created_at timestamp with time zone default now()
);

-- 3. Jobs: Worksheets, Invoices, and Quotes
create table public.jobs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  customer_id uuid references public.customers(id) on delete set null,
  
  -- Denormalized for fast history lookups
  client_name text, 
  
  title text not null,
  description text,
  trade text,
  status text default 'draft', -- 'draft', 'sent', 'paid', 'cancelled'
  type text default 'invoice', -- 'invoice', 'quote'
  
  -- Financial Snapshot (captures rates at time of creation)
  labor_hours numeric default 0,
  hourly_rate_at_time numeric,
  materials jsonb default '[]'::jsonb,
  tax_rate_at_time numeric default 0,
  total_amount numeric default 0,
  
  created_at timestamp with time zone default now()
);

-- Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.jobs enable row level security;

-- Policies: Ensure users only see their own data
create policy "Users can manage their own profile" on public.profiles for all using (auth.uid() = id);
create policy "Users can manage their own customers" on public.customers for all using (auth.uid() = user_id);
create policy "Users can manage their own jobs" on public.jobs for all using (auth.uid() = user_id);