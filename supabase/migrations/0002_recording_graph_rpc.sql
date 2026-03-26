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
    'title', r.title,
    'sourceType', r.source_type,
    'status', r.status::text,
    'createdAt', r.created_at::text,
    'updatedAt', r.updated_at::text,
    'durationMs', r.duration_ms,
    'audioPath', r.audio_path,
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
  transcript_item jsonb;
  message_item jsonb;
  chat_session_item jsonb;
begin
  insert into public.recordings (
    id,
    user_id,
    title,
    source_type,
    status,
    duration_ms,
    audio_path,
    last_error,
    created_at,
    updated_at
  )
  values (
    recording_uuid,
    storage_user_uuid,
    payload ->> 'title',
    payload ->> 'sourceType',
    (payload ->> 'status')::public.processing_status,
    nullif(payload ->> 'durationMs', '')::integer,
    payload ->> 'audioPath',
    payload ->> 'lastError',
    (payload ->> 'createdAt')::timestamptz,
    (payload ->> 'updatedAt')::timestamptz
  )
  on conflict (id) do update set
    user_id = excluded.user_id,
    title = excluded.title,
    source_type = excluded.source_type,
    status = excluded.status,
    duration_ms = excluded.duration_ms,
    audio_path = excluded.audio_path,
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

  if payload ? 'summary' and payload -> 'summary' is not null then
    insert into public.summaries (recording_id, overview, chapters)
    values (
      recording_uuid,
      payload -> 'summary' ->> 'overview',
      coalesce(payload -> 'summary' -> 'chapters', '[]'::jsonb)
    );
  end if;

  if payload ? 'noteArtifact' and payload -> 'noteArtifact' is not null then
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
  if chat_session_item is not null then
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
