-- FTR rebuild v0.2 - Supabase/Postgres core schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.contents (
  id uuid primary key default gen_random_uuid(),
  legacy_screen_id text unique,
  slug text unique not null,
  title text not null,
  summary text,
  body_html text,
  content_kind text not null default 'article' check (content_kind in ('article','exercise','quiz','glossary','media','external_archive')),
  premium boolean not null default false,
  status text not null default 'draft' check (status in ('draft','review','published','archived')),
  source_url text,
  source_last_reviewed_at timestamptz,
  medical_review_status text not null default 'pending' check (medical_review_status in ('pending','reviewed','needs_update','archived')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.content_categories (
  content_id uuid not null references public.contents(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  is_primary boolean not null default false,
  primary key (content_id, category_id)
);

create table if not exists public.content_assets (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.contents(id) on delete cascade,
  asset_type text not null check (asset_type in ('image','video','pdf','file')),
  storage_path text not null,
  caption text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  content_id uuid not null references public.contents(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, content_id)
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  content_id uuid references public.contents(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  content_id uuid not null references public.contents(id) on delete cascade,
  progress numeric(5,4) not null default 0 check (progress >= 0 and progress <= 1),
  last_position text,
  updated_at timestamptz not null default now(),
  primary key (user_id, content_id)
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('google_play','app_store','admin')),
  product_id text not null,
  status text not null check (status in ('active','grace','paused','expired','revoked','pending')),
  original_transaction_id text,
  purchase_token_hash text,
  starts_at timestamptz,
  expires_at timestamptz,
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.purchase_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  platform text not null,
  product_id text,
  event_type text not null,
  provider_event_id text unique,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.contents enable row level security;
alter table public.content_categories enable row level security;
alter table public.content_assets enable row level security;
alter table public.favorites enable row level security;
alter table public.notes enable row level security;
alter table public.user_progress enable row level security;
alter table public.subscriptions enable row level security;
alter table public.purchase_events enable row level security;

-- Public catalog metadata; premium body access should be mediated by a secure RPC/view or Edge Function.
create policy "categories readable" on public.categories for select using (is_active = true);
create policy "published content metadata readable" on public.contents for select using (status = 'published');
create policy "content category map readable" on public.content_categories for select using (true);
create policy "content assets metadata readable" on public.content_assets for select using (true);

create policy "profile owner select" on public.profiles for select using (auth.uid() = id);
create policy "profile owner update" on public.profiles for update using (auth.uid() = id);
create policy "favorite owner all" on public.favorites for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "note owner all" on public.notes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "progress owner all" on public.user_progress for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "subscription owner select" on public.subscriptions for select using (auth.uid() = user_id);

-- purchase_events intentionally has no client write policy; trusted server/Edge Function only.
