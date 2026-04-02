import { randomUUID } from 'node:crypto';
import { unlink } from 'node:fs/promises';

import type { AiProvider, ExportProvider, RecordingRepository, UploadAudioInput } from '../domain/contracts.js';
import type {
  ChatMessage,
  CreateRecordingInput,
  ProcessRecordingInput,
  Project,
  ProjectMemberRole,
  Recording,
} from '../domain/types.js';
import { config } from '../lib/config.js';
import { hasSupabasePersistenceConfig, uploadAudioToStorage } from '../lib/supabase-admin.js';
import { AssemblyAiTranscriptionProvider } from './assemblyai-transcription-provider.js';
import { NoopPushNotificationService, type PushNotificationServiceLike } from './push-notification-service.js';
import { ServiceError, isRetryableError, withRetries } from './service-errors.js';

function extractTranscriptText(recording: Recording): string {
  return recording.transcriptSegments
    .map((segment) => `${segment.speakerLabel}: ${segment.text}`)
    .join('\n')
    .trim();
}

function buildGroundedCitations(recording: Recording, question: string) {
  const questionTerms = question
    .toLowerCase()
    .split(/[^a-z0-9]+/i)
    .filter((term) => term.length >= 4);

  const rankedSegments = recording.transcriptSegments
    .map((segment) => {
      const text = segment.text.toLowerCase();
      const transcriptScore = questionTerms.reduce(
        (sum, term) => sum + (text.includes(term) ? 1 : 0),
        0,
      );
      const actionScore = recording.noteArtifact?.actionItems.some((item) =>
        questionTerms.some((term) => item.toLowerCase().includes(term)),
      )
        ? 1
        : 0;

      return { segment, score: transcriptScore + actionScore };
    })
    .sort((left, right) => right.score - left.score);

  const selected = rankedSegments.filter((item) => item.score > 0).slice(0, 3);
  const fallback = recording.transcriptSegments.slice(0, 2).map((segment) => ({ segment, score: 0 }));
  const finalSelection = selected.length > 0 ? selected : fallback;

  return finalSelection.map(({ segment }) => ({
    segmentId: segment.id,
    startMs: segment.startMs,
    endMs: segment.endMs,
    quote: segment.text,
  }));
}

export class RecordingService {
  private readonly assemblyAi = new AssemblyAiTranscriptionProvider();

  constructor(
    private readonly repository: RecordingRepository,
    private readonly aiProvider: AiProvider,
    private readonly exportProvider: ExportProvider,
    private readonly pushNotifications: PushNotificationServiceLike = new NoopPushNotificationService(),
  ) {}

  list(userId: string, filters?: { query?: string; tag?: string; projectId?: string }) {
    return this.repository.list(userId, filters);
  }

  listProjects(userId: string) {
    return this.repository.listProjects(userId);
  }

  listAdminProjects(filters?: { query?: string; status?: Project['status'] }) {
    return this.repository.listAllProjects(filters);
  }

  async getProjectOrThrow(projectId: string, userId: string): Promise<Project> {
    const project = await this.repository.getProject(projectId, userId);
    if (!project) {
      throw new ServiceError('Project not found', 404, 'project_not_found', { projectId });
    }

    return project;
  }

  async getAdminProjectOrThrow(projectId: string): Promise<Project> {
    const project = await this.repository.getProjectById(projectId);
    if (!project) {
      throw new ServiceError('Project not found', 404, 'project_not_found', { projectId });
    }

    return project;
  }

  createProject(userId: string, input: { name: string; slug: string }) {
    return this.repository.createProject(userId, input);
  }

  updateProject(
    userId: string,
    projectId: string,
    input: { name?: string; slug?: string; status?: Project['status'] },
  ) {
    return this.repository.updateProject(userId, projectId, input);
  }

  listProjectMembers(userId: string, projectId: string) {
    return this.repository.listProjectMembers(userId, projectId);
  }

  listProjectMembersAdmin(projectId: string) {
    return this.repository.listProjectMembersAdmin(projectId);
  }

  addProjectMember(
    userId: string,
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ) {
    return this.repository.addProjectMember(userId, projectId, member);
  }

  addProjectMemberAdmin(
    projectId: string,
    member: { userId: string; role: ProjectMemberRole },
  ) {
    return this.repository.addProjectMemberAdmin(projectId, member);
  }

  removeProjectMember(userId: string, projectId: string, memberUserId: string) {
    return this.repository.removeProjectMember(userId, projectId, memberUserId);
  }

  removeProjectMemberAdmin(projectId: string, memberUserId: string) {
    return this.repository.removeProjectMemberAdmin(projectId, memberUserId);
  }

  listAdminRecordings(filters?: {
    query?: string;
    projectId?: string;
    userId?: string;
    status?: Recording['status'];
  }) {
    return this.repository.listAllRecordings(filters);
  }

  async getAdminRecordingOrThrow(recordingId: string): Promise<Recording> {
    const recording = await this.repository.getAnyById(recordingId);
    if (!recording) {
      throw new ServiceError('Recording not found', 404, 'recording_not_found', {
        recordingId,
      });
    }

    return recording;
  }

  async getOrThrow(recordingId: string, userId: string): Promise<Recording> {
    const recording = await this.repository.getById(recordingId, userId);
    if (!recording) {
      throw new ServiceError('Recording not found', 404, 'recording_not_found', {
        recordingId,
      });
    }

    return recording;
  }

  create(userId: string, input: CreateRecordingInput) {
    return this.repository.create(userId, input);
  }

  async uploadAndStartTranscription(userId: string, input: UploadAudioInput): Promise<Recording> {
    const startedAt = new Date().toISOString();
    let recording = await this.repository.create(userId, {
      title: input.title,
      projectId: input.projectId,
      sourceType: input.sourceType,
      durationMs: input.durationMs,
      audioPath: input.fileName,
      createdByUserId: userId,
      transcriptionProvider: config.TRANSCRIPTION_PROVIDER === 'assemblyai' ? 'assemblyai' : 'mock',
      transcriptionStartedAt: startedAt,
    });

    recording.status = 'processing_transcript';
    recording = await this.repository.update(recording);

    if (config.TRANSCRIPTION_PROVIDER === 'assemblyai') {
      if (!hasSupabasePersistenceConfig()) {
        recording.status = 'failed';
        recording.lastError = 'Supabase persistence is required for audio retention when using AssemblyAI.';
        await this.repository.update(recording);
        await unlink(input.filePath).catch(() => undefined);
        throw new ServiceError(
          'Supabase persistence is required for audio retention when using AssemblyAI.',
          500,
          'supabase_storage_required',
        );
      }

      try {
        const objectPath = buildAudioObjectPath(recording.projectId, recording.id, input.fileName);
        await uploadAudioToStorage({
          objectPath,
          filePath: input.filePath,
          contentType: input.mimeType,
        });

        const audioUrl = await this.assemblyAi.uploadFile(input.filePath, input.mimeType);
        const transcriptJobId = await this.assemblyAi.createTranscript({
          audioUrl,
          recordingId: recording.id,
          userId,
        });
        return await this.repository.update({
          ...recording,
          audioPath: objectPath,
          transcriptionProvider: 'assemblyai',
          transcriptionJobId: transcriptJobId,
          transcriptionStartedAt: startedAt,
        });
      } catch (error) {
        recording.status = 'failed';
        recording.lastError = error instanceof Error ? error.message : 'AssemblyAI upload failed.';
        await this.repository.update(recording);
        throw error;
      } finally {
        await unlink(input.filePath).catch(() => undefined);
      }
    }

    // Mock mode keeps the asynchronous shape but processes with synthetic transcript.
    queueMicrotask(() => {
      void this.process(recording.id, userId, {
        transcriptText: this.buildMockTranscript(input.title),
      });
    });
    await unlink(input.filePath).catch(() => undefined);
    return recording;
  }

  async process(recordingId: string, userId: string, input?: ProcessRecordingInput): Promise<Recording> {
    let recording = await this.getOrThrow(recordingId, userId);
    return this.processLoadedRecording(recording, input);
  }

  async processAdmin(recordingId: string, input?: ProcessRecordingInput): Promise<Recording> {
    const recording = await this.getAdminRecordingOrThrow(recordingId);
    return this.processLoadedRecording(recording, input);
  }

  private async processLoadedRecording(recording: Recording, input?: ProcessRecordingInput): Promise<Recording> {
    const transcriptText = input?.transcriptText?.trim() || extractTranscriptText(recording);

    if (!transcriptText) {
      throw new ServiceError(
        'Transcript text is required to process a recording.',
        400,
        'transcript_required',
      );
    }

    recording.status = 'processing_transcript';
    recording = await this.repository.update(recording);

    try {
      const result = await withRetries(
        () => this.aiProvider.processRecording(recording, { transcriptText }),
        {
          retries: 2,
          shouldRetry: (error) => isRetryableError(error),
        },
      );

      recording.status = 'processing_summary';
      recording = await this.repository.update(recording);

      recording.title = result.title;
      if ((input?.transcriptSegments?.length ?? 0) > 0) {
        recording.transcriptSegments = input!.transcriptSegments!;
      } else if (result.transcriptSegments.length > 0) {
        recording.transcriptSegments = result.transcriptSegments;
      }
      recording.summary = {
        overview: result.overview,
        chapters: result.chapters,
      };
      recording.noteArtifact = {
        title: result.title,
        tags: result.tags,
        highlights: result.highlights,
        actionItems: result.actionItems,
      };

      recording.status = 'indexing';
      recording = await this.repository.update(recording);

      recording.status = 'ready';
      recording.lastError = undefined;
      const readyRecording = await this.repository.update(recording);
      try {
        await this.pushNotifications.notifyRecordingReady(readyRecording);
      } catch (notificationError) {
        console.warn('Push notification dispatch failed:', notificationError);
      }
      return readyRecording;
    } catch (error) {
      recording.status = 'failed';
      recording.lastError = error instanceof Error ? error.message : 'Unknown processing error';
      return this.repository.update(recording);
    }
  }

  async answerQuestion(recordingId: string, userId: string, question: string) {
    const recording = await this.getOrThrow(recordingId, userId);
    const answer = await withRetries(
      () => this.aiProvider.answerQuestion(recording, question),
      {
        retries: 1,
        shouldRetry: (error) => isRetryableError(error),
      },
    );

    const userMessage: ChatMessage = {
      id: randomUUID(),
      role: 'user',
      content: question,
      createdAt: new Date().toISOString(),
    };
    const assistantMessage: ChatMessage = {
      id: randomUUID(),
      role: 'assistant',
      content:
        answer.answer.trim() ||
        `Resumo disponível: ${recording.summary?.overview ?? 'sem resumo disponível.'}`,
      citations: answer.citations.length > 0 ? answer.citations : buildGroundedCitations(recording, question),
      createdAt: new Date().toISOString(),
    };

    recording.chatSession ??= {
      id: randomUUID(),
      recordingId: recording.id,
      messages: [],
    };
    recording.chatSession.messages.push(userMessage, assistantMessage);
    await this.repository.update(recording);

    return {
      recordingId: recording.id,
      answer: assistantMessage,
      session: recording.chatSession,
    };
  }

  async export(recordingId: string, userId: string, format: 'txt' | 'md') {
    const recording = await this.getOrThrow(recordingId, userId);
    return this.exportProvider.build(recording, format);
  }

  async processFromWebhook(
    recordingId: string,
    userId: string,
    input: ProcessRecordingInput,
  ): Promise<Recording> {
    return this.process(recordingId, userId, input);
  }

  async completeAssemblyAiTranscript(recordingId: string, userId: string, transcriptId: string): Promise<Recording> {
    const existing = await this.getOrThrow(recordingId, userId);
    if (
      existing.status === 'ready' &&
      existing.transcriptionProvider === 'assemblyai' &&
      existing.transcriptionJobId === transcriptId
    ) {
      return existing;
    }

    const transcript = await this.assemblyAi.getTranscript(transcriptId);

    if (transcript.status === 'error') {
      const recording = await this.getOrThrow(recordingId, userId);
      recording.status = 'failed';
      recording.lastError = transcript.error ?? 'AssemblyAI transcript failed.';
      recording.transcriptionProvider = 'assemblyai';
      recording.transcriptionJobId = transcriptId;
      recording.transcriptionCompletedAt = new Date().toISOString();
      return this.repository.update(recording);
    }

    if (transcript.status !== 'completed' || !transcript.text?.trim()) {
      throw new ServiceError(
        'AssemblyAI transcript is not completed yet.',
        409,
        'assemblyai_transcript_not_ready',
        { transcriptId, status: transcript.status },
      );
    }

    const transcriptSegments = transcript.utterances.map((utterance, index) => ({
      id: randomUUID(),
      recordingId,
      speakerLabel: `Participante ${utterance.speaker ?? index + 1}`,
      startMs: utterance.start ?? index * 30000,
      endMs: utterance.end ?? (utterance.start ?? index * 30000) + 20000,
      text: utterance.text,
    }));

    return this.process(recordingId, userId, {
      transcriptText: transcript.text,
      transcriptSegments,
    }).then((recording) => this.repository.update({
      ...recording,
      transcriptionProvider: 'assemblyai',
      transcriptionJobId: transcriptId,
      transcriptionCompletedAt: new Date().toISOString(),
    }));
  }

  private buildMockTranscript(title: string): string {
    return [
      `Participante 1: Esta nota chamada ${title} precisa consolidar o contexto da conversa.`,
      'Participante 2: Vamos registrar responsáveis, riscos e próximos passos para o produto.',
      'Participante 1: Precisamos manter busca, resumo estruturado e chat contextual no lançamento.',
    ].join('\n');
  }
}

function buildAudioObjectPath(projectId: string, recordingId: string, fileName: string): string {
  const safeFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
  return `${projectId}/${recordingId}/${safeFileName}`;
}
