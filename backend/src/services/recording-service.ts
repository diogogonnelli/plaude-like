import { randomUUID } from 'node:crypto';

import type { AiProvider, ExportProvider, RecordingRepository } from '../domain/contracts.js';
import type { ChatMessage, CreateRecordingInput, ProcessRecordingInput, Recording } from '../domain/types.js';
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
  constructor(
    private readonly repository: RecordingRepository,
    private readonly aiProvider: AiProvider,
    private readonly exportProvider: ExportProvider,
  ) {}

  list(userId: string, filters?: { query?: string; tag?: string }) {
    return this.repository.list(userId, filters);
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

  async process(recordingId: string, userId: string, input?: ProcessRecordingInput): Promise<Recording> {
    let recording = await this.getOrThrow(recordingId, userId);
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
      if (result.transcriptSegments.length > 0) {
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
      return this.repository.update(recording);
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
        `Summary available: ${recording.summary?.overview ?? 'no summary available.'}`,
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
}
