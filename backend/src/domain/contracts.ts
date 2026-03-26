import type {
  ChatCitation,
  CreateRecordingInput,
  ExportArtifact,
  ProcessRecordingInput,
  Recording,
  TranscriptSegment,
} from './types.js';

export interface RecordingRepository {
  list(userId: string, filters?: { query?: string; tag?: string }): Promise<Recording[]>;
  getById(recordingId: string, userId: string): Promise<Recording | null>;
  create(userId: string, input: CreateRecordingInput): Promise<Recording>;
  update(recording: Recording): Promise<Recording>;
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
