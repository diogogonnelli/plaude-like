import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('meetingCompanion', {
  bootstrap: () => ipcRenderer.invoke('app:bootstrap'),
  signIn: (payload) => ipcRenderer.invoke('auth:signIn', payload),
  signOut: () => ipcRenderer.invoke('auth:signOut'),
  listProjects: () => ipcRenderer.invoke('projects:list'),
  listRecordings: () => ipcRenderer.invoke('recordings:list'),
  getRecording: (payload) => ipcRenderer.invoke('recordings:get', payload),
  processRecording: (payload) => ipcRenderer.invoke('recordings:process', payload),
  exportRecordingMarkdown: (payload) => ipcRenderer.invoke('recordings:export-markdown', payload),
  updateRecording: (payload) => ipcRenderer.invoke('recordings:update', payload),
  pickAudioUpload: (payload) => ipcRenderer.invoke('audio:pick-upload', payload),
  retryUploads: () => ipcRenderer.invoke('queue:retry'),
  listCaptureSources: () => ipcRenderer.invoke('capture:list-sources'),
  listCaptureTargets: () => ipcRenderer.invoke('capture:list-targets'),
  prepareCapture: (payload) => ipcRenderer.invoke('capture:prepare', payload),
  openCaptureSession: () => ipcRenderer.invoke('capture:open-session'),
  appendCaptureChunk: (payload) => ipcRenderer.invoke('capture:append-chunk', payload),
  finishCaptureSession: (payload) => ipcRenderer.invoke('capture:finish-session', payload),
  abortCaptureSession: (payload) => ipcRenderer.invoke('capture:abort-session', payload),
});
