export type ProcessingStatus =
  | 'uploaded'
  | 'processing_transcript'
  | 'processing_summary'
  | 'indexing'
  | 'ready'
  | 'failed';

export type ProjectStatus = 'active' | 'archived';
export type ProjectMemberRole = 'owner' | 'member';
export type RecordingSourceType = 'microphone' | 'upload' | 'desktop_meeting';
export type CaptureSourceApp = 'teams' | 'zoom' | 'meet' | 'system_audio';
export type CapturePlatform = 'windows' | 'macos';
export type CaptureMode = 'system_and_mic';

export interface CaptureMetadata {
  sourceApp: CaptureSourceApp;
  platform: CapturePlatform;
  captureMode: CaptureMode;
  helperVersion: string;
  windowTitle?: string | null;
}

export interface AccessProfile {
  id: string;
  code: string;
  name: string;
  description?: string | null;
  isSystem: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface UserRecord {
  id: string;
  email?: string | null;
  fullName?: string | null;
  profileId: string;
  profileCode: string;
  profileName: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

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
  user?: UserRecord;
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
  sourceType: RecordingSourceType;
  captureMetadata?: CaptureMetadata;
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
  sourceType: RecordingSourceType;
  captureMetadata?: CaptureMetadata;
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
