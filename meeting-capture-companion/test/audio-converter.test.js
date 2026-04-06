import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { existsSync } from 'node:fs';

import { resolveFfmpegBinaryPath } from '../src/services/audio-converter.js';

test('resolveFfmpegBinaryPath rewrites app.asar path to app.asar.unpacked when needed', async () => {
  const baseDir = await mkdtemp(join(tmpdir(), 'ffmpeg-path-'));

  try {
    const unpackedDir = join(baseDir, 'resources', 'app.asar.unpacked', 'node_modules', 'ffmpeg-static');
    const unpackedBinary = join(unpackedDir, 'ffmpeg.exe');
    await mkdir(unpackedDir, { recursive: true });
    await writeFile(unpackedBinary, 'binary');

    const rawPath = join(baseDir, 'resources', 'app.asar', 'node_modules', 'ffmpeg-static', 'ffmpeg.exe');
    assert.equal(existsSync(unpackedBinary), true);
    const resolved = resolveFfmpegBinaryPath(rawPath);

    assert.equal(resolved, unpackedBinary);
  } finally {
    await rm(baseDir, { recursive: true, force: true });
  }
});
