-- Run this in the Supabase SQL Editor if migrations are not applied automatically.
create table if not exists public.bulletin_posts (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  message text not null,
  accent text not null default 'blue',
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  constraint bulletin_posts_accent_check check (
    accent in ('blue', 'peach', 'mint', 'lavender')
  )
);

create index if not exists bulletin_posts_sort_idx
  on public.bulletin_posts (sort_order, created_at);

alter table public.bulletin_posts enable row level security;

create policy "Allow public read bulletins"
  on public.bulletin_posts for select
  using (true);

create policy "Allow public insert bulletins"
  on public.bulletin_posts for insert
  with check (true);

create policy "Allow public update bulletins"
  on public.bulletin_posts for update
  using (true)
  with check (true);

create policy "Allow public delete bulletins"
  on public.bulletin_posts for delete
  using (true);
