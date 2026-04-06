import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { CompanionStore } from '../src/store/companion-store.js';

test('CompanionStore persists session and queue items', async () => {
  const baseDir = await mkdtemp(join(tmpdir(), 'companion-store-'));

  try {
    const store = new CompanionStore(baseDir);
    await store.load();
    await store.setSession({
      accessToken: 'access',
      refreshToken: 'refresh',
      email: 'user@example.com',
      userId: 'user-1',
      expiresAt: 123,
    });
    await store.upsertQueueItem({
      id: 'queue-1',
      title: 'Meeting',
      status: 'pending',
      filePath: '/tmp/meeting.m4a',
      projectId: 'project-1',
      sourceType: 'desktop_meeting',
      createdAt: new Date().toISOString(),
      captureMetadata: {
        sourceApp: 'teams',
        platform: 'windows',
        captureMode: 'system_and_mic',
        helperVersion: '0.1.0',
      },
    });

    const reloaded = new CompanionStore(baseDir);
    await reloaded.load();

    assert.equal(reloaded.getSession()?.email, 'user@example.com');
    assert.equal(reloaded.listQueue().length, 1);
    assert.equal(reloaded.listQueue()[0]?.captureMetadata?.sourceApp, 'teams');
  } finally {
    await rm(baseDir, { recursive: true, force: true });
  }
});
