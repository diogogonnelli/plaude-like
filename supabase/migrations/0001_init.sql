create extension if not exists vector;
create extension if not exists pgcrypto;

create type public.processing_status as enum (
  'uploaded',
  'processing_transcript',
  'processing_summary',
  'indexing',
  'ready',
  'failed'
);

create table if not exists public.recordings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  source_type text not null check (source_type in ('microphone', 'upload')),
  status public.processing_status not null default 'uploaded',
  duration_ms integer,
  audio_path text,
  last_error text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.transcript_segments (
  id uuid primary key default gen_random_uuid(),
  recording_id uuid not null references public.recordings (id) on delete cascade,
  speaker_label text not null,
  start_ms integer not null,
  end_ms integer not null,
  text text not null
);

create table if not exists public.summaries (
  recording_id uuid primary key references public.recordings (id) on delete cascade,
  overview text not null,
  chapters jsonb not null default '[]'::jsonb
);

create table if not exists public.note_artifacts (
  recording_id uuid primary key references public.recordings (id) on delete cascade,
  title text not null,
  tags text[] not null default '{}',
  highlights text[] not null default '{}',
  action_items text[] not null default '{}'
);

create table if not exists public.chat_sessions (
  id uuid primary key default gen_random_uuid(),
  recording_id uuid not null unique references public.recordings (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_session_id uuid not null references public.chat_sessions (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  citations jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.recording_chunks (
  id uuid primary key default gen_random_uuid(),
  recording_id uuid not null references public.recordings (id) on delete cascade,
  chunk_text text not null,
  start_ms integer,
  end_ms integer,
  embedding vector(1536)
);

create index if not exists recordings_user_created_idx on public.recordings (user_id, created_at desc);
create index if not exists transcript_segments_recording_idx on public.transcript_segments (recording_id, start_ms);
create index if not exists recording_chunks_recording_idx on public.recording_chunks (recording_id);
create index if not exists recording_chunks_embedding_idx
  on public.recording_chunks using ivfflat (embedding vector_cosine_ops) with (lists = 100);

alter table public.recordings enable row level security;
alter table public.transcript_segments enable row level security;
alter table public.summaries enable row level security;
alter table public.note_artifacts enable row level security;
alter table public.chat_sessions enable row level security;
alter table public.chat_messages enable row level security;
alter table public.recording_chunks enable row level security;

create policy "recordings are private to owner"
on public.recordings
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "transcript visible through recording owner"
on public.transcript_segments
for all
using (
  exists (
    select 1
    from public.recordings
    where recordings.id = transcript_segments.recording_id
      and recordings.user_id = auth.uid()
  )
);

create policy "summaries visible through recording owner"
on public.summaries
for all
using (
  exists (
    select 1
    from public.recordings
    where recordings.id = summaries.recording_id
      and recordings.user_id = auth.uid()
  )
);

create policy "artifacts visible through recording owner"
on public.note_artifacts
for all
using (
  exists (
    select 1
    from public.recordings
    where recordings.id = note_artifacts.recording_id
      and recordings.user_id = auth.uid()
  )
);

create policy "chat sessions visible through recording owner"
on public.chat_sessions
for all
using (
  exists (
    select 1
    from public.recordings
    where recordings.id = chat_sessions.recording_id
      and recordings.user_id = auth.uid()
  )
);

create policy "chat messages visible through recording owner"
on public.chat_messages
for all
using (
  exists (
    select 1
    from public.chat_sessions
    join public.recordings on recordings.id = chat_sessions.recording_id
    where chat_sessions.id = chat_messages.chat_session_id
      and recordings.user_id = auth.uid()
  )
);

create policy "chunks visible through recording owner"
on public.recording_chunks
for all
using (
  exists (
    select 1
    from public.recordings
    where recordings.id = recording_chunks.recording_id
      and recordings.user_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public)
values ('recordings', 'recordings', false)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public;

create policy "recordings bucket is private to the owner"
on storage.objects
for all
using (
  bucket_id = 'recordings'
  and auth.uid()::text = split_part(name, '/', 1)
)
with check (
  bucket_id = 'recordings'
  and auth.uid()::text = split_part(name, '/', 1)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists recordings_set_updated_at on public.recordings;
create trigger recordings_set_updated_at
before update on public.recordings
for each row
execute function public.set_updated_at();
