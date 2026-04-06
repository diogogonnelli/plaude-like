import { mkdir, unlink } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname } from 'node:path';
import { spawn } from 'node:child_process';

import ffmpegPath from 'ffmpeg-static';

export async function transcodeWebmToM4a(inputPath, outputPath) {
  const resolvedFfmpegPath = resolveFfmpegBinaryPath(ffmpegPath);
  if (!resolvedFfmpegPath) {
    throw new Error('ffmpeg-static binary is unavailable.');
  }

  await mkdir(dirname(outputPath), { recursive: true });

  await new Promise((resolve, reject) => {
    const process = spawn(resolvedFfmpegPath, [
      '-y',
      '-i',
      inputPath,
      '-vn',
      '-c:a',
      'aac',
      '-b:a',
      '128k',
      outputPath,
    ], {
      stdio: ['ignore', 'ignore', 'pipe'],
    });

    let errorOutput = '';
    process.stderr.on('data', (chunk) => {
      errorOutput += chunk.toString();
    });

    process.on('error', reject);
    process.on('close', (code) => {
      if (code === 0) {
        resolve();
        return;
      }

      reject(new Error(`ffmpeg exited with code ${code}. ${errorOutput}`));
    });
  });

  await unlink(inputPath).catch(() => undefined);
}

export function resolveFfmpegBinaryPath(rawPath) {
  if (!rawPath) {
    return null;
  }

  const unpackedPath = rawPath.replace('app.asar\\', 'app.asar.unpacked\\').replace('app.asar/', 'app.asar.unpacked/');
  if (unpackedPath !== rawPath && existsSync(unpackedPath)) {
    return unpackedPath;
  }

  if (existsSync(rawPath)) {
    return rawPath;
  }

  return rawPath;
}
