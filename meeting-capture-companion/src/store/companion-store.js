import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';

const defaultState = {
  session: null,
  queue: [],
};

export class CompanionStore {
  constructor(baseDir) {
    this.baseDir = baseDir;
    this.filePath = join(baseDir, 'state.json');
    this.state = structuredClone(defaultState);
  }

  async load() {
    await mkdir(dirname(this.filePath), { recursive: true });

    try {
      const raw = await readFile(this.filePath, 'utf8');
      const parsed = JSON.parse(raw);
      this.state = {
        session: parsed.session ?? null,
        queue: Array.isArray(parsed.queue) ? parsed.queue : [],
      };
    } catch (error) {
      if (error && typeof error === 'object' && 'code' in error && error.code === 'ENOENT') {
        await this.save();
        return this.snapshot();
      }

      throw error;
    }

    return this.snapshot();
  }

  snapshot() {
    return structuredClone(this.state);
  }

  getSession() {
    return this.state.session ? { ...this.state.session } : null;
  }

  async setSession(session) {
    this.state.session = session ? { ...session } : null;
    await this.save();
    return this.getSession();
  }

  async clearSession() {
    this.state.session = null;
    await this.save();
  }

  listQueue() {
    return this.state.queue
      .map((item) => ({ ...item }))
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt));
  }

  async upsertQueueItem(item) {
    const index = this.state.queue.findIndex((current) => current.id === item.id);
    if (index >= 0) {
      this.state.queue[index] = { ...this.state.queue[index], ...item };
    } else {
      this.state.queue.push({ ...item });
    }

    await this.save();
    return this.listQueue();
  }

  async replaceQueue(items) {
    this.state.queue = items.map((item) => ({ ...item }));
    await this.save();
    return this.listQueue();
  }

  async removeQueueItem(queueItemId) {
    this.state.queue = this.state.queue.filter((item) => item.id !== queueItemId);
    await this.save();
    return this.listQueue();
  }

  async save() {
    await mkdir(this.baseDir, { recursive: true });
    await writeFile(this.filePath, JSON.stringify(this.state, null, 2), 'utf8');
  }
}
