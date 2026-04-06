import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { CompanionStore } from '../src/store/companion-store.js';
import { UploadQueueService } from '../src/services/upload-queue.js';

test('UploadQueueService marks items as uploaded after successful upload', async () => {
  const baseDir = await mkdtemp(join(tmpdir(), 'upload-queue-'));
  const originalFetch = global.fetch;

  try {
    const store = new CompanionStore(baseDir);
    await store.load();

    const filePath = join(baseDir, 'meeting.m4a');
    await writeFile(filePath, 'fake-audio');

    global.fetch = async () => ({
      ok: true,
      json: async () => ({ data: { id: 'recording-1' } }),
    });

    const queue = new UploadQueueService({
      backendBaseUrl: 'http://localhost:8787',
      store,
      getAccessToken: () => 'token-1',
    });

    await queue.enqueueUpload({
      id: 'queue-1',
      filePath,
      mimeType: 'audio/mp4',
      title: 'Meeting',
      projectId: 'project-1',
      sourceType: 'desktop_meeting',
      durationMs: 1234,
      createdAt: new Date().toISOString(),
      captureMetadata: {
        sourceApp: 'teams',
        platform: 'windows',
        captureMode: 'system_and_mic',
        helperVersion: '0.1.0',
      },
    });

    await queue.processPendingUploads();

    assert.equal(queue.listQueue()[0]?.status, 'uploaded');
  } finally {
    global.fetch = originalFetch;
    await rm(baseDir, { recursive: true, force: true });
  }
});
