export type ProcessingStatus =
  | 'uploaded'
  | 'processing_transcript'
  | 'processing_summary'
  | 'indexing'
  | 'ready'
  | 'failed';

export type ProjectStatus = 'active' | 'archived';
export type ProjectMemberRole = 'owner' | 'member';

export interface Project {
  id: string;
  name: string;
  slug: string;
  status: ProjectStatus;
  createdAt: string;
  updatedAt: string;
}

export interface ProjectMember {
  projectId: string;
  userId: string;
  role: ProjectMemberRole;
  createdAt: string;
}

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
  createdByUserId: string;
  projectId: string;
  title: string;
  sourceType: 'microphone' | 'upload';
  status: ProcessingStatus;
  createdAt: string;
  updatedAt: string;
  durationMs?: number;
  audioPath?: string;
  transcriptionProvider?: 'assemblyai' | 'mock';
  transcriptionJobId?: string;
  transcriptionStartedAt?: string;
  transcriptionCompletedAt?: string;
  transcriptSegments: TranscriptSegment[];
  summary?: Summary;
  noteArtifact?: NoteArtifact;
  chatSession?: ChatSession;
  lastError?: string;
}

export interface CreateRecordingInput {
  title: string;
  projectId: string;
  sourceType: Recording['sourceType'];
  durationMs?: number;
  audioPath?: string;
  createdByUserId?: string;
  transcriptionProvider?: Recording['transcriptionProvider'];
  transcriptionJobId?: string;
  transcriptionStartedAt?: string;
  transcriptionCompletedAt?: string;
}

export interface ProcessRecordingInput {
  transcriptText?: string;
  transcriptSegments?: TranscriptSegment[];
}
