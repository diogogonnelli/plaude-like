import { createWriteStream } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';

import { transcodeWebmToM4a } from './audio-converter.js';

export class CaptureSessionManager {
  constructor({ baseDir, uploadQueue, appVersion, platform }) {
    this.baseDir = baseDir;
    this.uploadQueue = uploadQueue;
    this.appVersion = appVersion;
    this.platform = platform;
    this.sessions = new Map();
  }

  async openSession() {
    const sessionId = randomUUID();
    const tempDir = join(this.baseDir, 'temp');
    await mkdir(tempDir, { recursive: true });

    const webmPath = join(tempDir, `${sessionId}.webm`);
    const stream = createWriteStream(webmPath, { flags: 'a' });
    this.sessions.set(sessionId, {
      id: sessionId,
      webmPath,
      stream,
    });

    return { sessionId };
  }

  async appendChunk(sessionId, chunk) {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new Error('Capture session not found.');
    }

    await new Promise((resolve, reject) => {
      session.stream.write(Buffer.from(chunk), (error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });
  }

  async finalizeSession(sessionId, payload) {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new Error('Capture session not found.');
    }

    await new Promise((resolve, reject) => {
      session.stream.end((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });

    this.sessions.delete(sessionId);

    const completedDir = join(this.baseDir, 'completed');
    await mkdir(completedDir, { recursive: true });
    const m4aPath = join(completedDir, `${sessionId}.m4a`);
    await transcodeWebmToM4a(session.webmPath, m4aPath);

    const queueItem = {
      id: sessionId,
      filePath: m4aPath,
      mimeType: 'audio/mp4',
      title: payload.title,
      projectId: payload.projectId,
      sourceType: 'desktop_meeting',
      durationMs: payload.durationMs,
      createdAt: new Date().toISOString(),
      captureMetadata: {
        sourceApp: payload.sourceApp,
        platform: this.platform,
        captureMode: 'system_and_mic',
        helperVersion: this.appVersion,
        windowTitle: payload.windowTitle ?? null,
      },
    };

    await this.uploadQueue.enqueueUpload(queueItem);
    return queueItem;
  }

  async abortSession(sessionId) {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return false;
    }

    await new Promise((resolve) => {
      session.stream.end(() => resolve());
    });
    this.sessions.delete(sessionId);
    return true;
  }
}
