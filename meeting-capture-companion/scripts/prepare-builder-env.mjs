import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = fileURLToPath(new URL('.', import.meta.url));
const projectDir = fileURLToPath(new URL('..', import.meta.url));

const sourceCandidates = [
  join(projectDir, '.env.installer'),
  join(projectDir, '.env'),
];

const sourcePath = sourceCandidates.find((candidate) => existsSync(candidate));

if (!sourcePath) {
  throw new Error('No .env.installer or .env file was found for packaging.');
}

const raw = await readFile(sourcePath, 'utf8');
const filtered = raw
  .split(/\r?\n/)
  .filter((line) => line.trim().length > 0)
  .filter((line) => !line.trim().startsWith('#'))
  .filter((line) => line.startsWith('COMPANION_') || line.startsWith('BACKEND_BASE_URL=') || line.startsWith('SUPABASE_') || line.startsWith('VITE_SUPABASE_'));

const requiredPrefixes = [
  'COMPANION_BACKEND_BASE_URL=',
  'COMPANION_SUPABASE_URL=',
  'COMPANION_SUPABASE_ANON_KEY=',
];

for (const prefix of requiredPrefixes) {
  if (!filtered.some((line) => line.startsWith(prefix))) {
    throw new Error(`Missing required installer value: ${prefix.slice(0, -1)}`);
  }
}

function requireAbsoluteUrl(key) {
  const line = filtered.find((item) => item.startsWith(`${key}=`));
  const value = line?.slice(`${key}=`.length) ?? '';

  if (!/^https?:\/\//i.test(value)) {
    throw new Error(`${key} must start with http:// or https://. Received: ${value}`);
  }
}

requireAbsoluteUrl('COMPANION_BACKEND_BASE_URL');
requireAbsoluteUrl('COMPANION_SUPABASE_URL');

const buildResourcesDir = join(projectDir, 'build-resources');
await mkdir(buildResourcesDir, { recursive: true });
await writeFile(join(buildResourcesDir, 'companion.env'), `${filtered.join('\n')}\n`, 'utf8');

console.log(`Prepared installer env from ${sourcePath}`);
