import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { readFile } from 'node:fs/promises';

import { config } from './config.js';
import { ServiceError } from '../services/service-errors.js';

export function hasSupabasePersistenceConfig(): boolean {
  return Boolean(config.SUPABASE_URL && config.SUPABASE_SERVICE_ROLE_KEY);
}

export function createSupabaseAdminClient(): SupabaseClient | null {
  if (!hasSupabasePersistenceConfig()) {
    return null;
  }

  return createClient(config.SUPABASE_URL!, config.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

export function requireSupabaseAdminClient(): SupabaseClient {
  const client = createSupabaseAdminClient();
  if (!client) {
    throw new Error('Supabase admin client is not configured');
  }

  return client;
}

export async function uploadAudioToStorage(args: {
  objectPath: string;
  filePath: string;
  contentType?: string;
}): Promise<void> {
  const client = requireSupabaseAdminClient();
  const bytes = await readFile(args.filePath);
  const { error } = await client.storage
    .from(config.SUPABASE_STORAGE_BUCKET)
    .upload(args.objectPath, bytes, {
      contentType: args.contentType ?? 'application/octet-stream',
      upsert: true,
    });

  if (error) {
    throw new ServiceError(
      `Falha ao enviar audio para o Supabase Storage: ${error.message}`,
      502,
      'supabase_storage_upload_failed',
      {
        objectPath: args.objectPath,
        bucket: config.SUPABASE_STORAGE_BUCKET,
      },
    );
  }
}
