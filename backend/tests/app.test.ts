import request from 'supertest';
import { describe, expect, it } from 'vitest';

import type { AiProcessingResult, AiProvider, ChatAnswer } from '../src/domain/contracts.js';
import type { ProcessRecordingInput, Recording } from '../src/domain/types.js';
import { buildApp } from '../src/http/build-app.js';
import type { RequestAuth, RequestAuthProvider } from '../src/http/request-auth.js';
import { MemoryRecordingRepository } from '../src/repositories/memory-recording-repository.js';
import { demoRecordings, demoUserId } from '../src/seed/demo-recordings.js';
import { PlainTextExportProvider } from '../src/services/export-provider.js';
import { MockAiProvider } from '../src/services/mock-ai-provider.js';
import type { PushDevicePlatform, PushNotificationServiceLike } from '../src/services/push-notification-service.js';
import { RecordingService } from '../src/services/recording-service.js';
import { ServiceError } from '../src/services/service-errors.js';

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

class TestPushNotificationService implements PushNotificationServiceLike {
  public readonly registered: Array<{ userId: string; token: string; platform: PushDevicePlatform }> = [];
  public readonly unregistered: Array<{ userId: string; token: string }> = [];
  public readonly notifiedRecordingIds: string[] = [];

  async registerDevice(userId: string, token: string, platform: PushDevicePlatform): Promise<void> {
    this.registered.push({ userId, token, platform });
  }

  async unregisterDevice(userId: string, token: string): Promise<void> {
    this.unregistered.push({ userId, token });
  }

  async notifyRecordingReady(recording: Recording): Promise<void> {
    this.notifiedRecordingIds.push(recording.id);
  }
}

class TestAuthProvider implements RequestAuthProvider {
  constructor(
    private readonly auth: RequestAuth,
    private readonly options: {
      enforced?: boolean;
      admin?: boolean;
    } = {},
  ) {}

  isAuthEnforced(): boolean {
    return this.options.enforced ?? true;
  }

  async getRequestAuth(request: { header(name: string): string | undefined }): Promise<RequestAuth> {
    if (this.isAuthEnforced() && request.header('authorization') !== 'Bearer test-token') {
      throw new ServiceError('Authorization bearer token is required.', 401, 'auth_token_required');
    }

    return this.auth;
  }

  async ensureAdmin(): Promise<void> {
    if (!this.options.admin) {
      throw new ServiceError('Admin access denied.', 403, 'admin_access_denied');
    }
  }
}

const adminProfile = {
  id: 'profile-admin',
  code: 'admin',
  name: 'Administrador',
} as const;

const userProfile = {
  id: 'profile-user',
  code: 'user',
  name: 'Usuário',
} as const;

function makeAuth(overrides: Partial<RequestAuth> = {}): RequestAuth {
  return {
    userId: demoUserId,
    email: 'demo@example.com',
    fullName: 'Usuário demo',
    isActive: true,
    profile: adminProfile,
    source: 'dev-default',
    ...overrides,
  };
}

const repository = new MemoryRecordingRepository(demoRecordings, {
  forcePersistenceMode: 'memory',
});
const service = new RecordingService(repository, new MockAiProvider(), new PlainTextExportProvider());
const defaultAuthProvider = new TestAuthProvider(makeAuth(), { enforced: false, admin: true });

function buildTestApp(
  recordingService: RecordingService,
  options: {
    authProvider?: RequestAuthProvider;
    pushNotificationService?: PushNotificationServiceLike;
  } = {},
) {
  return buildApp(recordingService, {
    authProvider: options.authProvider ?? defaultAuthProvider,
    pushNotificationService: options.pushNotificationService,
  });
}

const app = buildTestApp(service, {
  authProvider: new TestAuthProvider(makeAuth(), { enforced: false, admin: true }),
});

describe('recordings api', () => {
  it('serves the OpenAPI document and Swagger UI', async () => {
    const jsonResponse = await request(app).get('/openapi.json');
    expect(jsonResponse.status).toBe(200);
    expect(jsonResponse.body.openapi).toBe('3.1.0');
    expect(jsonResponse.body.paths['/recordings/upload']).toBeTruthy();

    const docsResponse = await request(app).get('/docs');
    expect(docsResponse.status).toBe(301);
  });

  it('lists demo recordings', async () => {
    const response = await request(app)
      .get('/recordings')
      .set('x-user-id', demoUserId);

    expect(response.status).toBe(200);
    expect(response.body.data).toHaveLength(1);
  });

  it('lists projects for the current user', async () => {
    const response = await request(app)
      .get('/projects')
      .set('x-user-id', demoUserId);

    expect(response.status).toBe(200);
    expect(response.body.data[0].id).toBe('project-demo');
  });

  it('rejects protected routes without a bearer token when auth is enforced', async () => {
    const guardedApp = buildApp(service, {
      authProvider: new TestAuthProvider(
        makeAuth({
          userId: '11111111-1111-4111-8111-111111111111',
          email: 'user@example.com',
          fullName: 'Regular User',
          profile: userProfile,
          source: 'supabase',
        }),
        { enforced: true, admin: false },
      ),
    });

    const response = await request(guardedApp).get('/projects');

    expect(response.status).toBe(401);
    expect(response.body.code).toBe('auth_token_required');
  });

  it('rejects admin routes for authenticated non-admin users', async () => {
    const guardedApp = buildApp(service, {
      authProvider: new TestAuthProvider(
        makeAuth({
          userId: '11111111-1111-4111-8111-111111111111',
          email: 'user@example.com',
          fullName: 'Regular User',
          profile: userProfile,
          source: 'supabase',
        }),
        { enforced: true, admin: false },
      ),
    });

    const response = await request(guardedApp)
      .get('/admin/dashboard')
      .set('authorization', 'Bearer test-token');

    expect(response.status).toBe(403);
    expect(response.body.code).toBe('admin_access_denied');
  });

  it('allows admin routes globally without requiring project membership', async () => {
    const guardedApp = buildApp(service, {
      authProvider: new TestAuthProvider(
        makeAuth({
          userId: '22222222-2222-4222-8222-222222222222',
          email: 'operator@example.com',
          fullName: 'Backoffice Operator',
          source: 'supabase',
        }),
        { enforced: true, admin: true },
      ),
    });

    const response = await request(guardedApp)
      .get(`/admin/recordings/${demoRecordings[0]!.id}`)
      .set('authorization', 'Bearer test-token');

    expect(response.status).toBe(200);
    expect(response.body.data.id).toBe(demoRecordings[0]!.id);
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

  it('creates a project and manages members through admin endpoints', async () => {
    const profiles = await request(app).get('/admin/profiles');
    const userProfileId = profiles.body.data.find((item: { code: string }) => item.code === 'user')?.id as string;

    const createdUser = await request(app)
      .post('/admin/users')
      .send({
        email: 'usuario-teste@example.com',
        password: 'senha-forte-123',
        fullName: 'Usuário Teste',
        profileId: userProfileId,
      });

    expect(createdUser.status).toBe(201);

    const createProject = await request(app)
      .post('/admin/projects')
      .send({ name: 'Projeto de teste' });

    expect(createProject.status).toBe(201);
    const projectId = createProject.body.data.id as string;

    const addMember = await request(app)
      .post(`/admin/projects/${projectId}/members`)
      .send({ userId: createdUser.body.data.id, role: 'member' });

    expect(addMember.status).toBe(201);

    const listMembers = await request(app)
      .get(`/admin/projects/${projectId}/members`);

    expect(listMembers.status).toBe(200);
    expect(listMembers.body.data.length).toBeGreaterThan(1);
    expect(listMembers.body.data.some((member: { user?: { email?: string } }) => member.user?.email === 'usuario-teste@example.com')).toBe(true);
  });

  it('manages profiles and users through admin endpoints', async () => {
    const createProfile = await request(app)
      .post('/admin/profiles')
      .send({
        code: 'reviewer',
        name: 'Reviewer',
        description: 'Perfil para revisão interna.',
      });

    expect(createProfile.status).toBe(201);

    const createUser = await request(app)
      .post('/admin/users')
      .send({
        email: 'reviewer@example.com',
        password: 'senha-forte-456',
        fullName: 'Pessoa Reviewer',
        profileId: createProfile.body.data.id,
      });

    expect(createUser.status).toBe(201);
    expect(createUser.body.data.profileCode).toBe('reviewer');

    const updateUser = await request(app)
      .patch(`/admin/users/${createUser.body.data.id}`)
      .send({
        fullName: 'Pessoa Reviewer Atualizada',
        isActive: false,
      });

    expect(updateUser.status).toBe(200);
    expect(updateUser.body.data.fullName).toBe('Pessoa Reviewer Atualizada');
    expect(updateUser.body.data.isActive).toBe(false);

    const updateProfile = await request(app)
      .patch(`/admin/profiles/${createProfile.body.data.id}`)
      .send({
        name: 'Reviewer Senior',
      });

    expect(updateProfile.status).toBe(200);
    expect(updateProfile.body.data.name).toBe('Reviewer Senior');

    const listUsers = await request(app)
      .get('/admin/users')
      .query({ query: 'reviewer@example.com' });

    expect(listUsers.status).toBe(200);
    expect(listUsers.body.data.some((item: { email?: string }) => item.email === 'reviewer@example.com')).toBe(true);
  });

  it('filters admin projects by status and query', async () => {
    const created = await request(app)
      .post('/admin/projects')
      .send({ name: 'Projeto filtravel' });

    await request(app)
      .patch(`/admin/projects/${created.body.data.id}`)
      .send({ status: 'archived' });

    const response = await request(app)
      .get('/admin/projects')
      .query({ status: 'archived', query: 'filtrav' });

    expect(response.status).toBe(200);
    expect(response.body.data.some((project: { id: string }) => project.id === created.body.data.id)).toBe(true);
  });

  it('creates and processes a recording', async () => {
    const createResponse = await request(app)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        title: 'Customer interview',
        projectId: 'project-demo',
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

  it('creates recordings without a project and allows later project binding changes', async () => {
    const createResponse = await request(app)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        title: 'Nota sem projeto',
        sourceType: 'upload',
      });

    expect(createResponse.status).toBe(201);
    expect(createResponse.body.data.projectId).toBeNull();

    const recordingId = createResponse.body.data.id as string;

    const withoutProjectResponse = await request(app)
      .get('/recordings')
      .set('x-user-id', demoUserId)
      .query({ withoutProject: 'true' });

    expect(withoutProjectResponse.status).toBe(200);
    expect(withoutProjectResponse.body.data.some((item: { id: string }) => item.id === recordingId)).toBe(true);

    const bindResponse = await request(app)
      .patch(`/recordings/${recordingId}`)
      .set('x-user-id', demoUserId)
      .send({ projectId: 'project-demo' });

    expect(bindResponse.status).toBe(200);
    expect(bindResponse.body.data.projectId).toBe('project-demo');

    const unbindResponse = await request(app)
      .patch(`/recordings/${recordingId}`)
      .set('x-user-id', demoUserId)
      .send({ projectId: null });

    expect(unbindResponse.status).toBe(200);
    expect(unbindResponse.body.data.projectId).toBeNull();
  });

  it('keeps recordings private to the owner even when linked to a shared project', async () => {
    const profiles = await request(app).get('/admin/profiles');
    const userProfileId = profiles.body.data.find((item: { code: string }) => item.code === 'user')?.id as string;

    const createdUser = await request(app)
      .post('/admin/users')
      .send({
        email: 'member-private@example.com',
        password: 'senha-forte-123',
        fullName: 'Membro do projeto',
        profileId: userProfileId,
      });

    const createdProject = await request(app)
      .post('/admin/projects')
      .send({ name: 'Projeto owner-only' });

    await request(app)
      .post(`/admin/projects/${createdProject.body.data.id}/members`)
      .send({ userId: createdUser.body.data.id, role: 'member' });

    const createResponse = await request(app)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        title: 'Privada no projeto',
        projectId: createdProject.body.data.id,
        sourceType: 'upload',
      });

    const ownerRecordingId = createResponse.body.data.id as string;

    const response = await request(app)
      .get(`/recordings/${ownerRecordingId}`)
      .set('x-user-id', demoUserId);

    expect(response.status).toBe(200);

    const memberApp = buildTestApp(service, {
      authProvider: new TestAuthProvider(
        makeAuth({
          userId: createdUser.body.data.id,
          email: 'member-private@example.com',
          fullName: 'Membro do projeto',
          profile: userProfile,
          source: 'dev-header',
        }),
        { enforced: false, admin: false },
      ),
    });

    const memberResponse = await request(memberApp)
      .get(`/recordings/${ownerRecordingId}`);

    expect(memberResponse.status).toBe(404);
    expect(memberResponse.body.code).toBe('recording_not_found');
  });

  it('accepts desktop meeting recordings with capture metadata and admin filters', async () => {
    const createResponse = await request(app)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        title: 'Reunião semanal Teams',
        projectId: 'project-demo',
        sourceType: 'desktop_meeting',
        captureMetadata: {
          sourceApp: 'teams',
          platform: 'windows',
          captureMode: 'system_and_mic',
          helperVersion: '0.1.0',
          windowTitle: 'Daily sync',
        },
      });

    expect(createResponse.status).toBe(201);
    expect(createResponse.body.data.sourceType).toBe('desktop_meeting');
    expect(createResponse.body.data.captureMetadata.sourceApp).toBe('teams');

    const adminList = await request(app)
      .get('/admin/recordings')
      .query({ sourceApp: 'teams', platform: 'windows' });

    expect(adminList.status).toBe(200);
    expect(
      adminList.body.data.some((recording: { id: string }) => recording.id === createResponse.body.data.id),
    ).toBe(true);
  });

  it('registers and removes a push token for the authenticated user', async () => {
    const pushService = new TestPushNotificationService();
    const pushApp = buildTestApp(service, {
      pushNotificationService: pushService,
    });

    const registerResponse = await request(pushApp)
      .post('/me/push-devices')
      .set('x-user-id', demoUserId)
      .send({
        token: 'fcm-token-12345678901234567890',
        platform: 'android',
      });

    expect(registerResponse.status).toBe(204);
    expect(pushService.registered).toEqual([
      {
        userId: demoUserId,
        token: 'fcm-token-12345678901234567890',
        platform: 'android',
      },
    ]);

    const unregisterResponse = await request(pushApp)
      .delete('/me/push-devices')
      .set('x-user-id', demoUserId)
      .send({
        token: 'fcm-token-12345678901234567890',
      });

    expect(unregisterResponse.status).toBe(204);
    expect(pushService.unregistered).toEqual([
      {
        userId: demoUserId,
        token: 'fcm-token-12345678901234567890',
      },
    ]);
  });

  it('accepts multipart audio upload and creates an async recording', async () => {
    const response = await request(app)
      .post('/recordings/upload')
      .set('x-user-id', demoUserId)
      .field('title', 'Audio longo')
      .field('projectId', 'project-demo')
      .field('sourceType', 'desktop_meeting')
      .field(
        'captureMetadata',
        JSON.stringify({
          sourceApp: 'zoom',
          platform: 'windows',
          captureMode: 'system_and_mic',
          helperVersion: '0.1.0',
        }),
      )
      .attach('file', Buffer.from('fake audio bytes'), 'audio-test.wav');

    expect(response.status).toBe(201);
    expect(response.body.data.title).toBe('Audio longo');
    expect(response.body.data.sourceType).toBe('desktop_meeting');
    expect(response.body.data.captureMetadata.sourceApp).toBe('zoom');
    expect(response.body.data.status).toBe('processing_transcript');
  });

  it('retries transient processing failures', async () => {
    const retryRepository = new MemoryRecordingRepository(demoRecordings, {
      forcePersistenceMode: 'memory',
    });
    const flakyProvider = new FlakyAiProvider();
    const retryService = new RecordingService(retryRepository, flakyProvider, new PlainTextExportProvider());
    const retryApp = buildTestApp(retryService);

    const createResponse = await request(retryApp)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        title: 'Retry me',
        projectId: 'project-demo',
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

  it('dispatches a push notification when a recording reaches ready', async () => {
    const pushRepository = new MemoryRecordingRepository(demoRecordings, {
      forcePersistenceMode: 'memory',
    });
    const pushService = new TestPushNotificationService();
    const pushRecordingService = new RecordingService(
      pushRepository,
      new MockAiProvider(),
      new PlainTextExportProvider(),
      pushService,
    );
    const pushApp = buildTestApp(pushRecordingService, {
      pushNotificationService: pushService,
    });

    const createResponse = await request(pushApp)
      .post('/recordings')
      .set('x-user-id', demoUserId)
      .send({
        title: 'Notify me',
        projectId: 'project-demo',
        sourceType: 'upload',
      });

    const recordingId = createResponse.body.data.id as string;
    const processResponse = await request(pushApp)
      .post(`/recordings/${recordingId}/process`)
      .set('x-user-id', demoUserId)
      .send({
        transcriptText: 'Speaker 1: Finish processing and notify the operator.',
      });

    expect(processResponse.status).toBe(200);
    expect(processResponse.body.data.status).toBe('ready');
    expect(pushService.notifiedRecordingIds).toContain(recordingId);
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
    const fallbackRepository = new MemoryRecordingRepository(demoRecordings, {
      forcePersistenceMode: 'memory',
    });
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
    const fallbackApp = buildTestApp(fallbackService);

    const response = await request(fallbackApp)
      .post(`/recordings/${demoRecordings[0]!.id}/chat`)
      .set('x-user-id', demoUserId)
      .send({ question: 'What are the next steps?' });

    expect(response.status).toBe(200);
    expect(response.body.answer.content).toContain('Resumo disponível');
    expect(response.body.answer.citations.length).toBeGreaterThan(0);
  });
});
