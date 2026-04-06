import 'dotenv/config';

function requiredEnv(...keys) {
  for (const key of keys) {
    const value = process.env[key];
    if (value && value.trim().length > 0) {
      return value.trim();
    }
  }

  throw new Error(`Missing required environment variable. Checked: ${keys.join(', ')}`);
}

function optionalEnv(...keys) {
  for (const key of keys) {
    const value = process.env[key];
    if (value && value.trim().length > 0) {
      return value.trim();
    }
  }

  return null;
}

export const companionConfig = {
  backendBaseUrl: requiredEnv('COMPANION_BACKEND_BASE_URL', 'BACKEND_BASE_URL'),
  supabaseUrl: requiredEnv('COMPANION_SUPABASE_URL', 'SUPABASE_URL', 'VITE_SUPABASE_URL'),
  supabaseAnonKey: requiredEnv(
    'COMPANION_SUPABASE_ANON_KEY',
    'SUPABASE_ANON_KEY',
    'VITE_SUPABASE_ANON_KEY',
  ),
  appVersion: optionalEnv('COMPANION_APP_VERSION') ?? '0.1.0',
};
