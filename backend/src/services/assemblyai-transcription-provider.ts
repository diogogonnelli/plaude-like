import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';

import { config } from '../lib/config.js';
import { ServiceError } from './service-errors.js';

export interface AssemblyAiTranscriptResult {
  status: 'queued' | 'processing' | 'completed' | 'error';
  text?: string;
  error?: string;
  utterances: Array<{
    speaker?: string | number;
    start?: number;
    end?: number;
    text: string;
  }>;
}

export class AssemblyAiTranscriptionProvider {
  private readonly baseUrl = 'https://api.assemblyai.com/v2';

  private get headers() {
    if (!config.ASSEMBLYAI_API_KEY) {
      throw new ServiceError(
        'ASSEMBLYAI_API_KEY is required when TRANSCRIPTION_PROVIDER=assemblyai.',
        500,
        'assemblyai_api_key_missing',
      );
    }

    return {
      authorization: config.ASSEMBLYAI_API_KEY,
    };
  }

  async uploadFile(filePath: string, mimeType?: string): Promise<string> {
    const fileStats = await stat(filePath);
    const response = await fetch(`${this.baseUrl}/upload`, {
      method: 'POST',
      headers: {
        ...this.headers,
        'content-type': mimeType ?? 'application/octet-stream',
        'content-length': String(fileStats.size),
      },
      body: createReadStream(filePath) as unknown as BodyInit,
      duplex: 'half',
    } as RequestInit & { duplex: 'half' });

    if (!response.ok) {
      throw new ServiceError(
        `AssemblyAI upload failed with ${response.status}.`,
        502,
        'assemblyai_upload_failed',
        { body: await response.text() },
      );
    }

    const payload = await response.json() as { upload_url?: string };
    if (!payload.upload_url) {
      throw new ServiceError('AssemblyAI upload did not return upload_url.', 502, 'assemblyai_upload_url_missing');
    }

    return payload.upload_url;
  }

  async createTranscript(args: {
    audioUrl: string;
    recordingId: string;
    userId: string;
  }): Promise<string> {
    const webhookUrl = `${config.APP_BASE_URL}/webhooks/assemblyai?recordingId=${encodeURIComponent(args.recordingId)}&userId=${encodeURIComponent(args.userId)}`;

    const response = await fetch(`${this.baseUrl}/transcript`, {
      method: 'POST',
      headers: {
        ...this.headers,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        audio_url: args.audioUrl,
        speech_models: [config.ASSEMBLYAI_SPEECH_MODEL],
        speaker_labels: true,
        language_detection: true,
        webhook_url: webhookUrl,
      }),
    });

    if (!response.ok) {
      throw new ServiceError(
        `AssemblyAI transcript creation failed with ${response.status}.`,
        502,
        'assemblyai_transcript_create_failed',
        { body: await response.text() },
      );
    }

    const payload = await response.json() as { id?: string };
    if (!payload.id) {
      throw new ServiceError('AssemblyAI transcript did not return id.', 502, 'assemblyai_transcript_id_missing');
    }

    return payload.id;
  }

  async getTranscript(transcriptId: string): Promise<AssemblyAiTranscriptResult> {
    const response = await fetch(`${this.baseUrl}/transcript/${transcriptId}`, {
      headers: this.headers,
    });

    if (!response.ok) {
      throw new ServiceError(
        `AssemblyAI transcript fetch failed with ${response.status}.`,
        502,
        'assemblyai_transcript_fetch_failed',
        { body: await response.text(), transcriptId },
      );
    }

    const payload = await response.json() as {
      status?: string;
      text?: string;
      error?: string;
      utterances?: Array<{
        speaker?: string | number;
        start?: number;
        end?: number;
        text: string;
      }>;
    };

    return {
      status: (payload.status as AssemblyAiTranscriptResult['status']) ?? 'processing',
      text: payload.text,
      error: payload.error,
      utterances: payload.utterances ?? [],
    };
  }
}
