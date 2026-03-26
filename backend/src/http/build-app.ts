import cors from 'cors';
import express from 'express';
import { z } from 'zod';

import { isServiceError } from '../services/service-errors.js';
import type { RecordingService } from '../services/recording-service.js';

const userHeader = 'x-user-id';

const createRecordingSchema = z
  .object({
    title: z.string().min(1),
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
        error: 'Invalid request',
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
      error: error instanceof Error ? error.message : 'Unexpected server error',
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

export function buildApp(recordingService: RecordingService) {
  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '8mb' }));

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
        })
        .strict()
        .parse(request.query);

      const recordings = await recordingService.list(getUserId(request), query);
      response.json({ data: recordings });
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

  app.use((error: unknown, _request: express.Request, response: express.Response, _next: express.NextFunction) => {
    const parsed = parseError(error);
    response.status(parsed.statusCode).json(parsed.body);
  });

  return app;
}
