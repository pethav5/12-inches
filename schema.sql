-- ═══════════════════════════════════════════════════════════════════
--  12 Inches — database schema
--  Paste this whole file into Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════

-- ── Records ────────────────────────────────────────────────────────
create table if not exists public.records (
  id          bigserial primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  discogs_id  bigint not null,
  title       text not null,
  year        text,
  format      text,
  thumb       text,
  price       numeric default 0,
  price_date  timestamptz,
  added       timestamptz default now(),
  genres      text[]  default '{}',
  styles      text[]  default '{}',
  artists     jsonb   default '[]',
  unique (user_id, discogs_id)
);

-- ── Listens ────────────────────────────────────────────────────────
create table if not exists public.listens (
  id          bigserial primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  discogs_id  bigint not null,
  title       text,
  thumb       text,
  ts          timestamptz not null default now(),
  mood        text[],
  body        text[],
  intensity   int,
  note        text
);

-- ── Per-user settings ──────────────────────────────────────────────
create table if not exists public.settings (
  user_id          uuid primary key references auth.users(id) on delete cascade,
  discogs_token    text,
  discogs_username text,
  play_period      text    default 'all',
  auto_update      boolean default true,
  stale_days       int     default 7,
  ask_mood         boolean default true,
  updated_at       timestamptz default now()
);

-- ── Indexes ────────────────────────────────────────────────────────
create index if not exists records_user_idx on public.records (user_id);
create index if not exists listens_user_ts_idx on public.listens (user_id, ts desc);

-- ── Row Level Security ─────────────────────────────────────────────
alter table public.records  enable row level security;
alter table public.listens  enable row level security;
alter table public.settings enable row level security;

drop policy if exists "own records"  on public.records;
drop policy if exists "own listens"  on public.listens;
drop policy if exists "own settings" on public.settings;

create policy "own records" on public.records
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own listens" on public.listens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own settings" on public.settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
