import { createClient, type SupabaseClient } from '@supabase/supabase-js';

import { config } from './config.js';

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
