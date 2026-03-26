import request from 'supertest';
import { describe, expect, it } from 'vitest';

import type { AiProcessingResult, AiProvider, ChatAnswer } from '../src/domain/contracts.js';
import type { ProcessRecordingInput, Recording } from '../src/domain/types.js';
import { buildApp } from '../src/http/build-app.js';
import { MemoryRecordingRepository } from '../src/repositories/memory-recording-repository.js';
import { demoRecordings, demoUserId } from '../src/seed/demo-recordings.js';
import { PlainTextExportProvider } from '../src/services/export-provider.js';
import { MockAiProvider } from '../src/services/mock-ai-provider.js';
import { RecordingService } from '../src/services/recording-service.js';

class FlakyAiProvider implements AiProvider {
  public processCalls = 0;

  async processRecording(recording: Recording, input?: ProcessRecordingInput): Promise<AiProcessingResult> {
    this.processCalls += 1;

    if (this.processCalls < 2) {
      const error = new Error('temporarily unavailable') as Error & { statusCode?: number };
      error.statusCode = 503;
      throw error;
    }

    const transcriptText = input?.transcriptText ?? '';
    return {
      title: 'Recovered title',
      overview: 'Recovered overview',
      tags: ['recovered'],
      highlights: ['Recovered highlight'],
      actionItems: ['Recovered action'],
      chapters: [{ heading: 'Recovered', body: 'Recovered body' }],
      transcriptSegments: transcriptText.split('\n').map((line, index) => ({
        id: `${recording.id}-${index}`,
        recordingId: recording.id,
        speakerLabel: 'Speaker 1',
        startMs: index * 1000,
        endMs: index * 1000 + 500,
        text: line.split(':').slice(1).join(':').trim() || line,
      })),
    };
  }

  async answerQuestion(_recording: Recording): Promise<ChatAnswer> {
    return {
      answer: '',
      citations: [],
    };
  }
}

const repository = new MemoryRecordingRepository(demoRecordings);
const service = new RecordingService(repository, new MockAiProvider(), new PlainTextExportProvider());
const app = buildApp(service);

describe('recordings api', () => {
  it('lists demo recordings', async () => {
    const response = await request(app)
      .get('/recordings')
      .set('x-user-id', demoUserId);

    expect(response.status).toBe(200);
    expect(response.body.data).toHaveLength(1);
  });

  it('rejects invalid create payloads', async () => {
    const response = await request(app)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        sourceType: 'upload',
      });

    expect(response.status).toBe(400);
    expect(response.body.code).toBe('validation_error');
  });

  it('creates and processes a recording', async () => {
    const createResponse = await request(app)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        title: 'Customer interview',
        sourceType: 'upload',
      });

    expect(createResponse.status).toBe(201);

    const recordingId = createResponse.body.data.id as string;
    const processResponse = await request(app)
      .post(`/recordings/${recordingId}/process`)
      .set('x-user-id', demoUserId)
      .send({
        transcriptText: 'Speaker 1: Customer wants weekly summaries.\nSpeaker 2: We will deliver a pilot next Monday.',
      });

    expect(processResponse.status).toBe(200);
    expect(processResponse.body.data.status).toBe('ready');
    expect(processResponse.body.data.summary.overview).toBeTruthy();
  });

  it('retries transient processing failures', async () => {
    const retryRepository = new MemoryRecordingRepository(demoRecordings);
    const flakyProvider = new FlakyAiProvider();
    const retryService = new RecordingService(retryRepository, flakyProvider, new PlainTextExportProvider());
    const retryApp = buildApp(retryService);

    const createResponse = await request(retryApp)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        title: 'Retry me',
        sourceType: 'upload',
      });

    const recordingId = createResponse.body.data.id as string;
    const response = await request(retryApp)
      .post(`/recordings/${recordingId}/process`)
      .set('x-user-id', demoUserId)
      .send({
        transcriptText: 'Speaker 1: Keep trying until the provider recovers.',
      });

    expect(response.status).toBe(200);
    expect(response.body.data.status).toBe('ready');
    expect(flakyProvider.processCalls).toBe(2);
  });

  it('accepts final transcription webhooks with segments', async () => {
    const recordingId = demoRecordings[0]!.id;

    const response = await request(app)
      .post('/webhooks/transcription')
      .set('x-user-id', demoUserId)
      .send({
        provider: 'deepgram',
        event: 'transcript.completed',
        recordingId,
        isFinal: true,
        segments: [
          { speakerLabel: 'Speaker 1', text: 'Team agreed on launch scope.' },
          { speakerLabel: 'Speaker 2', text: 'We will ship the retry logic first.' },
        ],
      });

    expect(response.status).toBe(202);
    expect(response.body.accepted).toBe(true);
    expect(response.body.data.status).toBe('ready');
    expect(response.body.data.transcriptSegments).toHaveLength(2);
  });

  it('answers chat grounded in a note and exports markdown', async () => {
    const recordingId = demoRecordings[0]!.id;

    const chatResponse = await request(app)
      .post(`/recordings/${recordingId}/chat`)
      .set('x-user-id', demoUserId)
      .send({ question: 'Quais sao os proximos passos?' });

    expect(chatResponse.status).toBe(200);
    expect(chatResponse.body.answer.role).toBe('assistant');
    expect(chatResponse.body.answer.citations.length).toBeGreaterThan(0);

    const exportResponse = await request(app)
      .post(`/recordings/${recordingId}/export`)
      .set('x-user-id', demoUserId)
      .send({ format: 'md' });

    expect(exportResponse.status).toBe(200);
    expect(exportResponse.body.data.body).toContain('# Team agreed on launch scope.');
  });

  it('falls back to grounded citations when provider answer is empty', async () => {
    const fallbackRepository = new MemoryRecordingRepository(demoRecordings);
    const fallbackService = new RecordingService(
      fallbackRepository,
      {
        async processRecording(recording: Recording, input?: ProcessRecordingInput): Promise<AiProcessingResult> {
          return new MockAiProvider().processRecording(recording, input);
        },
        async answerQuestion(): Promise<ChatAnswer> {
          return {
            answer: '',
            citations: [],
          };
        },
      },
      new PlainTextExportProvider(),
    );
    const fallbackApp = buildApp(fallbackService);

    const response = await request(fallbackApp)
      .post(`/recordings/${demoRecordings[0]!.id}/chat`)
      .set('x-user-id', demoUserId)
      .send({ question: 'What are the next steps?' });

    expect(response.status).toBe(200);
    expect(response.body.answer.content).toContain('Summary available');
    expect(response.body.answer.citations.length).toBeGreaterThan(0);
  });
});
