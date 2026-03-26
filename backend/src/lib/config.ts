import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().default(8787),
  APP_BASE_URL: z.string().url().default('http://localhost:8787'),
  OPENAI_API_KEY: z.string().optional(),
  OPENAI_MODEL: z.string().default('gpt-5-mini'),
  OPENAI_EMBEDDING_MODEL: z.string().default('text-embedding-3-small'),
  SUPABASE_URL: z.string().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  SUPABASE_PERSISTENCE_MODE: z.enum(['auto', 'memory', 'supabase']).default('auto'),
  SUPABASE_STORAGE_BUCKET: z.string().default('recordings'),
  AI_PROVIDER: z.enum(['mock', 'openai']).default('mock'),
});

export const config = envSchema.parse(process.env);
