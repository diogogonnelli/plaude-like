import { createHash } from 'node:crypto';

import type {
  ChatMessage,
  NoteArtifact,
  Recording,
  Summary,
  TranscriptSegment,
} from '../domain/types.js';

export function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

export function toStableUuid(value: string): string {
  const hash = createHash('sha256').update(value).digest('hex');
  const timeLow = hash.slice(0, 8);
  const timeMid = hash.slice(8, 12);
  const timeHi = `4${hash.slice(13, 16)}`;
  const variantNibble = ((Number.parseInt(hash[16] ?? '8', 16) & 0x3) | 0x8).toString(16);
  const clockSeq = `${variantNibble}${hash.slice(17, 20)}`;
  const node = hash.slice(20, 32);
  return `${timeLow}-${timeMid}-${timeHi}-${clockSeq}-${node}`;
}

export function resolveStorageUserId(userId: string): string {
  return isUuid(userId) ? userId : toStableUuid(`plaude-like:user:${userId}`);
}

export function serializeRecordingGraph(recording: Recording, storageUserId: string) {
  return {
    id: recording.id,
    userId: storageUserId,
    title: recording.title,
    sourceType: recording.sourceType,
    status: recording.status,
    createdAt: recording.createdAt,
    updatedAt: recording.updatedAt,
    durationMs: recording.durationMs ?? null,
    audioPath: recording.audioPath ?? null,
    lastError: recording.lastError ?? null,
    transcriptSegments: recording.transcriptSegments.map(serializeTranscriptSegment),
    summary: recording.summary ? serializeSummary(recording.summary) : null,
    noteArtifact: recording.noteArtifact ? serializeNoteArtifact(recording.noteArtifact) : null,
    chatSession: recording.chatSession ? serializeChatSession(recording.chatSession) : null,
  };
}

export function deserializeRecordingGraph(
  payload: unknown,
  fallbackUserId: string,
): Recording {
  const raw = payload as Record<string, unknown>;
  const transcriptSegments = (raw.transcriptSegments as Record<string, unknown>[] | undefined) ?? [];
  const chatSession = raw.chatSession as Record<string, unknown> | null | undefined;

  return {
    id: String(raw.id),
    userId: fallbackUserId,
    title: String(raw.title),
    sourceType: raw.sourceType as Recording['sourceType'],
    status: raw.status as Recording['status'],
    createdAt: String(raw.createdAt),
    updatedAt: String(raw.updatedAt),
    durationMs: raw.durationMs == null ? undefined : Number(raw.durationMs),
    audioPath: raw.audioPath == null ? undefined : String(raw.audioPath),
    transcriptSegments: transcriptSegments.map(deserializeTranscriptSegment),
    summary: raw.summary ? deserializeSummary(raw.summary as Record<string, unknown>) : undefined,
    noteArtifact: raw.noteArtifact
      ? deserializeNoteArtifact(raw.noteArtifact as Record<string, unknown>)
      : undefined,
    chatSession: chatSession ? deserializeChatSession(chatSession) : undefined,
    lastError: raw.lastError == null ? undefined : String(raw.lastError),
  };
}

function serializeTranscriptSegment(segment: TranscriptSegment) {
  return {
    id: segment.id,
    recordingId: segment.recordingId,
    speakerLabel: segment.speakerLabel,
    startMs: segment.startMs,
    endMs: segment.endMs,
    text: segment.text,
  };
}

function deserializeTranscriptSegment(segment: Record<string, unknown>): TranscriptSegment {
  return {
    id: String(segment.id),
    recordingId: String(segment.recordingId),
    speakerLabel: String(segment.speakerLabel),
    startMs: Number(segment.startMs),
    endMs: Number(segment.endMs),
    text: String(segment.text),
  };
}

function serializeSummary(summary: Summary) {
  return {
    overview: summary.overview,
    chapters: summary.chapters.map((chapter) => ({
      heading: chapter.heading,
      body: chapter.body,
    })),
  };
}

function deserializeSummary(summary: Record<string, unknown>): Summary {
  return {
    overview: String(summary.overview),
    chapters: ((summary.chapters as Record<string, unknown>[] | undefined) ?? []).map((chapter) => ({
      heading: String(chapter.heading),
      body: String(chapter.body),
    })),
  };
}

function serializeNoteArtifact(noteArtifact: NoteArtifact) {
  return {
    title: noteArtifact.title,
    tags: noteArtifact.tags,
    highlights: noteArtifact.highlights,
    actionItems: noteArtifact.actionItems,
  };
}

function deserializeNoteArtifact(noteArtifact: Record<string, unknown>): NoteArtifact {
  return {
    title: String(noteArtifact.title),
    tags: (noteArtifact.tags as string[] | undefined) ?? [],
    highlights: (noteArtifact.highlights as string[] | undefined) ?? [],
    actionItems: (noteArtifact.actionItems as string[] | undefined) ?? [],
  };
}

function serializeChatSession(chatSession: NonNullable<Recording['chatSession']>) {
  return {
    id: chatSession.id,
    recordingId: chatSession.recordingId,
    messages: chatSession.messages.map(serializeChatMessage),
  };
}

function deserializeChatSession(chatSession: Record<string, unknown>) {
  return {
    id: String(chatSession.id),
    recordingId: String(chatSession.recordingId),
    messages: ((chatSession.messages as Record<string, unknown>[] | undefined) ?? []).map(
      deserializeChatMessage,
    ),
  };
}

function serializeChatMessage(message: ChatMessage) {
  return {
    id: message.id,
    role: message.role,
    content: message.content,
    createdAt: message.createdAt,
    citations: message.citations ?? [],
  };
}

function deserializeChatMessage(message: Record<string, unknown>): ChatMessage {
  return {
    id: String(message.id),
    role: message.role as ChatMessage['role'],
    content: String(message.content),
    createdAt: String(message.createdAt),
    citations: ((message.citations as Record<string, unknown>[] | undefined) ?? []).map((citation) => ({
      segmentId: String(citation.segmentId),
      startMs: Number(citation.startMs),
      endMs: Number(citation.endMs),
      quote: String(citation.quote),
    })),
  };
}
