import { randomUUID } from 'node:crypto';

import type { SupabaseClient } from '@supabase/supabase-js';

import type { RecordingRepository } from '../domain/contracts.js';
import type { CreateRecordingInput, Recording } from '../domain/types.js';
import { config } from '../lib/config.js';
import {
  deserializeRecordingGraph,
  resolveStorageUserId,
  serializeRecordingGraph,
} from '../lib/persistence.js';
import { createSupabaseAdminClient, hasSupabasePersistenceConfig } from '../lib/supabase-admin.js';

const nowIso = () => new Date().toISOString();

export class MemoryRecordingRepository implements RecordingRepository {
  private readonly recordings = new Map<string, Recording>();
  private readonly supabase: SupabaseClient | null;
  private readonly persistenceMode: 'memory' | 'supabase';

  constructor(seed: Recording[] = []) {
    const wantsSupabase =
      config.SUPABASE_PERSISTENCE_MODE === 'supabase' ||
      (config.SUPABASE_PERSISTENCE_MODE === 'auto' && hasSupabasePersistenceConfig());

    this.persistenceMode = wantsSupabase ? 'supabase' : 'memory';
    this.supabase = wantsSupabase ? createSupabaseAdminClient() : null;

    if (this.persistenceMode === 'memory') {
      for (const recording of seed) {
        this.recordings.set(recording.id, structuredClone(recording));
      }
    }
  }

  async list(userId: string, filters?: { query?: string; tag?: string }): Promise<Recording[]> {
    if (this.persistenceMode === 'supabase') {
      return this.listFromSupabase(userId, filters);
    }

    const values = [...this.recordings.values()]
      .filter((recording) => recording.userId === userId)
      .filter((recording) => matchesFilters(recording, filters))
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));

    return structuredClone(values);
  }

  async getById(recordingId: string, userId: string): Promise<Recording | null> {
    if (this.persistenceMode === 'supabase') {
      return this.getFromSupabase(recordingId, userId);
    }

    const recording = this.recordings.get(recordingId);
    if (!recording || recording.userId !== userId) {
      return null;
    }

    return structuredClone(recording);
  }

  async create(userId: string, input: CreateRecordingInput): Promise<Recording> {
    const timestamp = nowIso();
    const recording: Recording = {
      id: randomUUID(),
      userId,
      title: input.title,
      sourceType: input.sourceType,
      createdAt: timestamp,
      updatedAt: timestamp,
      durationMs: input.durationMs,
      audioPath: input.audioPath,
      status: 'uploaded',
      transcriptSegments: [],
      chatSession: {
        id: randomUUID(),
        recordingId: '',
        messages: [],
      },
    };
    recording.chatSession!.recordingId = recording.id;

    if (this.persistenceMode === 'supabase') {
      return this.upsertToSupabase(recording);
    }

    this.recordings.set(recording.id, structuredClone(recording));
    return structuredClone(recording);
  }

  async update(recording: Recording): Promise<Recording> {
    const next = {
      ...recording,
      updatedAt: nowIso(),
    };

    if (this.persistenceMode === 'supabase') {
      return this.upsertToSupabase(next);
    }

    this.recordings.set(next.id, structuredClone(next));
    return structuredClone(next);
  }

  private async listFromSupabase(
    userId: string,
    filters?: { query?: string; tag?: string },
  ): Promise<Recording[]> {
    const storageUserId = resolveStorageUserId(userId);
    const supabase = this.ensureSupabaseClient();

    const { data, error } = await supabase
      .from('recordings')
      .select('id')
      .eq('user_id', storageUserId)
      .order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    const recordings = await Promise.all(
      (data ?? []).map(async (row) => {
        const graph = await this.fetchGraph(String(row.id), userId);
        return graph;
      }),
    );

    return recordings
      .filter((recording): recording is Recording => recording !== null)
      .filter((recording) => matchesFilters(recording, filters))
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));
  }

  private async getFromSupabase(recordingId: string, userId: string): Promise<Recording | null> {
    const storageUserId = resolveStorageUserId(userId);
    const supabase = this.ensureSupabaseClient();

    const { data, error } = await supabase
      .from('recordings')
      .select('id')
      .eq('id', recordingId)
      .eq('user_id', storageUserId)
      .maybeSingle();

    if (error) {
      throw error;
    }

    if (!data) {
      return null;
    }

    return this.fetchGraph(recordingId, userId);
  }

  private async fetchGraph(recordingId: string, userId: string): Promise<Recording | null> {
    const supabase = this.ensureSupabaseClient();
    const { data, error } = await supabase.rpc('get_recording_graph', {
      recording_id: recordingId,
    });

    if (error) {
      throw error;
    }

    if (!data) {
      return null;
    }

    return deserializeRecordingGraph(data, userId);
  }

  private async upsertToSupabase(recording: Recording): Promise<Recording> {
    const supabase = this.ensureSupabaseClient();
    const payload = serializeRecordingGraph(recording, resolveStorageUserId(recording.userId));

    const { data, error } = await supabase.rpc('upsert_recording_graph', {
      payload,
    });

    if (error) {
      throw error;
    }

    return deserializeRecordingGraph(data, recording.userId);
  }

  private ensureSupabaseClient(): SupabaseClient {
    if (!this.supabase) {
      throw new Error('Supabase client is not configured');
    }

    return this.supabase;
  }
}

function matchesFilters(recording: Recording, filters?: { query?: string; tag?: string }): boolean {
  if (!filters) {
    return true;
  }

  const query = filters.query?.trim().toLowerCase();
  if (query) {
    const haystack = [
      recording.title,
      recording.summary?.overview ?? '',
      recording.noteArtifact?.tags.join(' ') ?? '',
      recording.transcriptSegments.map((segment) => segment.text).join(' '),
    ]
      .join(' ')
      .toLowerCase();

    if (!haystack.includes(query)) {
      return false;
    }
  }

  const tag = filters.tag?.trim().toLowerCase();
  if (tag) {
    const tags = recording.noteArtifact?.tags ?? [];
    if (!tags.some((value) => value.toLowerCase() === tag)) {
      return false;
    }
  }

  return true;
}
