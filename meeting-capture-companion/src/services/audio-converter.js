import { mkdir, unlink } from 'node:fs/promises';
import { dirname } from 'node:path';
import { spawn } from 'node:child_process';

import ffmpegPath from 'ffmpeg-static';

export async function transcodeWebmToM4a(inputPath, outputPath) {
  if (!ffmpegPath) {
    throw new Error('ffmpeg-static binary is unavailable.');
  }

  await mkdir(dirname(outputPath), { recursive: true });

  await new Promise((resolve, reject) => {
    const process = spawn(ffmpegPath, [
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
