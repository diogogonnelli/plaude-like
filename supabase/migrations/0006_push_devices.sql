create table if not exists public.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists push_devices_user_idx on public.push_devices (user_id, updated_at desc);

alter table public.push_devices enable row level security;

create policy "push devices visible to owner"
on public.push_devices
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop trigger if exists push_devices_set_updated_at on public.push_devices;
create trigger push_devices_set_updated_at
before update on public.push_devices
for each row
execute function public.set_updated_at();
