import { randomUUID } from 'node:crypto';

import OpenAI from 'openai';

import { config } from '../lib/config.js';
import type { AiProcessingResult, AiProvider, ChatAnswer } from '../domain/contracts.js';
import type { ProcessRecordingInput, Recording, TranscriptSegment } from '../domain/types.js';
import { ServiceError } from './service-errors.js';

function normalizeSegments(recordingId: string, transcriptText: string): TranscriptSegment[] {
  return transcriptText
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line, index) => {
      const [speaker, ...rest] = line.split(':');
      const startMs = index * 30_000;
      return {
        id: randomUUID(),
        recordingId,
        speakerLabel: rest.length > 0 ? speaker.trim() : `Speaker ${(index % 2) + 1}`,
        startMs,
        endMs: startMs + 24_000,
        text: rest.length > 0 ? rest.join(':').trim() : line,
      };
    });
}

function extractJsonObject(raw: string): string {
  const trimmed = raw.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    return trimmed;
  }

  const codeFenceMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (codeFenceMatch?.[1]) {
    return codeFenceMatch[1].trim();
  }

  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return trimmed.slice(start, end + 1);
  }

  throw new ServiceError('Provider returned non-JSON content.', 502, 'provider_invalid_payload');
}

function parseJson<T>(raw: string): T {
  const payload = extractJsonObject(raw);
  return JSON.parse(payload) as T;
}

function mapSupportingQuotesToCitations(
  recording: Recording,
  supportingQuotes: string[] | undefined,
) {
  const quotes = supportingQuotes?.filter((item) => item.trim().length > 0) ?? [];
  const citations = recording.transcriptSegments.filter((segment) =>
    quotes.some((quote) => segment.text.toLowerCase().includes(quote.toLowerCase().slice(0, 18))),
  );

  const selected = citations.length > 0 ? citations : recording.transcriptSegments.slice(0, 2);
  return selected.map((segment) => ({
    segmentId: segment.id,
    startMs: segment.startMs,
    endMs: segment.endMs,
    quote: segment.text,
  }));
}

export class OpenAiProvider implements AiProvider {
  private readonly client: OpenAI;

  constructor() {
    if (!config.OPENAI_API_KEY) {
      throw new ServiceError(
        'OPENAI_API_KEY is required when AI_PROVIDER=openai.',
        500,
        'openai_api_key_missing',
      );
    }

    this.client = new OpenAI({ apiKey: config.OPENAI_API_KEY });
  }

  async processRecording(recording: Recording, input?: ProcessRecordingInput): Promise<AiProcessingResult> {
    const transcriptText = input?.transcriptText?.trim();
    if (!transcriptText) {
      throw new ServiceError(
        'Transcript text is required for OpenAI processing.',
        400,
        'transcript_required',
      );
    }

    const prompt = [
      'You are processing a meeting note.',
      'Return JSON only with keys: title, overview, tags, highlights, actionItems, chapters.',
      'chapters must be an array of { heading, body }.',
      'Use concise business language.',
      'Transcript:',
      transcriptText,
    ].join('\n');

    const response = await this.client.responses.create({
      model: config.OPENAI_MODEL,
      input: prompt,
      text: {
        format: {
          type: 'json_schema',
          name: 'recording_summary',
          schema: {
            type: 'object',
            additionalProperties: false,
            required: ['title', 'overview', 'tags', 'highlights', 'actionItems', 'chapters'],
            properties: {
              title: { type: 'string' },
              overview: { type: 'string' },
              tags: { type: 'array', items: { type: 'string' } },
              highlights: { type: 'array', items: { type: 'string' } },
              actionItems: { type: 'array', items: { type: 'string' } },
              chapters: {
                type: 'array',
                items: {
                  type: 'object',
                  additionalProperties: false,
                  required: ['heading', 'body'],
                  properties: {
                    heading: { type: 'string' },
                    body: { type: 'string' },
                  },
                },
              },
            },
          },
        },
      },
    });

    const payload = parseJson<{
      title: string;
      overview: string;
      tags: string[];
      highlights: string[];
      actionItems: string[];
      chapters: Array<{ heading: string; body: string }>;
    }>(response.output_text);

    return {
      title: payload.title,
      overview: payload.overview,
      tags: payload.tags,
      highlights: payload.highlights,
      actionItems: payload.actionItems,
      chapters: payload.chapters,
      transcriptSegments: normalizeSegments(recording.id, transcriptText),
    };
  }

  async answerQuestion(recording: Recording, question: string): Promise<ChatAnswer> {
    const transcript = recording.transcriptSegments
      .map((segment) => `[${segment.startMs}-${segment.endMs}] ${segment.speakerLabel}: ${segment.text}`)
      .join('\n');

    const response = await this.client.responses.create({
      model: config.OPENAI_MODEL,
      input: [
        'Answer only from the provided transcript and summary.',
        'Return JSON only with keys: answer, supportingQuotes.',
        'supportingQuotes must be a string array copied from the transcript.',
        `Question: ${question}`,
        `Summary: ${recording.summary?.overview ?? ''}`,
        'Transcript:',
        transcript,
      ].join('\n'),
      text: {
        format: {
          type: 'json_schema',
          name: 'recording_answer',
          schema: {
            type: 'object',
            additionalProperties: false,
            required: ['answer', 'supportingQuotes'],
            properties: {
              answer: { type: 'string' },
              supportingQuotes: { type: 'array', items: { type: 'string' } },
            },
          },
        },
      },
    });

    const payload = parseJson<{
      answer: string;
      supportingQuotes: string[];
    }>(response.output_text);

    return {
      answer: payload.answer,
      citations: mapSupportingQuotesToCitations(recording, payload.supportingQuotes),
    };
  }
}
