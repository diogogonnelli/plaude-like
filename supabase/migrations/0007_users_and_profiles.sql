create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  is_system boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint profiles_code_format check (code ~ '^[a-z0-9_]+$')
);

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  profile_id uuid not null references public.profiles (id),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists users_email_idx
  on public.users (lower(email))
  where email is not null;

insert into public.profiles (code, name, description, is_system)
values
  ('admin', 'Administrador', 'Acesso administrativo completo ao backoffice.', true),
  ('user', 'Usuário', 'Usuário padrão do produto.', true)
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  is_system = excluded.is_system;

do $$
declare
  default_profile_id uuid;
  admin_profile_id uuid;
begin
  select id into default_profile_id
  from public.profiles
  where code = 'user'
  limit 1;

  select id into admin_profile_id
  from public.profiles
  where code = 'admin'
  limit 1;

  if default_profile_id is null or admin_profile_id is null then
    raise exception 'Default profiles were not created.';
  end if;

  insert into public.users (
    id,
    email,
    full_name,
    profile_id,
    is_active,
    created_at,
    updated_at
  )
  select
    auth_user.id,
    auth_user.email,
    coalesce(
      auth_user.raw_user_meta_data ->> 'full_name',
      auth_user.raw_user_meta_data ->> 'name'
    ),
    default_profile_id,
    true,
    coalesce(auth_user.created_at, timezone('utc', now())),
    coalesce(auth_user.updated_at, timezone('utc', now()))
  from auth.users as auth_user
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, public.users.full_name),
    updated_at = timezone('utc', now());

  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'admin_users'
  ) then
    update public.users as public_user
    set
      email = coalesce(admin_user.email, public_user.email),
      profile_id = admin_profile_id,
      updated_at = timezone('utc', now())
    from public.admin_users as admin_user
    where admin_user.user_id = public_user.id;
  end if;
end $$;

create or replace function public.sync_auth_user_to_public_users()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  default_profile_id uuid;
  resolved_full_name text;
begin
  select id into default_profile_id
  from public.profiles
  where code = 'user'
  limit 1;

  if default_profile_id is null then
    raise exception 'Default user profile was not found.';
  end if;

  resolved_full_name := coalesce(
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'name'
  );

  insert into public.users (
    id,
    email,
    full_name,
    profile_id,
    is_active,
    created_at,
    updated_at
  )
  values (
    new.id,
    new.email,
    resolved_full_name,
    default_profile_id,
    true,
    coalesce(new.created_at, timezone('utc', now())),
    coalesce(new.updated_at, timezone('utc', now()))
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = excluded.full_name,
    updated_at = timezone('utc', now());

  return new;
end;
$$;

drop trigger if exists auth_users_sync_public_users on auth.users;
create trigger auth_users_sync_public_users
after insert or update of email, raw_user_meta_data on auth.users
for each row
execute function public.sync_auth_user_to_public_users();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row
execute function public.set_updated_at();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'project_members_user_id_fkey'
      and conrelid = 'public.project_members'::regclass
  ) then
    alter table public.project_members
      add constraint project_members_user_id_fkey
      foreign key (user_id)
      references public.users (id)
      on delete cascade;
  end if;
end $$;

alter table public.profiles enable row level security;
alter table public.users enable row level security;

create policy "profiles visible to authenticated users"
on public.profiles
for select
using (auth.role() = 'authenticated');

create policy "users visible to self"
on public.users
for select
using (auth.uid() = id);

drop table if exists public.admin_users;
