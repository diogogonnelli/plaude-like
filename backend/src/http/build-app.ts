import cors from 'cors';
import express from 'express';
import multer from 'multer';
import { tmpdir } from 'node:os';
import swaggerUi from 'swagger-ui-express';
import { z } from 'zod';

import { config } from '../lib/config.js';
import { ServiceError, isServiceError } from '../services/service-errors.js';
import type { PushNotificationServiceLike } from '../services/push-notification-service.js';
import type { RecordingService } from '../services/recording-service.js';
import { buildOpenApiDocument } from './openapi.js';
import {
  SupabaseRequestAuthProvider,
  type RequestAuth,
  type RequestAuthProvider,
} from './request-auth.js';

const userHeader = 'x-user-id';
const recordingSourceTypes = ['microphone', 'upload', 'desktop_meeting'] as const;
const captureSourceApps = ['teams', 'zoom', 'meet', 'system_audio'] as const;
const capturePlatforms = ['windows', 'macos'] as const;
const captureModes = ['system_and_mic'] as const;

const captureMetadataSchema = z
  .object({
    sourceApp: z.enum(captureSourceApps),
    platform: z.enum(capturePlatforms),
    captureMode: z.enum(captureModes),
    helperVersion: z.string().min(1),
    windowTitle: z.string().min(1).optional(),
  })
  .strict();

const createRecordingSchema = z
  .object({
    title: z.string().min(1),
    projectId: z.string().min(1),
    sourceType: z.enum(recordingSourceTypes),
    captureMetadata: captureMetadataSchema.optional(),
    durationMs: z.number().int().positive().optional(),
    audioPath: z.string().min(1).optional(),
  })
  .strict();

const processRecordingSchema = z
  .object({
    transcriptText: z.string().min(1).optional(),
  })
  .strict();

const chatSchema = z
  .object({
    question: z.string().min(3),
  })
  .strict();

const exportSchema = z
  .object({
    format: z.enum(['txt', 'md']),
  })
  .strict();

const uploadRecordingSchema = z
  .object({
    title: z.string().min(1),
    projectId: z.string().min(1),
    sourceType: z.enum(recordingSourceTypes).default('upload'),
    captureMetadata: z.preprocess(parseCaptureMetadataField, captureMetadataSchema.optional()),
    durationMs: z.coerce.number().int().positive().optional(),
  })
  .strict();

const projectSchema = z
  .object({
    name: z.string().min(1),
    slug: z.string().min(1).optional(),
  })
  .strict();

const projectPatchSchema = z
  .object({
    name: z.string().min(1).optional(),
    slug: z.string().min(1).optional(),
    status: z.enum(['active', 'archived']).optional(),
  })
  .strict();

const projectMemberSchema = z
  .object({
    userId: z.string().min(1),
    role: z.enum(['owner', 'member']).default('member'),
  })
  .strict();

const booleanQuerySchema = z.enum(['true', 'false']).transform((value) => value === 'true');

const adminUserCreateSchema = z
  .object({
    email: z.string().email(),
    password: z.string().min(8),
    fullName: z.string().trim().min(1).nullable().optional(),
    profileId: z.string().min(1),
    isActive: z.boolean().optional(),
  })
  .strict();

const adminUserPatchSchema = z
  .object({
    email: z.string().email().optional(),
    password: z.string().min(8).optional(),
    fullName: z.string().trim().min(1).nullable().optional(),
    profileId: z.string().min(1).optional(),
    isActive: z.boolean().optional(),
  })
  .strict();

const profileSchema = z
  .object({
    code: z.string().regex(/^[a-z0-9_]+$/),
    name: z.string().min(1),
    description: z.string().trim().min(1).nullable().optional(),
  })
  .strict();

const profilePatchSchema = z
  .object({
    code: z.string().regex(/^[a-z0-9_]+$/).optional(),
    name: z.string().min(1).optional(),
    description: z.string().trim().min(1).nullable().optional(),
  })
  .strict();

const webhookSegmentSchema = z
  .object({
    speakerLabel: z.string().min(1).optional(),
    startMs: z.number().int().nonnegative().optional(),
    endMs: z.number().int().nonnegative().optional(),
    text: z.string().min(1),
  })
  .strict();

const transcriptionWebhookSchema = z
  .object({
    provider: z.enum(['deepgram', 'assemblyai', 'generic']).default('generic'),
    event: z.string().min(1),
    recordingId: z.string().min(1),
    userId: z.string().min(1).optional(),
    transcriptText: z.string().min(1).optional(),
    segments: z.array(webhookSegmentSchema).default([]),
    isFinal: z.boolean().default(true),
    status: z.enum(['partial', 'completed', 'failed']).optional(),
    requestId: z.string().min(1).optional(),
  })
  .strict();

const pushDeviceSchema = z
  .object({
    token: z.string().min(20),
    platform: z.enum(['android', 'ios']),
  })
  .strict();

function getUserId(request: express.Request) {
  return request.header(userHeader) ?? 'demo-user';
}

function setRequestAuth(request: express.Request, auth: RequestAuth) {
  (request as express.Request & { auth?: RequestAuth }).auth = auth;
}

function parseError(error: unknown) {
  if (error instanceof z.ZodError) {
    return {
      statusCode: 400,
      body: {
        error: 'Requisição inválida',
        code: 'validation_error',
        issues: error.issues,
      },
    };
  }

  if (isServiceError(error)) {
    return {
      statusCode: error.statusCode,
      body: {
        error: error.message,
        code: error.code,
        details: error.details,
      },
    };
  }

  return {
    statusCode: 500,
    body: {
      error: error instanceof Error ? error.message : 'Erro interno inesperado',
      code: 'internal_error',
    },
  };
}

function asyncRoute(
  handler: (request: express.Request, response: express.Response) => Promise<void>,
) {
  return (request: express.Request, response: express.Response, next: express.NextFunction) => {
    handler(request, response).catch(next);
  };
}

function buildTranscriptFromSegments(
  transcriptText: string | undefined,
  segments: Array<{ speakerLabel?: string; text: string }>,
) {
  if (transcriptText?.trim()) {
    return transcriptText.trim();
  }

  if (segments.length === 0) {
    return '';
  }

  return segments
    .map((segment, index) => `${segment.speakerLabel ?? `Speaker ${index + 1}`}: ${segment.text}`)
    .join('\n');
}

function parseCaptureMetadataField(value: unknown) {
  if (value == null || value === '') {
    return undefined;
  }

  if (typeof value === 'string') {
    return JSON.parse(value) as unknown;
  }

  return value;
}

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60) || 'project';
}

function buildAuthorLabelResolver(recordingService: Pick<RecordingService, 'getAdminUserById'>) {
  const cache = new Map<string, string>();

  return async (userId: string) => {
    if (cache.has(userId)) {
      return cache.get(userId)!;
    }

    if (userId === 'demo-user') {
      cache.set(userId, 'Usuário demo');
      return 'Usuário demo';
    }

    const user = await recordingService.getAdminUserById(userId).catch(() => null);
    if (!user) {
      cache.set(userId, userId);
      return userId;
    }

    const label =
      user.fullName ??
      user.email ??
      userId;

    cache.set(userId, label);
    return label;
  };
}

async function decorateAdminRecordings<T extends { createdByUserId: string }>(
  recordingService: Pick<RecordingService, 'getAdminUserById'>,
  recordings: T[],
) {
  const resolveAuthorLabel = buildAuthorLabelResolver(recordingService);

  return Promise.all(
    recordings.map(async (recording) => ({
      ...recording,
      createdByLabel: await resolveAuthorLabel(recording.createdByUserId),
    })),
  );
}

export interface BuildAppOptions {
  authProvider?: RequestAuthProvider;
  pushNotificationService?: PushNotificationServiceLike;
}

export function buildApp(recordingService: RecordingService, options: BuildAppOptions = {}) {
  const app = express();
  const authProvider = options.authProvider ?? new SupabaseRequestAuthProvider();
  const pushNotificationService = options.pushNotificationService;
  const openApiDocument = buildOpenApiDocument(config.APP_BASE_URL);
  const upload = multer({
    dest: tmpdir(),
    limits: {
      fileSize: 1024 * 1024 * 512,
    },
  });
  app.use(cors());
  app.use(express.json({ limit: '8mb' }));

  const withAuth = (
    handler: (
      request: express.Request,
      response: express.Response,
      auth: RequestAuth,
    ) => Promise<void>,
    routeOptions: { admin?: boolean } = {},
  ) =>
    asyncRoute(async (request, response) => {
      const auth = await authProvider.getRequestAuth(request);
      setRequestAuth(request, auth);
      if (routeOptions.admin) {
        await authProvider.ensureAdmin(auth);
      }
      await handler(request, response, auth);
    });

  app.get('/openapi.json', (_request, response) => {
    response.json(openApiDocument);
  });

  app.use(
    '/docs',
    swaggerUi.serve,
    swaggerUi.setup(openApiDocument, {
      explorer: true,
      customSiteTitle: 'Plaude Like API Docs',
    }),
  );

  app.get(
    '/health',
    asyncRoute(async (_request, response) => {
      response.json({ ok: true, service: 'plaude-like-backend' });
    }),
  );

  app.get(
    '/recordings',
    withAuth(async (request, response, auth) => {
      const query = z
        .object({
          query: z.string().min(1).optional(),
          tag: z.string().min(1).optional(),
          projectId: z.string().min(1).optional(),
          _ts: z.string().optional(),
        })
        .strict()
        .parse(request.query);

      const recordings = await recordingService.list(auth.userId, query);
      response.json({ data: recordings });
    }),
  );

  app.get(
    '/projects',
    withAuth(async (_request, response, auth) => {
      const projects = await recordingService.listProjects(auth.userId);
      response.json({ data: projects });
    }),
  );

  app.get(
    '/projects/:id',
    withAuth(async (request, response, auth) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const project = await recordingService.getProjectOrThrow(params.id, auth.userId);
      response.json({ data: project });
    }),
  );

  app.post(
    '/me/push-devices',
    withAuth(async (request, response, auth) => {
      if (!pushNotificationService) {
        response.status(204).send();
        return;
      }

      const body = pushDeviceSchema.parse(request.body ?? {});
      await pushNotificationService.registerDevice(auth.userId, body.token, body.platform);
      response.status(204).send();
    }),
  );

  app.delete(
    '/me/push-devices',
    withAuth(async (request, response, auth) => {
      if (!pushNotificationService) {
        response.status(204).send();
        return;
      }

      const body = z.object({ token: z.string().min(20) }).strict().parse(request.body ?? {});
      await pushNotificationService.unregisterDevice(auth.userId, body.token);
      response.status(204).send();
    }),
  );

  app.post(
    '/recordings',
    withAuth(async (request, response, auth) => {
      const body = createRecordingSchema.parse(request.body ?? {});
      const recording = await recordingService.create(auth.userId, body);
      response.status(201).json({
        data: recording,
        upload: {
          bucket: config.SUPABASE_STORAGE_BUCKET,
          objectPath: recording.audioPath ?? `${recording.id}.m4a`,
        },
      });
    }),
  );

  app.post(
    '/recordings/upload',
    upload.single('file'),
    withAuth(async (request, response, auth) => {
      const file = request.file;
      if (!file) {
        throw new ServiceError('Arquivo de audio nao enviado.', 400, 'audio_file_missing');
      }

      const body = uploadRecordingSchema.parse(request.body ?? {});
      const recording = await recordingService.uploadAndStartTranscription(auth.userId, {
        title: body.title,
        projectId: body.projectId,
        sourceType: body.sourceType,
        captureMetadata: body.captureMetadata,
        durationMs: body.durationMs,
        filePath: file.path,
        fileName: file.originalname,
        mimeType: file.mimetype,
      });

      response.status(201).json({ data: recording });
    }),
  );

  app.post(
    '/recordings/:id/process',
    withAuth(async (request, response, auth) => {
      const params = z
        .object({
          id: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      const body = processRecordingSchema.parse(request.body ?? {});
      const recording = await recordingService.process(params.id, auth.userId, body);
      response.json({ data: recording });
    }),
  );

  app.get(
    '/recordings/:id',
    withAuth(async (request, response, auth) => {
      const params = z
        .object({
          id: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      const recording = await recordingService.getOrThrow(params.id, auth.userId);
      response.json({ data: recording });
    }),
  );

  app.post(
    '/recordings/:id/chat',
    withAuth(async (request, response, auth) => {
      const params = z
        .object({
          id: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      const body = chatSchema.parse(request.body ?? {});
      const payload = await recordingService.answerQuestion(params.id, auth.userId, body.question);
      response.json(payload);
    }),
  );

  app.post(
    '/recordings/:id/export',
    withAuth(async (request, response, auth) => {
      const params = z
        .object({
          id: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      const body = exportSchema.parse(request.body ?? {});
      const artifact = await recordingService.export(params.id, auth.userId, body.format);
      response.json({ data: artifact });
    }),
  );

  app.post(
    '/webhooks/transcription',
    asyncRoute(async (request, response) => {
      const body = transcriptionWebhookSchema.parse(request.body ?? {});
      const userId = body.userId ?? getUserId(request);
      const transcriptText = buildTranscriptFromSegments(body.transcriptText, body.segments);

      if (!body.isFinal && body.status !== 'completed') {
        response.status(202).json({
          accepted: true,
          ignored: true,
          provider: body.provider,
          event: body.event,
          requestId: body.requestId,
        });
        return;
      }

      const recording = await recordingService.processFromWebhook(body.recordingId, userId, {
        transcriptText,
      });

      response.status(202).json({
        accepted: true,
        provider: body.provider,
        event: body.event,
        requestId: body.requestId,
        data: recording,
      });
    }),
  );

  app.post(
    '/webhooks/assemblyai',
    asyncRoute(async (request, response) => {
      const query = z
        .object({
          recordingId: z.string().min(1),
          userId: z.string().min(1),
        })
        .strict()
        .parse(request.query);

      const body = z
        .object({
          transcript_id: z.string().min(1),
          status: z.string().min(1),
        })
        .passthrough()
        .parse(request.body ?? {});

      if (body.status === 'completed' || body.status === 'error') {
        await recordingService.completeAssemblyAiTranscript(
          query.recordingId,
          query.userId,
          body.transcript_id,
        );
      }

      response.status(202).json({
        accepted: true,
        provider: 'assemblyai',
        status: body.status,
      });
    }),
  );

  app.get(
    '/admin/dashboard',
    withAuth(async (_request, response) => {
      const recordings = await recordingService.listAdminRecordings();
      response.json({
        data: {
          totalRecordings: recordings.length,
          processing: recordings.filter((item) => item.status !== 'ready' && item.status !== 'failed').length,
          failed: recordings.filter((item) => item.status === 'failed').length,
          ready: recordings.filter((item) => item.status === 'ready').length,
        },
      });
    }, { admin: true }),
  );

  app.get(
    '/admin/me',
    withAuth(async (_request, response, auth) => {
      response.json({
        data: {
          userId: auth.userId,
          email: auth.email,
          fullName: auth.fullName,
          source: auth.source,
          isActive: auth.isActive,
          profile: auth.profile,
          authEnforced: authProvider.isAuthEnforced(),
          isAdmin: true,
        },
      });
    }, { admin: true }),
  );

  app.get(
    '/admin/profiles',
    withAuth(async (request, response) => {
      const query = z
        .object({
          query: z.string().min(1).optional(),
        })
        .strict()
        .parse(request.query);
      const profiles = await recordingService.listAccessProfiles(query);
      response.json({ data: profiles });
    }, { admin: true }),
  );

  app.post(
    '/admin/profiles',
    withAuth(async (request, response) => {
      const body = profileSchema.parse(request.body ?? {});
      const profile = await recordingService.createAccessProfile(body);
      response.status(201).json({ data: profile });
    }, { admin: true }),
  );

  app.patch(
    '/admin/profiles/:id',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const body = profilePatchSchema.parse(request.body ?? {});
      const profile = await recordingService.updateAccessProfile(params.id, body);
      response.json({ data: profile });
    }, { admin: true }),
  );

  app.delete(
    '/admin/profiles/:id',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      await recordingService.deleteAccessProfile(params.id);
      response.status(204).send();
    }, { admin: true }),
  );

  app.get(
    '/admin/users',
    withAuth(async (request, response) => {
      const query = z
        .object({
          query: z.string().min(1).optional(),
          profileId: z.string().min(1).optional(),
          isActive: booleanQuerySchema.optional(),
        })
        .strict()
        .parse(request.query);
      const users = await recordingService.listAdminUsers(query);
      response.json({ data: users });
    }, { admin: true }),
  );

  app.post(
    '/admin/users',
    withAuth(async (request, response) => {
      const body = adminUserCreateSchema.parse(request.body ?? {});
      const user = await recordingService.createAdminUser(body);
      response.status(201).json({ data: user });
    }, { admin: true }),
  );

  app.patch(
    '/admin/users/:id',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const body = adminUserPatchSchema.parse(request.body ?? {});
      const user = await recordingService.updateAdminUser(params.id, body);
      response.json({ data: user });
    }, { admin: true }),
  );

  app.get(
    '/admin/projects',
    withAuth(async (request, response) => {
      const query = z
        .object({
          query: z.string().min(1).optional(),
          status: z.enum(['active', 'archived']).optional(),
        })
        .strict()
        .parse(request.query);
      const projects = await recordingService.listAdminProjects(query);
      response.json({ data: projects });
    }, { admin: true }),
  );

  app.get(
    '/admin/projects/:id',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const project = await recordingService.getAdminProjectOrThrow(params.id);
      response.json({ data: project });
    }, { admin: true }),
  );

  app.post(
    '/admin/projects',
    withAuth(async (request, response, auth) => {
      const body = projectSchema.parse(request.body ?? {});
      const project = await recordingService.createProject(auth.userId, {
        name: body.name,
        slug: body.slug ?? slugify(body.name),
      });
      response.status(201).json({ data: project });
    }, { admin: true }),
  );

  app.patch(
    '/admin/projects/:id',
    withAuth(async (request, response, auth) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const body = projectPatchSchema.parse(request.body ?? {});
      const project = await recordingService.updateProject(auth.userId, params.id, body);
      response.json({ data: project });
    }, { admin: true }),
  );

  app.get(
    '/admin/projects/:id/members',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      await recordingService.getAdminProjectOrThrow(params.id);
      const members = await recordingService.listProjectMembersAdmin(params.id);
      response.json({ data: members });
    }, { admin: true }),
  );

  app.post(
    '/admin/projects/:id/members',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const body = projectMemberSchema.parse(request.body ?? {});
      await recordingService.getAdminProjectOrThrow(params.id);
      const member = await recordingService.addProjectMemberAdmin(params.id, body);
      response.status(201).json({ data: member });
    }, { admin: true }),
  );

  app.delete(
    '/admin/projects/:id/members/:userId',
    withAuth(async (request, response) => {
      const params = z
        .object({
          id: z.string().min(1),
          userId: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      await recordingService.getAdminProjectOrThrow(params.id);
      await recordingService.removeProjectMemberAdmin(params.id, params.userId);
      response.status(204).send();
    }, { admin: true }),
  );

  app.get(
    '/admin/recordings',
    withAuth(async (request, response) => {
      const query = z
        .object({
          query: z.string().min(1).optional(),
          projectId: z.string().min(1).optional(),
          userId: z.string().min(1).optional(),
          sourceApp: z.enum(captureSourceApps).optional(),
          platform: z.enum(capturePlatforms).optional(),
          status: z.enum(['uploaded', 'processing_transcript', 'processing_summary', 'indexing', 'ready', 'failed']).optional(),
      })
        .strict()
        .parse(request.query);
      const recordings = await recordingService.listAdminRecordings(query);
      const decorated = await decorateAdminRecordings(recordingService, recordings);
      response.json({ data: decorated });
    }, { admin: true }),
  );

  app.get(
    '/admin/recordings/:id',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const recording = await recordingService.getAdminRecordingOrThrow(params.id);
      const [decorated] = await decorateAdminRecordings(recordingService, [recording]);
      response.json({ data: decorated });
    }, { admin: true }),
  );

  app.post(
    '/admin/recordings/:id/export',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const body = exportSchema.parse(request.body ?? {});
      const artifact = await recordingService.exportAdmin(params.id, body.format);
      response.json({ data: artifact });
    }, { admin: true }),
  );

  app.post(
    '/admin/recordings/:id/reprocess',
    withAuth(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const recording = await recordingService.processAdmin(params.id);
      response.json({ data: recording });
    }, { admin: true }),
  );

  app.get(
    '/admin/jobs',
    withAuth(async (request, response) => {
      const query = z
        .object({
          query: z.string().min(1).optional(),
          projectId: z.string().min(1).optional(),
          userId: z.string().min(1).optional(),
          sourceApp: z.enum(captureSourceApps).optional(),
          platform: z.enum(capturePlatforms).optional(),
          status: z.enum(['uploaded', 'processing_transcript', 'processing_summary', 'indexing', 'ready', 'failed']).optional(),
        })
        .strict()
        .parse(request.query);
      const recordings = await recordingService.listAdminRecordings(query);
      response.json({
        data: recordings.map((recording) => ({
          recordingId: recording.id,
          projectId: recording.projectId,
          title: recording.title,
          status: recording.status,
          transcriptionProvider: recording.transcriptionProvider,
          transcriptionJobId: recording.transcriptionJobId,
          transcriptionStartedAt: recording.transcriptionStartedAt,
          transcriptionCompletedAt: recording.transcriptionCompletedAt,
          lastError: recording.lastError,
        })),
      });
    }, { admin: true }),
  );

  app.get(
    '/admin/providers',
    withAuth(async (_request, response) => {
      response.json({
        data: {
          aiProvider: config.AI_PROVIDER,
          transcriptionProvider: config.TRANSCRIPTION_PROVIDER,
          assemblyAiSpeechModel: config.ASSEMBLYAI_SPEECH_MODEL,
          supabasePersistenceMode: config.SUPABASE_PERSISTENCE_MODE,
          supabaseStorageBucket: config.SUPABASE_STORAGE_BUCKET,
        },
      });
    }, { admin: true }),
  );

  app.patch(
    '/admin/providers',
    withAuth(async (request, response) => {
      const body = z
        .object({
          aiProvider: z.enum(['mock', 'openai']).optional(),
          transcriptionProvider: z.enum(['mock', 'assemblyai']).optional(),
          assemblyAiSpeechModel: z.enum(['universal-2', 'universal-3-pro']).optional(),
        })
        .strict()
        .parse(request.body ?? {});
      response.json({
        data: {
          message: 'Provider settings are environment-driven in this version.',
          requested: body,
        },
      });
    }, { admin: true }),
  );

  app.use((error: unknown, _request: express.Request, response: express.Response, _next: express.NextFunction) => {
    const parsed = parseError(error);
    if (!isServiceError(error) && !(error instanceof z.ZodError)) {
      console.error('Unhandled backend error:', error);
    }
    response.status(parsed.statusCode).json(parsed.body);
  });

  return app;
}
