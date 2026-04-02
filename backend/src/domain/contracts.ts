import type {
  ChatCitation,
  CreateRecordingInput,
  ExportArtifact,
  ProcessRecordingInput,
  Project,
  ProjectMember,
  ProjectMemberRole,
  Recording,
  TranscriptSegment,
} from './types.js';

export interface RecordingRepository {
  list(userId: string, filters?: { query?: string; tag?: string; projectId?: string }): Promise<Recording[]>;
  getById(recordingId: string, userId: string): Promise<Recording | null>;
  create(userId: string, input: CreateRecordingInput): Promise<Recording>;
  update(recording: Recording): Promise<Recording>;
  listProjects(userId: string): Promise<Project[]>;
  getProject(projectId: string, userId: string): Promise<Project | null>;
  createProject(userId: string, input: { name: string; slug: string }): Promise<Project>;
  updateProject(
    userId: string,
    projectId: string,
    input: { name?: string; slug?: string; status?: Project['status'] },
  ): Promise<Project>;
  listProjectMembers(requesterUserId: string, projectId: string): Promise<ProjectMember[]>;
  addProjectMember(
    requesterUserId: string,
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ): Promise<ProjectMember>;
  removeProjectMember(requesterUserId: string, projectId: string, memberUserId: string): Promise<void>;
  listAllRecordings(filters?: {
    query?: string;
    projectId?: string;
    userId?: string;
    status?: Recording['status'];
  }): Promise<Recording[]>;
}

export interface AiProcessingResult {
  title: string;
  transcriptSegments: TranscriptSegment[];
  overview: string;
  chapters: Array<{
    heading: string;
    body: string;
  }>;
  tags: string[];
  highlights: string[];
  actionItems: string[];
}

export interface ChatAnswer {
  answer: string;
  citations: ChatCitation[];
}

export interface AiProvider {
  processRecording(recording: Recording, input?: ProcessRecordingInput): Promise<AiProcessingResult>;
  answerQuestion(recording: Recording, question: string): Promise<ChatAnswer>;
}

export interface ExportProvider {
  build(recording: Recording, format: 'txt' | 'md'): ExportArtifact;
}

export interface UploadAudioInput {
  title: string;
  projectId: string;
  sourceType: Recording['sourceType'];
  filePath: string;
  fileName: string;
  mimeType?: string;
  durationMs?: number;
}
