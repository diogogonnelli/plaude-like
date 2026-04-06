import { openAsBlob } from 'node:fs';
import { basename } from 'node:path';
import { unlink } from 'node:fs/promises';

export class UploadQueueService {
  constructor({ backendBaseUrl, store, getAccessToken }) {
    this.backendBaseUrl = backendBaseUrl;
    this.store = store;
    this.getAccessToken = getAccessToken;
    this.processing = false;
  }

  listQueue() {
    return this.store.listQueue();
  }

  listPendingUploads() {
    return this.store
      .listQueue()
      .filter((item) => item.status === 'pending' || item.status === 'uploading' || item.status === 'failed');
  }

  async enqueueUpload(item) {
    const queueItem = {
      status: 'pending',
      error: null,
      uploadedAt: null,
      ...item,
    };

    await this.store.upsertQueueItem(queueItem);
    await this.processPendingUploads();
    return queueItem;
  }

  async retryFailedUploads() {
    const nextItems = this.store.listQueue().map((item) => (
      item.status === 'failed'
        ? { ...item, status: 'pending', error: null }
        : item
    ));
    await this.store.replaceQueue(nextItems);
    await this.processPendingUploads();
    return this.listQueue();
  }

  async processPendingUploads() {
    if (this.processing) {
      return this.listQueue();
    }

    const accessToken = this.getAccessToken();
    if (!accessToken) {
      return this.listQueue();
    }

    this.processing = true;
    try {
      for (const item of this.store.listQueue()) {
        if (item.status === 'uploaded') {
          continue;
        }

        await this.store.upsertQueueItem({
          ...item,
          status: 'uploading',
          error: null,
        });

        try {
          await this.uploadItem(item, accessToken);
          await this.store.upsertQueueItem({
            ...item,
            status: 'uploaded',
            error: null,
            uploadedAt: new Date().toISOString(),
          });
          await unlink(item.filePath).catch(() => undefined);
        } catch (error) {
          await this.store.upsertQueueItem({
            ...item,
            status: 'failed',
            error: error instanceof Error ? error.message : String(error),
          });
        }
      }
    } finally {
      this.processing = false;
    }

    return this.listQueue();
  }

  async uploadItem(item, accessToken) {
    const form = new FormData();
    form.set('title', item.title);
    form.set('projectId', item.projectId);
    form.set('sourceType', item.sourceType);
    form.set('captureMetadata', JSON.stringify(item.captureMetadata));

    if (item.durationMs != null) {
      form.set('durationMs', String(item.durationMs));
    }

    const fileBlob = await openAsBlob(item.filePath, { type: item.mimeType ?? 'audio/mp4' });
    form.set('file', fileBlob, basename(item.filePath));

    const response = await fetch(`${this.backendBaseUrl}/recordings/upload`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
      body: form,
    });

    if (!response.ok) {
      throw new Error(`Upload failed with ${response.status}: ${await response.text()}`);
    }

    return response.json();
  }
}
