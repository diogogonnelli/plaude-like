export type ProcessingStatus =
  | 'uploaded'
  | 'processing_transcript'
  | 'processing_summary'
  | 'indexing'
  | 'ready'
  | 'failed';

export interface TranscriptSegment {
  id: string;
  recordingId: string;
  speakerLabel: string;
  startMs: number;
  endMs: number;
  text: string;
}

export interface NoteArtifact {
  title: string;
  tags: string[];
  highlights: string[];
  actionItems: string[];
}

export interface Summary {
  overview: string;
  chapters: Array<{
    heading: string;
    body: string;
  }>;
}

export interface ChatCitation {
  segmentId: string;
  startMs: number;
  endMs: number;
  quote: string;
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  createdAt: string;
  citations?: ChatCitation[];
}

export interface ChatSession {
  id: string;
  recordingId: string;
  messages: ChatMessage[];
}

export interface ExportArtifact {
  format: 'txt' | 'md';
  fileName: string;
  contentType: string;
  body: string;
}

export interface Recording {
  id: string;
  userId: string;
  title: string;
  sourceType: 'microphone' | 'upload';
  status: ProcessingStatus;
  createdAt: string;
  updatedAt: string;
  durationMs?: number;
  audioPath?: string;
  transcriptSegments: TranscriptSegment[];
  summary?: Summary;
  noteArtifact?: NoteArtifact;
  chatSession?: ChatSession;
  lastError?: string;
}

export interface CreateRecordingInput {
  title: string;
  sourceType: Recording['sourceType'];
  durationMs?: number;
  audioPath?: string;
}

export interface ProcessRecordingInput {
  transcriptText?: string;
}
