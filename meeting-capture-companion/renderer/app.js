const state = {
  session: null,
  projects: [],
  queue: [],
  captureSources: [],
  captureTargets: [],
  bootstrap: null,
  recorder: null,
  captureSessionId: null,
  desktopStream: null,
  micStream: null,
  audioContext: null,
  startedAt: null,
  selectedTargetName: null,
  refreshInterval: null,
};

const elements = {
  loginSection: document.getElementById('loginSection'),
  appSection: document.getElementById('appSection'),
  loginForm: document.getElementById('loginForm'),
  emailInput: document.getElementById('emailInput'),
  passwordInput: document.getElementById('passwordInput'),
  loginMessage: document.getElementById('loginMessage'),
  appMessage: document.getElementById('appMessage'),
  accountLabel: document.getElementById('accountLabel'),
  platformLabel: document.getElementById('platformLabel'),
  versionLabel: document.getElementById('versionLabel'),
  projectSelect: document.getElementById('projectSelect'),
  sourceSelect: document.getElementById('sourceSelect'),
  targetSelect: document.getElementById('targetSelect'),
  titleInput: document.getElementById('titleInput'),
  refreshTargetsButton: document.getElementById('refreshTargetsButton'),
  startButton: document.getElementById('startButton'),
  stopButton: document.getElementById('stopButton'),
  retryButton: document.getElementById('retryButton'),
  signOutButton: document.getElementById('signOutButton'),
  queueTableBody: document.getElementById('queueTableBody'),
  captureStatusLabel: document.getElementById('captureStatusLabel'),
  captureStatusText: document.getElementById('captureStatusText'),
};

document.addEventListener('DOMContentLoaded', async () => {
  bindEvents();
  await bootstrap();
});

function bindEvents() {
  elements.loginForm.addEventListener('submit', handleSignIn);
  elements.signOutButton.addEventListener('click', handleSignOut);
  elements.refreshTargetsButton.addEventListener('click', refreshCaptureTargets);
  elements.startButton.addEventListener('click', startCapture);
  elements.stopButton.addEventListener('click', stopCapture);
  elements.retryButton.addEventListener('click', retryUploads);
}

async function bootstrap() {
  const payload = await window.meetingCompanion.bootstrap();
  hydrateState(payload);
  await refreshCaptureTargets();
  render();
  startPolling();
}

function hydrateState(payload) {
  state.bootstrap = payload;
  state.session = payload.session;
  state.projects = payload.projects ?? [];
  state.queue = payload.queue ?? [];
  state.captureSources = payload.captureSources ?? [];
}

function startPolling() {
  if (state.refreshInterval) {
    clearInterval(state.refreshInterval);
  }

  state.refreshInterval = window.setInterval(async () => {
    const payload = await window.meetingCompanion.bootstrap();
    hydrateState(payload);
    render();
  }, 5000);
}

async function handleSignIn(event) {
  event.preventDefault();
  setMessage(elements.loginMessage, '', false);

  try {
    const payload = await window.meetingCompanion.signIn({
      email: elements.emailInput.value,
      password: elements.passwordInput.value,
    });
    state.session = payload.session;
    state.projects = payload.projects ?? [];
    state.queue = payload.queue ?? [];
    elements.passwordInput.value = '';
    await refreshCaptureTargets();
    render();
  } catch (error) {
    setMessage(elements.loginMessage, error instanceof Error ? error.message : String(error), true);
  }
}

async function handleSignOut() {
  await window.meetingCompanion.signOut();
  state.session = null;
  state.projects = [];
  state.queue = [];
  render();
}

async function retryUploads() {
  setMessage(elements.appMessage, '', false);
  try {
    state.queue = await window.meetingCompanion.retryUploads();
    renderQueue();
    setMessage(elements.appMessage, 'Fila reenfileirada.', false);
  } catch (error) {
    setMessage(elements.appMessage, error instanceof Error ? error.message : String(error), true);
  }
}

async function refreshCaptureTargets() {
  state.captureTargets = await window.meetingCompanion.listCaptureTargets().catch(() => []);
  renderCaptureTargets();
}

function render() {
  elements.accountLabel.textContent = state.session?.email ?? 'Sessão não iniciada';
  elements.platformLabel.textContent = state.bootstrap?.platform === 'macos' ? 'macOS 13+' : 'Windows 11';
  elements.versionLabel.textContent = `Companion ${state.bootstrap?.appVersion ?? '0.1.0'}`;

  const authenticated = Boolean(state.session);
  elements.loginSection.classList.toggle('hidden', authenticated);
  elements.appSection.classList.toggle('hidden', !authenticated);

  if (authenticated) {
    renderProjects();
    renderCaptureSources();
    renderQueue();
  }

  updateCaptureStateUi();
}

function renderProjects() {
  const currentValue = elements.projectSelect.value;
  elements.projectSelect.innerHTML = state.projects
    .map((project) => `<option value="${project.id}">${escapeHtml(project.name)}</option>`)
    .join('');

  if (currentValue && state.projects.some((project) => project.id === currentValue)) {
    elements.projectSelect.value = currentValue;
  }
}

function renderCaptureSources() {
  const currentValue = elements.sourceSelect.value;
  elements.sourceSelect.innerHTML = state.captureSources
    .map((item) => `<option value="${item.id}">${escapeHtml(item.label)}</option>`)
    .join('');

  if (currentValue && state.captureSources.some((item) => item.id === currentValue)) {
    elements.sourceSelect.value = currentValue;
  } else if (state.captureSources.length > 0) {
    elements.sourceSelect.value = state.captureSources[0].id;
  }

  if (!elements.titleInput.value) {
    elements.titleInput.value = defaultRecordingTitle();
  }
}

function renderCaptureTargets() {
  const currentValue = elements.targetSelect.value;
  elements.targetSelect.innerHTML = state.captureTargets
    .map((target) => `<option value="${target.id}">${escapeHtml(target.name)}</option>`)
    .join('');

  if (currentValue && state.captureTargets.some((target) => target.id === currentValue)) {
    elements.targetSelect.value = currentValue;
  }
}

function renderQueue() {
  if (state.queue.length === 0) {
    elements.queueTableBody.innerHTML = `
      <tr>
        <td colspan="4"><span class="muted">Nenhum upload pendente.</span></td>
      </tr>
    `;
    return;
  }

  elements.queueTableBody.innerHTML = state.queue
    .map((item) => `
      <tr>
        <td>
          <div class="table-primary">${escapeHtml(item.title)}</div>
          <div class="table-secondary">${escapeHtml(item.projectId)}</div>
        </td>
        <td>
          <div class="table-primary">${escapeHtml(formatSourceApp(item.captureMetadata?.sourceApp))}</div>
          <div class="table-secondary">${escapeHtml(formatPlatform(item.captureMetadata?.platform))}</div>
        </td>
        <td><span class="status ${escapeHtml(item.status)}">${escapeHtml(item.status)}</span>${item.error ? `<div class="table-secondary">${escapeHtml(item.error)}</div>` : ''}</td>
        <td><div class="table-secondary">${escapeHtml(item.filePath)}</div></td>
      </tr>
    `)
    .join('');
}

function updateCaptureStateUi() {
  const recording = Boolean(state.recorder);
  elements.startButton.disabled = recording || !state.session || state.projects.length === 0;
  elements.stopButton.disabled = !recording;
  elements.captureStatusLabel.textContent = recording ? 'Gravando' : 'Parado';
  elements.captureStatusText.textContent = recording
    ? 'Captura local em andamento. O upload será enfileirado ao parar.'
    : 'Nenhuma gravação em andamento.';
}

async function startCapture() {
  setMessage(elements.appMessage, '', false);

  if (!state.session) {
    setMessage(elements.appMessage, 'Faça login antes de iniciar a captura.', true);
    return;
  }

  if (!elements.projectSelect.value) {
    setMessage(elements.appMessage, 'Selecione um projeto.', true);
    return;
  }

  if (!elements.targetSelect.value) {
    setMessage(elements.appMessage, 'Selecione uma tela ou janela.', true);
    return;
  }

  const title = elements.titleInput.value.trim() || defaultRecordingTitle();
  const target = state.captureTargets.find((item) => item.id === elements.targetSelect.value);
  state.selectedTargetName = target?.name ?? null;

  try {
    await window.meetingCompanion.prepareCapture({ targetId: elements.targetSelect.value });
    const { sessionId } = await window.meetingCompanion.openCaptureSession();
    state.captureSessionId = sessionId;

    state.desktopStream = await navigator.mediaDevices.getDisplayMedia({
      audio: true,
      video: true,
    });

    if (state.desktopStream.getAudioTracks().length === 0) {
      throw new Error('O sistema não entregou áudio da reunião. Verifique a permissão de screen capture com áudio.');
    }

    state.micStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
    state.audioContext = new AudioContext();
    const destination = state.audioContext.createMediaStreamDestination();

    const systemSource = state.audioContext.createMediaStreamSource(
      new MediaStream(state.desktopStream.getAudioTracks()),
    );
    const micSource = state.audioContext.createMediaStreamSource(
      new MediaStream(state.micStream.getAudioTracks()),
    );

    systemSource.connect(destination);
    micSource.connect(destination);

    const mimeType = pickRecorderMimeType();
    state.recorder = new MediaRecorder(destination.stream, { mimeType });
    state.startedAt = Date.now();

    state.recorder.addEventListener('dataavailable', async (captureEvent) => {
      if (!captureEvent.data || captureEvent.data.size === 0 || !state.captureSessionId) {
        return;
      }

      const chunk = new Uint8Array(await captureEvent.data.arrayBuffer());
      await window.meetingCompanion.appendCaptureChunk({
        sessionId: state.captureSessionId,
        chunk,
      });
    });

    state.recorder.start(2000);
    elements.titleInput.value = title;
    updateCaptureStateUi();
  } catch (error) {
    if (state.captureSessionId) {
      await window.meetingCompanion.abortCaptureSession({ sessionId: state.captureSessionId }).catch(() => undefined);
    }
    await cleanupCaptureState();
    setMessage(elements.appMessage, error instanceof Error ? error.message : String(error), true);
  }
}

async function stopCapture() {
  if (!state.recorder || !state.captureSessionId) {
    return;
  }

  setMessage(elements.appMessage, '', false);

  const sessionId = state.captureSessionId;
  const title = elements.titleInput.value.trim() || defaultRecordingTitle();
  const projectId = elements.projectSelect.value;
  const sourceApp = elements.sourceSelect.value;
  const durationMs = state.startedAt ? Date.now() - state.startedAt : null;

  try {
    await stopMediaRecorder(state.recorder);
    const queueItem = await window.meetingCompanion.finishCaptureSession({
      sessionId,
      title,
      projectId,
      sourceApp,
      durationMs,
      windowTitle: state.selectedTargetName,
    });
    await cleanupCaptureState();
    const payload = await window.meetingCompanion.bootstrap();
    hydrateState(payload);
    render();
    setMessage(
      elements.appMessage,
      `Captura finalizada. Upload ${queueItem.status === 'uploaded' ? 'concluído' : 'enfileirado'}.`,
      false,
    );
  } catch (error) {
    await cleanupCaptureState();
    setMessage(elements.appMessage, error instanceof Error ? error.message : String(error), true);
  }
}

async function cleanupCaptureState() {
  if (state.desktopStream) {
    state.desktopStream.getTracks().forEach((track) => track.stop());
  }
  if (state.micStream) {
    state.micStream.getTracks().forEach((track) => track.stop());
  }
  if (state.audioContext) {
    await state.audioContext.close().catch(() => undefined);
  }

  state.recorder = null;
  state.desktopStream = null;
  state.micStream = null;
  state.audioContext = null;
  state.captureSessionId = null;
  state.startedAt = null;
  state.selectedTargetName = null;
  updateCaptureStateUi();
}

function setMessage(element, message, isError) {
  if (!message) {
    element.classList.add('hidden');
    element.textContent = '';
    element.classList.remove('error');
    return;
  }

  element.classList.remove('hidden');
  element.classList.toggle('error', isError);
  element.textContent = message;
}

function defaultRecordingTitle() {
  const source = state.captureSources.find((item) => item.id === elements.sourceSelect.value)?.label ?? 'Reunião';
  return `${source} ${new Date().toLocaleString('pt-BR')}`;
}

function pickRecorderMimeType() {
  const candidates = [
    'audio/webm;codecs=opus',
    'audio/webm',
    'video/webm;codecs=vp8,opus',
  ];

  for (const candidate of candidates) {
    if (MediaRecorder.isTypeSupported(candidate)) {
      return candidate;
    }
  }

  return '';
}

function stopMediaRecorder(recorder) {
  return new Promise((resolve) => {
    recorder.addEventListener('stop', () => resolve(), { once: true });
    recorder.stop();
  });
}

function formatSourceApp(value) {
  switch (value) {
    case 'teams':
      return 'Teams';
    case 'zoom':
      return 'Zoom';
    case 'meet':
      return 'Google Meet';
    case 'system_audio':
      return 'Áudio do sistema';
    default:
      return '—';
  }
}

function formatPlatform(value) {
  switch (value) {
    case 'windows':
      return 'Windows';
    case 'macos':
      return 'macOS';
    default:
      return '—';
  }
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
