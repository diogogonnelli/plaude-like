create type public.project_status as enum ('active', 'archived');
create type public.project_member_role as enum ('owner', 'member');

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status public.project_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.project_members (
  project_id uuid not null references public.projects (id) on delete cascade,
  user_id uuid not null,
  role public.project_member_role not null default 'member',
  created_at timestamptz not null default timezone('utc', now()),
  primary key (project_id, user_id)
);

alter table public.recordings
  add column if not exists project_id uuid references public.projects (id) on delete cascade,
  add column if not exists created_by_user_id uuid;

create index if not exists recordings_project_created_idx on public.recordings (project_id, created_at desc);
create index if not exists project_members_user_idx on public.project_members (user_id);

do $$
declare
  legacy_project_id uuid;
begin
  if exists (select 1 from public.recordings where project_id is null) then
    insert into public.projects (name, slug, status)
    values ('Projeto legado', 'projeto-legado', 'active')
    on conflict (slug) do update set slug = excluded.slug
    returning id into legacy_project_id;

    if legacy_project_id is null then
      select id into legacy_project_id
      from public.projects
      where slug = 'projeto-legado'
      limit 1;
    end if;

    update public.recordings
    set
      project_id = legacy_project_id,
      created_by_user_id = coalesce(created_by_user_id, user_id)
    where project_id is null;

    insert into public.project_members (project_id, user_id, role)
    select distinct legacy_project_id, coalesce(created_by_user_id, user_id), 'member'::public.project_member_role
    from public.recordings
    where project_id = legacy_project_id
    on conflict do nothing;
  end if;
end $$;

alter table public.recordings
  alter column project_id set not null,
  alter column created_by_user_id set not null;

alter table public.projects enable row level security;
alter table public.project_members enable row level security;

drop policy if exists "recordings are private to owner" on public.recordings;
drop policy if exists "transcript visible through recording owner" on public.transcript_segments;
drop policy if exists "summaries visible through recording owner" on public.summaries;
drop policy if exists "artifacts visible through recording owner" on public.note_artifacts;
drop policy if exists "chat sessions visible through recording owner" on public.chat_sessions;
drop policy if exists "chat messages visible through recording owner" on public.chat_messages;
drop policy if exists "chunks visible through recording owner" on public.recording_chunks;

create policy "projects visible to members"
on public.projects
for all
using (
  exists (
    select 1
    from public.project_members pm
    where pm.project_id = projects.id
      and pm.user_id = auth.uid()
  )
);

create policy "project members visible to members"
on public.project_members
for all
using (
  exists (
    select 1
    from public.project_members pm
    where pm.project_id = project_members.project_id
      and pm.user_id = auth.uid()
  )
);

create policy "recordings visible through project membership"
on public.recordings
for all
using (
  exists (
    select 1
    from public.project_members pm
    where pm.project_id = recordings.project_id
      and pm.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.project_members pm
    where pm.project_id = recordings.project_id
      and pm.user_id = auth.uid()
  )
);

create policy "transcript visible through project membership"
on public.transcript_segments
for all
using (
  exists (
    select 1
    from public.recordings r
    join public.project_members pm on pm.project_id = r.project_id
    where r.id = transcript_segments.recording_id
      and pm.user_id = auth.uid()
  )
);

create policy "summaries visible through project membership"
on public.summaries
for all
using (
  exists (
    select 1
    from public.recordings r
    join public.project_members pm on pm.project_id = r.project_id
    where r.id = summaries.recording_id
      and pm.user_id = auth.uid()
  )
);

create policy "artifacts visible through project membership"
on public.note_artifacts
for all
using (
  exists (
    select 1
    from public.recordings r
    join public.project_members pm on pm.project_id = r.project_id
    where r.id = note_artifacts.recording_id
      and pm.user_id = auth.uid()
  )
);

create policy "chat sessions visible through project membership"
on public.chat_sessions
for all
using (
  exists (
    select 1
    from public.recordings r
    join public.project_members pm on pm.project_id = r.project_id
    where r.id = chat_sessions.recording_id
      and pm.user_id = auth.uid()
  )
);

create policy "chat messages visible through project membership"
on public.chat_messages
for all
using (
  exists (
    select 1
    from public.chat_sessions cs
    join public.recordings r on r.id = cs.recording_id
    join public.project_members pm on pm.project_id = r.project_id
    where cs.id = chat_messages.chat_session_id
      and pm.user_id = auth.uid()
  )
);

create policy "chunks visible through project membership"
on public.recording_chunks
for all
using (
  exists (
    select 1
    from public.recordings r
    join public.project_members pm on pm.project_id = r.project_id
    where r.id = recording_chunks.recording_id
      and pm.user_id = auth.uid()
  )
);

drop policy if exists "recordings bucket is private to the owner" on storage.objects;

create policy "recordings bucket visible through project membership"
on storage.objects
for all
using (
  bucket_id = 'recordings'
  and exists (
    select 1
    from public.project_members pm
    where pm.project_id::text = split_part(name, '/', 1)
      and pm.user_id = auth.uid()
  )
)
with check (
  bucket_id = 'recordings'
  and exists (
    select 1
    from public.project_members pm
    where pm.project_id::text = split_part(name, '/', 1)
      and pm.user_id = auth.uid()
  )
);

drop trigger if exists projects_set_updated_at on public.projects;
create trigger projects_set_updated_at
before update on public.projects
for each row
execute function public.set_updated_at();

create or replace function public.get_recording_graph(recording_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'id', r.id::text,
    'userId', r.user_id::text,
    'createdByUserId', r.created_by_user_id::text,
    'projectId', r.project_id::text,
    'title', r.title,
    'sourceType', r.source_type,
    'status', r.status::text,
    'createdAt', r.created_at::text,
    'updatedAt', r.updated_at::text,
    'durationMs', r.duration_ms,
    'audioPath', r.audio_path,
    'transcriptionProvider', r.transcription_provider,
    'transcriptionJobId', r.transcription_job_id,
    'transcriptionStartedAt', r.transcription_started_at::text,
    'transcriptionCompletedAt', r.transcription_completed_at::text,
    'lastError', r.last_error,
    'transcriptSegments', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', t.id::text,
          'recordingId', t.recording_id::text,
          'speakerLabel', t.speaker_label,
          'startMs', t.start_ms,
          'endMs', t.end_ms,
          'text', t.text
        )
        order by t.start_ms
      )
      from public.transcript_segments t
      where t.recording_id = r.id
    ), '[]'::jsonb),
    'summary', (
      select jsonb_build_object(
        'overview', s.overview,
        'chapters', s.chapters
      )
      from public.summaries s
      where s.recording_id = r.id
    ),
    'noteArtifact', (
      select jsonb_build_object(
        'title', n.title,
        'tags', n.tags,
        'highlights', n.highlights,
        'actionItems', n.action_items
      )
      from public.note_artifacts n
      where n.recording_id = r.id
    ),
    'chatSession', (
      select jsonb_build_object(
        'id', cs.id::text,
        'recordingId', cs.recording_id::text,
        'messages', coalesce((
          select jsonb_agg(
            jsonb_build_object(
              'id', m.id::text,
              'role', m.role,
              'content', m.content,
              'createdAt', m.created_at::text,
              'citations', coalesce(m.citations, '[]'::jsonb)
            )
            order by m.created_at
          )
          from public.chat_messages m
          where m.chat_session_id = cs.id
        ), '[]'::jsonb)
      )
      from public.chat_sessions cs
      where cs.recording_id = r.id
    )
  )
  from public.recordings r
  where r.id = recording_id;
$$;

create or replace function public.upsert_recording_graph(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  recording_uuid uuid := (payload ->> 'id')::uuid;
  storage_user_uuid uuid := (payload ->> 'userId')::uuid;
  created_by_uuid uuid := (payload ->> 'createdByUserId')::uuid;
  project_uuid uuid := (payload ->> 'projectId')::uuid;
  transcript_item jsonb;
  message_item jsonb;
  chat_session_item jsonb;
begin
  insert into public.recordings (
    id,
    user_id,
    created_by_user_id,
    project_id,
    title,
    source_type,
    status,
    duration_ms,
    audio_path,
    transcription_provider,
    transcription_job_id,
    transcription_started_at,
    transcription_completed_at,
    last_error,
    created_at,
    updated_at
  )
  values (
    recording_uuid,
    storage_user_uuid,
    created_by_uuid,
    project_uuid,
    payload ->> 'title',
    payload ->> 'sourceType',
    (payload ->> 'status')::public.processing_status,
    nullif(payload ->> 'durationMs', '')::integer,
    payload ->> 'audioPath',
    payload ->> 'transcriptionProvider',
    payload ->> 'transcriptionJobId',
    nullif(payload ->> 'transcriptionStartedAt', '')::timestamptz,
    nullif(payload ->> 'transcriptionCompletedAt', '')::timestamptz,
    payload ->> 'lastError',
    (payload ->> 'createdAt')::timestamptz,
    (payload ->> 'updatedAt')::timestamptz
  )
  on conflict (id) do update set
    user_id = excluded.user_id,
    created_by_user_id = excluded.created_by_user_id,
    project_id = excluded.project_id,
    title = excluded.title,
    source_type = excluded.source_type,
    status = excluded.status,
    duration_ms = excluded.duration_ms,
    audio_path = excluded.audio_path,
    transcription_provider = excluded.transcription_provider,
    transcription_job_id = excluded.transcription_job_id,
    transcription_started_at = excluded.transcription_started_at,
    transcription_completed_at = excluded.transcription_completed_at,
    last_error = excluded.last_error;

  delete from public.transcript_segments where recording_id = recording_uuid;
  delete from public.summaries where recording_id = recording_uuid;
  delete from public.note_artifacts where recording_id = recording_uuid;
  delete from public.chat_messages where chat_session_id in (
    select id from public.chat_sessions where recording_id = recording_uuid
  );
  delete from public.chat_sessions where recording_id = recording_uuid;

  for transcript_item in
    select * from jsonb_array_elements(coalesce(payload -> 'transcriptSegments', '[]'::jsonb))
  loop
    insert into public.transcript_segments (
      id,
      recording_id,
      speaker_label,
      start_ms,
      end_ms,
      text
    )
    values (
      (transcript_item ->> 'id')::uuid,
      recording_uuid,
      transcript_item ->> 'speakerLabel',
      (transcript_item ->> 'startMs')::integer,
      (transcript_item ->> 'endMs')::integer,
      transcript_item ->> 'text'
    );
  end loop;

  if jsonb_typeof(payload -> 'summary') = 'object' then
    insert into public.summaries (recording_id, overview, chapters)
    values (
      recording_uuid,
      payload -> 'summary' ->> 'overview',
      coalesce(payload -> 'summary' -> 'chapters', '[]'::jsonb)
    );
  end if;

  if jsonb_typeof(payload -> 'noteArtifact') = 'object' then
    insert into public.note_artifacts (recording_id, title, tags, highlights, action_items)
    values (
      recording_uuid,
      payload -> 'noteArtifact' ->> 'title',
      coalesce(array(select jsonb_array_elements_text(payload -> 'noteArtifact' -> 'tags')), '{}'::text[]),
      coalesce(array(select jsonb_array_elements_text(payload -> 'noteArtifact' -> 'highlights')), '{}'::text[]),
      coalesce(array(select jsonb_array_elements_text(payload -> 'noteArtifact' -> 'actionItems')), '{}'::text[])
    );
  end if;

  chat_session_item := payload -> 'chatSession';
  if jsonb_typeof(chat_session_item) = 'object' then
    insert into public.chat_sessions (id, recording_id, created_at)
    values (
      (chat_session_item ->> 'id')::uuid,
      recording_uuid,
      coalesce((chat_session_item ->> 'createdAt')::timestamptz, timezone('utc', now()))
    );

    for message_item in
      select * from jsonb_array_elements(coalesce(chat_session_item -> 'messages', '[]'::jsonb))
    loop
      insert into public.chat_messages (id, chat_session_id, role, content, citations, created_at)
      values (
        (message_item ->> 'id')::uuid,
        (chat_session_item ->> 'id')::uuid,
        message_item ->> 'role',
        message_item ->> 'content',
        coalesce(message_item -> 'citations', '[]'::jsonb),
        (message_item ->> 'createdAt')::timestamptz
      );
    end loop;
  end if;

  return public.get_recording_graph(recording_uuid);
end;
$$;
