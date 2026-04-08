import 'dotenv/config';
import { z } from 'zod';

const booleanLikeSchema = z.preprocess((value) => {
  if (typeof value === 'boolean') {
    return value;
  }

  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true') {
      return true;
    }
    if (normalized === 'false') {
      return false;
    }
  }

  return value;
}, z.boolean());

const envSchema = z.object({
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().default(8787),
  APP_BASE_URL: z.string().url().default('http://localhost:8787'),
  TRUST_PROXY: booleanLikeSchema.default(false),
  OPENAI_API_KEY: z.string().optional(),
  OPENAI_MODEL: z.string().default('gpt-5-mini'),
  OPENAI_EMBEDDING_MODEL: z.string().default('text-embedding-3-small'),
  TRANSCRIPTION_PROVIDER: z.enum(['mock', 'assemblyai']).default('mock'),
  ASSEMBLYAI_API_KEY: z.string().optional(),
  ASSEMBLYAI_SPEECH_MODEL: z.enum(['universal-2', 'universal-3-pro']).default('universal-2'),
  SUPABASE_URL: z.string().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  SUPABASE_PERSISTENCE_MODE: z.enum(['auto', 'memory', 'supabase']).default('auto'),
  SUPABASE_STORAGE_BUCKET: z.string().default('recordings'),
  FIREBASE_SERVICE_ACCOUNT_JSON: z.string().optional(),
  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional(),
  AI_PROVIDER: z.enum(['mock', 'openai']).default('mock'),
});

export const config = envSchema.parse(process.env);
