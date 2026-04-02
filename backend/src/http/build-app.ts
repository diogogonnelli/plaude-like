import cors from 'cors';
import express from 'express';
import multer from 'multer';
import { tmpdir } from 'node:os';
import swaggerUi from 'swagger-ui-express';
import { z } from 'zod';

import { config } from '../lib/config.js';
import { ServiceError, isServiceError } from '../services/service-errors.js';
import type { RecordingService } from '../services/recording-service.js';
import { buildOpenApiDocument } from './openapi.js';

const userHeader = 'x-user-id';

const createRecordingSchema = z
  .object({
    title: z.string().min(1),
    projectId: z.string().min(1),
    sourceType: z.enum(['microphone', 'upload']),
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
    sourceType: z.enum(['microphone', 'upload']).default('upload'),
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

function getUserId(request: express.Request) {
  return request.header(userHeader) ?? 'demo-user';
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

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60) || 'project';
}

export function buildApp(recordingService: RecordingService) {
  const app = express();
  const openApiDocument = buildOpenApiDocument(config.APP_BASE_URL);
  const upload = multer({
    dest: tmpdir(),
    limits: {
      fileSize: 1024 * 1024 * 512,
    },
  });
  app.use(cors());
  app.use(express.json({ limit: '8mb' }));

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
    asyncRoute(async (request, response) => {
      const query = z
        .object({
          query: z.string().min(1).optional(),
          tag: z.string().min(1).optional(),
          _ts: z.string().optional(),
        })
        .strict()
        .parse(request.query);

      const recordings = await recordingService.list(getUserId(request), query);
      response.json({ data: recordings });
    }),
  );

  app.get(
    '/projects',
    asyncRoute(async (request, response) => {
      const projects = await recordingService.listProjects(getUserId(request));
      response.json({ data: projects });
    }),
  );

  app.get(
    '/projects/:id',
    asyncRoute(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const project = await recordingService.getProjectOrThrow(params.id, getUserId(request));
      response.json({ data: project });
    }),
  );

  app.post(
    '/recordings',
    asyncRoute(async (request, response) => {
      const body = createRecordingSchema.parse(request.body ?? {});
      const recording = await recordingService.create(getUserId(request), body);
      response.status(201).json({
        data: recording,
        upload: {
          bucket: 'recordings',
          objectPath: recording.audioPath ?? `${recording.id}.m4a`,
        },
      });
    }),
  );

  app.post(
    '/recordings/upload',
    upload.single('file'),
    asyncRoute(async (request, response) => {
      const file = request.file;
      if (!file) {
        throw new ServiceError('Arquivo de audio nao enviado.', 400, 'audio_file_missing');
      }

      const body = uploadRecordingSchema.parse(request.body ?? {});
      const recording = await recordingService.uploadAndStartTranscription(getUserId(request), {
        title: body.title,
        projectId: body.projectId,
        sourceType: body.sourceType,
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
    asyncRoute(async (request, response) => {
      const params = z
        .object({
          id: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      const body = processRecordingSchema.parse(request.body ?? {});
      const recording = await recordingService.process(params.id, getUserId(request), body);
      response.json({ data: recording });
    }),
  );

  app.get(
    '/recordings/:id',
    asyncRoute(async (request, response) => {
      const params = z
        .object({
          id: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      const recording = await recordingService.getOrThrow(params.id, getUserId(request));
      response.json({ data: recording });
    }),
  );

  app.post(
    '/recordings/:id/chat',
    asyncRoute(async (request, response) => {
      const params = z
        .object({
          id: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      const body = chatSchema.parse(request.body ?? {});
      const payload = await recordingService.answerQuestion(params.id, getUserId(request), body.question);
      response.json(payload);
    }),
  );

  app.post(
    '/recordings/:id/export',
    asyncRoute(async (request, response) => {
      const params = z
        .object({
          id: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      const body = exportSchema.parse(request.body ?? {});
      const artifact = await recordingService.export(params.id, getUserId(request), body.format);
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
    asyncRoute(async (_request, response) => {
      const recordings = await recordingService.listAdminRecordings();
      response.json({
        data: {
          totalRecordings: recordings.length,
          processing: recordings.filter((item) => item.status !== 'ready' && item.status !== 'failed').length,
          failed: recordings.filter((item) => item.status === 'failed').length,
          ready: recordings.filter((item) => item.status === 'ready').length,
        },
      });
    }),
  );

  app.get(
    '/admin/projects',
    asyncRoute(async (_request, response) => {
      const projects = await recordingService.listProjects('demo-user');
      response.json({ data: projects });
    }),
  );

  app.post(
    '/admin/projects',
    asyncRoute(async (request, response) => {
      const body = projectSchema.parse(request.body ?? {});
      const project = await recordingService.createProject('demo-user', {
        name: body.name,
        slug: body.slug ?? slugify(body.name),
      });
      response.status(201).json({ data: project });
    }),
  );

  app.patch(
    '/admin/projects/:id',
    asyncRoute(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const body = projectPatchSchema.parse(request.body ?? {});
      const project = await recordingService.updateProject('demo-user', params.id, body);
      response.json({ data: project });
    }),
  );

  app.get(
    '/admin/projects/:id/members',
    asyncRoute(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const members = await recordingService.listProjectMembers('demo-user', params.id);
      response.json({ data: members });
    }),
  );

  app.post(
    '/admin/projects/:id/members',
    asyncRoute(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const body = projectMemberSchema.parse(request.body ?? {});
      const member = await recordingService.addProjectMember('demo-user', params.id, body);
      response.status(201).json({ data: member });
    }),
  );

  app.delete(
    '/admin/projects/:id/members/:userId',
    asyncRoute(async (request, response) => {
      const params = z
        .object({
          id: z.string().min(1),
          userId: z.string().min(1),
        })
        .strict()
        .parse(request.params);
      await recordingService.removeProjectMember('demo-user', params.id, params.userId);
      response.status(204).send();
    }),
  );

  app.get(
    '/admin/recordings',
    asyncRoute(async (request, response) => {
      const query = z
        .object({
          query: z.string().min(1).optional(),
          projectId: z.string().min(1).optional(),
          userId: z.string().min(1).optional(),
          status: z.enum(['uploaded', 'processing_transcript', 'processing_summary', 'indexing', 'ready', 'failed']).optional(),
        })
        .strict()
        .parse(request.query);
      const recordings = await recordingService.listAdminRecordings(query);
      response.json({ data: recordings });
    }),
  );

  app.get(
    '/admin/recordings/:id',
    asyncRoute(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const recording = await recordingService.getOrThrow(params.id, 'demo-user');
      response.json({ data: recording });
    }),
  );

  app.post(
    '/admin/recordings/:id/reprocess',
    asyncRoute(async (request, response) => {
      const params = z.object({ id: z.string().min(1) }).strict().parse(request.params);
      const recording = await recordingService.process(params.id, 'demo-user');
      response.json({ data: recording });
    }),
  );

  app.get(
    '/admin/jobs',
    asyncRoute(async (_request, response) => {
      const recordings = await recordingService.listAdminRecordings();
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
    }),
  );

  app.get(
    '/admin/providers',
    asyncRoute(async (_request, response) => {
      response.json({
        data: {
          aiProvider: config.AI_PROVIDER,
          transcriptionProvider: config.TRANSCRIPTION_PROVIDER,
          assemblyAiSpeechModel: config.ASSEMBLYAI_SPEECH_MODEL,
          supabasePersistenceMode: config.SUPABASE_PERSISTENCE_MODE,
          supabaseStorageBucket: config.SUPABASE_STORAGE_BUCKET,
        },
      });
    }),
  );

  app.patch(
    '/admin/providers',
    asyncRoute(async (request, response) => {
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
    }),
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
