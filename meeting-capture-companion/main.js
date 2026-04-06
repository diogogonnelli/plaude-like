import { app, BrowserWindow, desktopCapturer, ipcMain, session } from 'electron';
import { join } from 'node:path';
import { mkdir } from 'node:fs/promises';

import { companionConfig } from './src/config.js';
import { CompanionStore } from './src/store/companion-store.js';
import { SupabaseSessionService } from './src/services/supabase-session.js';
import { UploadQueueService } from './src/services/upload-queue.js';
import { CaptureSessionManager } from './src/services/capture-session-manager.js';
import {
  exportRecordingMarkdown,
  getRecording,
  listProjects,
  listRecordings,
  updateRecording,
} from './src/services/backend-client.js';
import { captureSources } from './src/shared/capture-sources.js';

const runtime = {
  selectedCaptureTargetId: null,
  store: null,
  sessionService: null,
  uploadQueue: null,
  captureManager: null,
};

async function buildBootstrapPayload() {
  const sessionState = runtime.sessionService.getSession();
  let projects = [];
  let recordings = [];

  if (sessionState?.accessToken) {
    projects = await listProjects(companionConfig.backendBaseUrl, sessionState.accessToken).catch(() => []);
    recordings = await listRecordings(companionConfig.backendBaseUrl, sessionState.accessToken).catch(() => []);
  }

  return {
    appVersion: companionConfig.appVersion,
    platform: process.platform === 'darwin' ? 'macos' : 'windows',
    session: sessionState,
    queue: runtime.uploadQueue.listQueue(),
    captureSources,
    projects,
    recordings,
  };
}

async function createWindow() {
  const window = new BrowserWindow({
    width: 1160,
    height: 840,
    minWidth: 980,
    minHeight: 720,
    webPreferences: {
      preload: join(app.getAppPath(), 'preload.js'),
      contextIsolation: true,
      sandbox: false,
      nodeIntegration: false,
    },
    title: 'Meeting Capture Companion',
  });

  await window.loadFile(join(app.getAppPath(), 'renderer', 'index.html'));
}

function registerIpcHandlers() {
  ipcMain.handle('app:bootstrap', async () => buildBootstrapPayload());

  ipcMain.handle('auth:signIn', async (_event, payload) => {
    const sessionState = await runtime.sessionService.signIn(payload.email, payload.password);
    await runtime.uploadQueue.processPendingUploads();
    return {
      session: sessionState,
      queue: runtime.uploadQueue.listQueue(),
      projects: await listProjects(companionConfig.backendBaseUrl, sessionState.accessToken).catch(() => []),
      recordings: await listRecordings(companionConfig.backendBaseUrl, sessionState.accessToken).catch(() => []),
    };
  });

  ipcMain.handle('auth:signOut', async () => {
    await runtime.sessionService.signOut();
    return buildBootstrapPayload();
  });

  ipcMain.handle('projects:list', async () => {
    const accessToken = runtime.sessionService.getAccessToken();
    if (!accessToken) {
      return [];
    }

    return listProjects(companionConfig.backendBaseUrl, accessToken);
  });

  ipcMain.handle('recordings:list', async () => {
    const accessToken = runtime.sessionService.getAccessToken();
    if (!accessToken) {
      return [];
    }

    return listRecordings(companionConfig.backendBaseUrl, accessToken);
  });

  ipcMain.handle('recordings:get', async (_event, payload) => {
    const accessToken = runtime.sessionService.getAccessToken();
    if (!accessToken) {
      return null;
    }

    return getRecording(companionConfig.backendBaseUrl, accessToken, payload.recordingId);
  });

  ipcMain.handle('recordings:export-markdown', async (_event, payload) => {
    const accessToken = runtime.sessionService.getAccessToken();
    if (!accessToken) {
      return null;
    }

    return exportRecordingMarkdown(companionConfig.backendBaseUrl, accessToken, payload.recordingId);
  });

  ipcMain.handle('recordings:update', async (_event, payload) => {
    const accessToken = runtime.sessionService.getAccessToken();
    if (!accessToken) {
      return null;
    }

    return updateRecording(companionConfig.backendBaseUrl, accessToken, payload.recordingId, payload.input);
  });

  ipcMain.handle('queue:retry', async () => {
    await runtime.uploadQueue.retryFailedUploads();
    return runtime.uploadQueue.listQueue();
  });

  ipcMain.handle('capture:list-sources', async () => captureSources);

  ipcMain.handle('capture:list-targets', async () => {
    const sources = await desktopCapturer.getSources({
      types: ['screen', 'window'],
      fetchWindowIcons: true,
      thumbnailSize: { width: 320, height: 200 },
    });

    return sources.map((source) => ({
      id: source.id,
      name: source.name,
      type: source.id.startsWith('window:') ? 'window' : 'screen',
      displayId: source.display_id || null,
    }));
  });

  ipcMain.handle('capture:prepare', async (_event, payload) => {
    runtime.selectedCaptureTargetId = payload.targetId ?? null;
    return { ok: true };
  });

  ipcMain.handle('capture:open-session', async () => runtime.captureManager.openSession());

  ipcMain.handle('capture:append-chunk', async (_event, payload) => {
    await runtime.captureManager.appendChunk(payload.sessionId, payload.chunk);
    return { ok: true };
  });

  ipcMain.handle('capture:finish-session', async (_event, payload) => {
    const queueItem = await runtime.captureManager.finalizeSession(payload.sessionId, payload);
    await runtime.uploadQueue.processPendingUploads();
    return queueItem;
  });

  ipcMain.handle('capture:abort-session', async (_event, payload) => {
    const aborted = await runtime.captureManager.abortSession(payload.sessionId);
    return { aborted };
  });
}

app.whenReady().then(async () => {
  const userDataDir = app.getPath('userData');
  const capturesDir = join(userDataDir, 'captures');
  await mkdir(capturesDir, { recursive: true });

  runtime.store = new CompanionStore(userDataDir);
  await runtime.store.load();

  runtime.sessionService = new SupabaseSessionService(companionConfig, runtime.store);
  await runtime.sessionService.bootstrap();

  runtime.uploadQueue = new UploadQueueService({
    backendBaseUrl: companionConfig.backendBaseUrl,
    store: runtime.store,
    getAccessToken: () => runtime.sessionService.getAccessToken(),
  });

  runtime.captureManager = new CaptureSessionManager({
    baseDir: capturesDir,
    uploadQueue: runtime.uploadQueue,
    appVersion: companionConfig.appVersion,
    platform: process.platform === 'darwin' ? 'macos' : 'windows',
  });

  session.defaultSession.setDisplayMediaRequestHandler(async (_request, callback) => {
    const sources = await desktopCapturer.getSources({
      types: ['screen', 'window'],
      fetchWindowIcons: true,
      thumbnailSize: { width: 320, height: 200 },
    });

    const selected = sources.find((source) => source.id === runtime.selectedCaptureTargetId) ?? sources[0];

    callback({
      video: selected,
      audio: 'loopback',
    });
  });

  registerIpcHandlers();
  await runtime.uploadQueue.processPendingUploads();
  await createWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
