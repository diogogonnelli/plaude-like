alter table public.recordings
  alter column project_id drop not null;

create index if not exists recordings_owner_created_idx
  on public.recordings (created_by_user_id, created_at desc);

drop policy if exists "recordings visible through project membership" on public.recordings;
drop policy if exists "transcript visible through project membership" on public.transcript_segments;
drop policy if exists "summaries visible through project membership" on public.summaries;
drop policy if exists "artifacts visible through project membership" on public.note_artifacts;
drop policy if exists "chat sessions visible through project membership" on public.chat_sessions;
drop policy if exists "chat messages visible through project membership" on public.chat_messages;
drop policy if exists "chunks visible through project membership" on public.recording_chunks;

create policy "recordings visible to owner"
on public.recordings
for all
using (auth.uid() = created_by_user_id)
with check (auth.uid() = created_by_user_id);

create policy "transcript visible to recording owner"
on public.transcript_segments
for all
using (
  exists (
    select 1
    from public.recordings r
    where r.id = transcript_segments.recording_id
      and r.created_by_user_id = auth.uid()
  )
);

create policy "summaries visible to recording owner"
on public.summaries
for all
using (
  exists (
    select 1
    from public.recordings r
    where r.id = summaries.recording_id
      and r.created_by_user_id = auth.uid()
  )
);

create policy "artifacts visible to recording owner"
on public.note_artifacts
for all
using (
  exists (
    select 1
    from public.recordings r
    where r.id = note_artifacts.recording_id
      and r.created_by_user_id = auth.uid()
  )
);

create policy "chat sessions visible to recording owner"
on public.chat_sessions
for all
using (
  exists (
    select 1
    from public.recordings r
    where r.id = chat_sessions.recording_id
      and r.created_by_user_id = auth.uid()
  )
);

create policy "chat messages visible to recording owner"
on public.chat_messages
for all
using (
  exists (
    select 1
    from public.chat_sessions cs
    join public.recordings r on r.id = cs.recording_id
    where cs.id = chat_messages.chat_session_id
      and r.created_by_user_id = auth.uid()
  )
);

create policy "chunks visible to recording owner"
on public.recording_chunks
for all
using (
  exists (
    select 1
    from public.recordings r
    where r.id = recording_chunks.recording_id
      and r.created_by_user_id = auth.uid()
  )
);

drop policy if exists "recordings bucket visible through project membership" on storage.objects;

create policy "recordings bucket visible to recording owner"
on storage.objects
for all
using (
  bucket_id = 'recordings'
  and exists (
    select 1
    from public.recordings r
    where r.id::text = split_part(name, '/', 2)
      and r.created_by_user_id = auth.uid()
  )
)
with check (
  bucket_id = 'recordings'
  and exists (
    select 1
    from public.recordings r
    where r.id::text = split_part(name, '/', 2)
      and r.created_by_user_id = auth.uid()
  )
);
