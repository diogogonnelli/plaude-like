create table if not exists public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text,
  created_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists admin_users_email_idx
  on public.admin_users (lower(email))
  where email is not null;

alter table public.admin_users enable row level security;
