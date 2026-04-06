import type {
  AccessProfile,
  CapturePlatform,
  CaptureSourceApp,
  ChatCitation,
  CreateRecordingInput,
  ExportArtifact,
  ProcessRecordingInput,
  Project,
  ProjectMember,
  ProjectMemberRole,
  Recording,
  TranscriptSegment,
  UserRecord,
} from './types.js';

export interface RecordingRepository {
  isSupabasePersistence(): boolean;
  list(userId: string, filters?: { query?: string; tag?: string; projectId?: string }): Promise<Recording[]>;
  getById(recordingId: string, userId: string): Promise<Recording | null>;
  getAnyById(recordingId: string): Promise<Recording | null>;
  create(userId: string, input: CreateRecordingInput): Promise<Recording>;
  update(recording: Recording): Promise<Recording>;
  listProjects(userId: string): Promise<Project[]>;
  listAllProjects(filters?: { query?: string; status?: Project['status'] }): Promise<Project[]>;
  getProject(projectId: string, userId: string): Promise<Project | null>;
  getProjectById(projectId: string): Promise<Project | null>;
  createProject(userId: string, input: { name: string; slug: string }): Promise<Project>;
  updateProject(
    userId: string,
    projectId: string,
    input: { name?: string; slug?: string; status?: Project['status'] },
  ): Promise<Project>;
  listProjectMembers(requesterUserId: string, projectId: string): Promise<ProjectMember[]>;
  listProjectMembersAdmin(projectId: string): Promise<ProjectMember[]>;
  addProjectMember(
    requesterUserId: string,
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ): Promise<ProjectMember>;
  addProjectMemberAdmin(
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ): Promise<ProjectMember>;
  removeProjectMember(requesterUserId: string, projectId: string, memberUserId: string): Promise<void>;
  removeProjectMemberAdmin(projectId: string, memberUserId: string): Promise<void>;
  listUsers(filters?: {
    query?: string;
    profileId?: string;
    isActive?: boolean;
  }): Promise<UserRecord[]>;
  getUserById(userId: string): Promise<UserRecord | null>;
  saveUser(input: {
    id: string;
    email?: string | null;
    fullName?: string | null;
    profileId?: string;
    isActive?: boolean;
  }): Promise<UserRecord>;
  listProfiles(filters?: { query?: string }): Promise<AccessProfile[]>;
  getProfileById(profileId: string): Promise<AccessProfile | null>;
  getProfileByCode(code: string): Promise<AccessProfile | null>;
  createProfile(input: {
    code: string;
    name: string;
    description?: string | null;
    isSystem?: boolean;
  }): Promise<AccessProfile>;
  updateProfile(
    profileId: string,
    input: {
      code?: string;
      name?: string;
      description?: string | null;
    },
  ): Promise<AccessProfile>;
  deleteProfile(profileId: string): Promise<void>;
  listAllRecordings(filters?: {
    query?: string;
    projectId?: string;
    userId?: string;
    status?: Recording['status'];
    sourceApp?: CaptureSourceApp;
    platform?: CapturePlatform;
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
  captureMetadata?: Recording['captureMetadata'];
  filePath: string;
  fileName: string;
  mimeType?: string;
  durationMs?: number;
}
