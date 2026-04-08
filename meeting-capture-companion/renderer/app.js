const FILTER_ALL = '__all__';
const FILTER_NONE = '__none__';
const PROCESSING_STATUSES = new Set([
  'uploaded',
  'processing_transcript',
  'processing_summary',
  'indexing',
]);

const state = {
  session: null,
  projects: [],
  recordings: [],
  selectedRecording: null,
  captureSources: [],
  captureTargets: [],
  audioInputs: [],
  bootstrap: null,
  recorder: null,
  captureSessionId: null,
  desktopStream: null,
  micStream: null,
  audioContext: null,
  startedAt: null,
  selectedTargetName: null,
  refreshInterval: null,
  captureActionPending: null,
  audioUploadPending: false,
  recordingActionPendingId: null,
  searchQuery: '',
  recordingProjectFilterValue: FILTER_ALL,
  selectedAudioInputId: '',
  pendingAudioInputId: '',
  activeView: 'home',
};

const elements = {
  loginSection: document.getElementById('loginSection'),
  appShell: document.getElementById('appShell'),
  loginForm: document.getElementById('loginForm'),
  emailInput: document.getElementById('emailInput'),
  passwordInput: document.getElementById('passwordInput'),
  loginMessage: document.getElementById('loginMessage'),
  appMessage: document.getElementById('appMessage'),
  accountLabel: document.getElementById('accountLabel'),
  platformLabel: document.getElementById('platformLabel'),
  versionLabel: document.getElementById('versionLabel'),
  activeProjectLabel: document.getElementById('activeProjectLabel'),
  activeProjectMeta: document.getElementById('activeProjectMeta'),
  signOutButton: document.getElementById('signOutButton'),
  refreshRecordingsButton: document.getElementById('refreshRecordingsButton'),
  homeActiveProjectLabel: document.getElementById('homeActiveProjectLabel'),
  homeNotesCount: document.getElementById('homeNotesCount'),
  homeProcessingCount: document.getElementById('homeProcessingCount'),
  homeFailedCount: document.getElementById('homeFailedCount'),
  homeStartButton: document.getElementById('homeStartButton'),
  homeUploadButton: document.getElementById('homeUploadButton'),
  searchInput: document.getElementById('searchInput'),
  recordingProjectFilterSelect: document.getElementById('recordingProjectFilterSelect'),
  processingSectionCount: document.getElementById('processingSectionCount'),
  readySectionCount: document.getElementById('readySectionCount'),
  failedSectionCount: document.getElementById('failedSectionCount'),
  projectSelect: document.getElementById('projectSelect'),
  sourceSelect: document.getElementById('sourceSelect'),
  targetSelect: document.getElementById('targetSelect'),
  titleInput: document.getElementById('titleInput'),
  microphonePickerBackdrop: document.getElementById('microphonePickerBackdrop'),
  microphonePickerSelect: document.getElementById('microphonePickerSelect'),
  microphonePickerMessage: document.getElementById('microphonePickerMessage'),
  closeMicrophonePickerButton: document.getElementById('closeMicrophonePickerButton'),
  confirmMicrophonePickerButton: document.getElementById('confirmMicrophonePickerButton'),
  refreshMicrophonesButton: document.getElementById('refreshMicrophonesButton'),
  refreshTargetsButton: document.getElementById('refreshTargetsButton'),
  processingList: document.getElementById('processingList'),
  readyList: document.getElementById('readyList'),
  failedList: document.getElementById('failedList'),
  recordingDetailBackdrop: document.getElementById('recordingDetailBackdrop'),
  recordingDetailContent: document.getElementById('recordingDetailContent'),
  recordingDetailFeedback: document.getElementById('recordingDetailFeedback'),
  closeDetailButton: document.getElementById('closeDetailButton'),
  navButtons: Array.from(document.querySelectorAll('[data-view]')),
  viewPanels: Array.from(document.querySelectorAll('[data-view-panel]')),
};

document.addEventListener('DOMContentLoaded', async () => {
  bindEvents();
  await bootstrap();
});

function bindEvents() {
  elements.loginForm.addEventListener('submit', handleSignIn);
  elements.signOutButton.addEventListener('click', handleSignOut);
  elements.refreshRecordingsButton.addEventListener('click', refreshRecordings);
  elements.refreshMicrophonesButton.addEventListener('click', refreshAudioInputs);
  elements.refreshTargetsButton.addEventListener('click', refreshCaptureTargets);
  elements.homeStartButton.addEventListener('click', handleCaptureAction);
  elements.homeUploadButton.addEventListener('click', handleAudioUploadAction);
  elements.closeMicrophonePickerButton.addEventListener('click', closeMicrophonePicker);
  elements.confirmMicrophonePickerButton.addEventListener('click', confirmMicrophoneAndStartCapture);
  elements.closeDetailButton.addEventListener('click', closeRecordingDetail);
  elements.microphonePickerBackdrop.addEventListener('click', (event) => {
    if (event.target === elements.microphonePickerBackdrop) {
      closeMicrophonePicker();
    }
  });
  elements.recordingDetailBackdrop.addEventListener('click', (event) => {
    if (event.target === elements.recordingDetailBackdrop) {
      closeRecordingDetail();
    }
  });

  elements.searchInput.addEventListener('input', (event) => {
    state.searchQuery = event.target.value ?? '';
    renderLibrary();
  });

  elements.recordingProjectFilterSelect.addEventListener('change', (event) => {
    state.recordingProjectFilterValue = event.target.value || FILTER_ALL;
    renderLibrary();
  });

  elements.projectSelect.addEventListener('change', () => {
    syncActiveProjectCard();
  });

  elements.microphonePickerSelect.addEventListener('change', (event) => {
    state.pendingAudioInputId = event.target.value || '';
  });

  elements.navButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const nextView = button.getAttribute('data-view');
      if (nextView) {
        state.activeView = nextView;
        renderActiveView();
      }
    });
  });

  if (navigator.mediaDevices?.addEventListener) {
    navigator.mediaDevices.addEventListener('devicechange', () => {
      void refreshAudioInputs();
    });
  }
}

async function bootstrap() {
  const payload = await window.meetingCompanion.bootstrap();
  hydrateState(payload);
  await refreshAudioInputs();
  await refreshCaptureTargets();
  render();
  startPolling();
}

function hydrateState(payload) {
  state.bootstrap = payload;
  state.session = payload.session ?? null;
  state.projects = payload.projects ?? [];
  state.recordings = payload.recordings ?? [];
  state.captureSources = payload.captureSources ?? [];

  if (
    state.recordingProjectFilterValue !== FILTER_ALL &&
    state.recordingProjectFilterValue !== FILTER_NONE &&
    !state.projects.some((project) => project.id === state.recordingProjectFilterValue)
  ) {
    state.recordingProjectFilterValue = FILTER_ALL;
  }

  syncSelectedRecordingFromCollection();
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
    hydrateState(payload);
    elements.passwordInput.value = '';
    await refreshAudioInputs();
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
  state.recordings = [];
  state.selectedRecording = null;
  state.searchQuery = '';
  state.recordingProjectFilterValue = FILTER_ALL;
  state.activeView = 'home';
  state.audioUploadPending = false;
  state.pendingAudioInputId = '';
  elements.searchInput.value = '';
  closeMicrophonePicker();
  closeRecordingDetail();
  render();
}

async function refreshRecordings() {
  if (!state.session) {
    state.recordings = [];
    renderHomeDeck();
    renderLibrary();
    return;
  }

  try {
    state.recordings = await window.meetingCompanion.listRecordings();
    syncSelectedRecordingFromCollection();
    renderHomeDeck();
    renderLibrary();
  } catch (error) {
    setMessage(elements.appMessage, error instanceof Error ? error.message : String(error), true);
  }
}

async function refreshCaptureTargets() {
  try {
    state.captureTargets = await window.meetingCompanion.listCaptureTargets();
  } catch {
    state.captureTargets = [];
  }

  renderCaptureTargets();
}

async function refreshAudioInputs() {
  if (!navigator.mediaDevices?.enumerateDevices) {
    state.audioInputs = [];
    renderMicrophonePickerOptions();
    return;
  }

  try {
    const devices = await navigator.mediaDevices.enumerateDevices();
    state.audioInputs = devices.filter((device) => device.kind === 'audioinput');
  } catch {
    state.audioInputs = [];
  }

  renderMicrophonePickerOptions();
}

function render() {
  const authenticated = Boolean(state.session);
  elements.loginSection.classList.toggle('hidden', authenticated);
  elements.appShell.classList.toggle('hidden', !authenticated);

  if (!authenticated) {
    setMessage(elements.appMessage, '', false);
    closeMicrophonePicker();
    return;
  }

  renderShellContext();
  renderProjectOptions();
  renderHomeDeck();
  renderCaptureSources();
  renderCaptureTargets();
  renderLibrary();
  renderActiveView();
  updateCaptureStateUi();

  if (state.selectedRecording) {
    renderRecordingDetail();
  }
}

function renderActiveView() {
  elements.navButtons.forEach((button) => {
    button.classList.toggle('is-active', button.getAttribute('data-view') === state.activeView);
  });

  elements.viewPanels.forEach((panel) => {
    panel.classList.toggle('hidden', panel.getAttribute('data-view-panel') !== state.activeView);
  });
}

function renderShellContext() {
  elements.accountLabel.textContent = state.session?.email ?? 'Sessao nao iniciada';
  elements.platformLabel.textContent = state.bootstrap?.platform === 'macos' ? 'macOS 13+' : 'Windows 11';
  elements.versionLabel.textContent = `Companion ${state.bootstrap?.appVersion ?? '0.1.0'}`;
  syncActiveProjectCard();
}

function renderHomeDeck() {
  const processingCount = state.recordings.filter((recording) => PROCESSING_STATUSES.has(recording.status)).length;
  const failedCount = state.recordings.filter((recording) => recording.status === 'failed').length;

  elements.homeNotesCount.textContent = String(state.recordings.length);
  elements.homeProcessingCount.textContent = String(processingCount);
  elements.homeFailedCount.textContent = String(failedCount);
  elements.homeActiveProjectLabel.textContent = elements.projectSelect.value
    ? formatProjectLabel(elements.projectSelect.value)
    : 'Sem projeto';
}

function syncActiveProjectCard() {
  const projectId = elements.projectSelect.value || null;
  const activeProject = projectId ? state.projects.find((project) => project.id === projectId) : null;

  if (!activeProject) {
    elements.activeProjectLabel.textContent = 'Sem projeto';
    elements.activeProjectMeta.textContent = 'As novas capturas podem ser enviadas com ou sem projeto.';
    elements.homeActiveProjectLabel.textContent = 'Sem projeto';
    return;
  }

  elements.activeProjectLabel.textContent = activeProject.name;
  elements.activeProjectMeta.textContent = 'As novas capturas serao vinculadas a este projeto.';
  elements.homeActiveProjectLabel.textContent = activeProject.name;
}

function renderProjectOptions() {
  const captureValue = elements.projectSelect.value;
  elements.projectSelect.innerHTML = [
    '<option value="">Sem projeto</option>',
    ...state.projects.map((project) => `<option value="${escapeHtml(project.id)}">${escapeHtml(project.name)}</option>`),
  ].join('');

  if (!captureValue || state.projects.some((project) => project.id === captureValue)) {
    elements.projectSelect.value = captureValue;
  }

  elements.recordingProjectFilterSelect.innerHTML = [
    `<option value="${FILTER_ALL}">Todos</option>`,
    `<option value="${FILTER_NONE}">Sem projeto</option>`,
    ...state.projects.map((project) => `<option value="${escapeHtml(project.id)}">${escapeHtml(project.name)}</option>`),
  ].join('');
  elements.recordingProjectFilterSelect.value = state.recordingProjectFilterValue;

  syncActiveProjectCard();
}

function renderCaptureSources() {
  const currentValue = elements.sourceSelect.value;
  elements.sourceSelect.innerHTML = state.captureSources
    .map((item) => `<option value="${escapeHtml(item.id)}">${escapeHtml(formatSourceApp(item.id))}</option>`)
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

function renderMicrophonePickerOptions() {
  const currentValue = state.pendingAudioInputId || state.selectedAudioInputId;
  elements.microphonePickerSelect.innerHTML = [
    '<option value="">Padrao do sistema</option>',
    ...state.audioInputs.map((device, index) => (
      `<option value="${escapeHtml(device.deviceId)}">${escapeHtml(formatAudioInputLabel(device, index))}</option>`
    )),
  ].join('');

  if (currentValue && state.audioInputs.some((device) => device.deviceId === currentValue)) {
    state.pendingAudioInputId = currentValue;
    elements.microphonePickerSelect.value = currentValue;
  } else {
    state.pendingAudioInputId = '';
    elements.microphonePickerSelect.value = '';
  }
}

function renderCaptureTargets() {
  const currentValue = elements.targetSelect.value;

  if (state.captureTargets.length === 0) {
    elements.targetSelect.innerHTML = '<option value="">Nenhuma tela ou janela disponivel</option>';
    elements.targetSelect.value = '';
    return;
  }

  elements.targetSelect.innerHTML = state.captureTargets
    .map((target) => `<option value="${escapeHtml(target.id)}">${escapeHtml(target.name)}</option>`)
    .join('');

  if (currentValue && state.captureTargets.some((target) => target.id === currentValue)) {
    elements.targetSelect.value = currentValue;
  } else if (state.captureTargets.length > 0) {
    elements.targetSelect.value = state.captureTargets[0].id;
  }
}

function renderLibrary() {
  const filtered = getFilteredRecordings();
  const processing = filtered.filter((recording) => PROCESSING_STATUSES.has(recording.status));
  const ready = filtered.filter((recording) => recording.status === 'ready');
  const failed = filtered.filter((recording) => recording.status === 'failed');

  elements.processingSectionCount.textContent = String(processing.length);
  elements.readySectionCount.textContent = String(ready.length);
  elements.failedSectionCount.textContent = String(failed.length);

  renderRecordingSection(elements.processingList, processing, 'Nenhum registro em andamento.');
  renderRecordingSection(elements.readyList, ready, 'Nenhuma nota pronta para este filtro.');
  renderRecordingSection(elements.failedList, failed, 'Nenhuma falha aberta para este filtro.');
}

function renderRecordingSection(container, recordings, emptyLabel) {
  if (recordings.length === 0) {
    container.innerHTML = `
      <article class="empty-state">
        <strong>Sem itens</strong>
        <p>${escapeHtml(emptyLabel)}</p>
      </article>
    `;
    return;
  }

  container.innerHTML = recordings.map(renderRecordingCard).join('');
  container.querySelectorAll('[data-recording-id]').forEach((card) => {
    card.addEventListener('click', () => {
      const recordingId = card.getAttribute('data-recording-id');
      if (recordingId) {
        void openRecordingDetail(recordingId);
      }
    });
  });
}

function renderRecordingCard(recording) {
  return `
    <article class="recording-card" data-recording-id="${escapeHtml(recording.id)}">
      <div class="recording-card__top">
        <div>
          <h3 class="recording-card__title">${escapeHtml(recording.noteArtifact?.title ?? recording.title)}</h3>
          <p class="recording-card__summary">${escapeHtml(recording.summary?.overview ?? summarizeStatus(recording.status, recording.lastError))}</p>
        </div>
        ${renderStatusPill(recording.status)}
      </div>
      <div class="chip-row">
        ${renderMetaChip('Horario', formatDateTime(recording.createdAt))}
        ${renderMetaChip('Projeto', formatProjectLabel(recording.projectId))}
        ${renderMetaChip('Origem', formatRecordingSource(recording))}
        ${renderMetaChip('Autor', authorLabelFor(recording.createdByUserId))}
      </div>
    </article>
  `;
}

function updateCaptureStateUi() {
  const recording = Boolean(state.recorder);
  const busy = state.captureActionPending === 'starting' || state.captureActionPending === 'stopping';
  const canStart = !busy && !state.audioUploadPending && (recording || Boolean(state.session));

  elements.homeStartButton.disabled = !canStart;
  elements.homeStartButton.innerHTML = renderCommandButtonContent(
    recording ? 'stop' : 'mic',
    state.captureActionPending === 'starting'
      ? 'Iniciando captacao...'
      : state.captureActionPending === 'stopping'
        ? 'Parando captacao...'
        : recording
          ? 'Parar captacao'
          : 'Iniciar captacao',
  );

  elements.homeUploadButton.disabled = !state.session || recording || state.audioUploadPending || busy;
  elements.homeUploadButton.innerHTML = renderCommandButtonContent(
    'upload',
    state.audioUploadPending ? 'Enviando audio...' : 'Enviar audio',
  );
}

function renderCommandButtonContent(icon, label) {
  return `
    <span class="command-button__glyph" aria-hidden="true">
      ${commandGlyph(icon)}
    </span>
    <span>${escapeHtml(label)}</span>
  `;
}

function commandGlyph(icon) {
  switch (icon) {
    case 'stop':
      return `
        <svg viewBox="0 0 24 24" focusable="false" aria-hidden="true">
          <path d="M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2Zm-3 7a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1V9Z" />
        </svg>
      `;
    case 'upload':
      return `
        <svg viewBox="0 0 24 24" focusable="false" aria-hidden="true">
          <path d="M8 3a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V9.83a2 2 0 0 0-.59-1.41l-3.83-3.83A2 2 0 0 0 12.17 4H8Zm4 1.5V8a1 1 0 0 0 1 1h3.5V19a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h4Zm0 8.59V11a1 1 0 1 1 2 0v2.09h1.09a1 1 0 1 1 0 2H14V17a1 1 0 1 1-2 0v-1.91H10.91a1 1 0 1 1 0-2H12Z" />
        </svg>
      `;
    case 'mic':
    default:
      return `
        <svg viewBox="0 0 24 24" focusable="false" aria-hidden="true">
          <path d="M12 15a3 3 0 0 0 3-3V7a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3Zm5-3a1 1 0 1 1 2 0 7 7 0 0 1-6 6.92V22h2a1 1 0 1 1 0 2H9a1 1 0 1 1 0-2h2v-3.08A7 7 0 0 1 5 12a1 1 0 1 1 2 0 5 5 0 1 0 10 0Z" />
        </svg>
      `;
  }
}

async function openMicrophonePicker() {
  await refreshAudioInputs();
  state.pendingAudioInputId = state.selectedAudioInputId;
  renderMicrophonePickerOptions();
  setMessage(elements.microphonePickerMessage, '', false);
  elements.microphonePickerBackdrop.classList.remove('hidden');
}

function closeMicrophonePicker() {
  elements.microphonePickerBackdrop.classList.add('hidden');
  setMessage(elements.microphonePickerMessage, '', false);
}

async function confirmMicrophoneAndStartCapture() {
  state.selectedAudioInputId = state.pendingAudioInputId;
  closeMicrophonePicker();
  await startCapture();
}

async function handleCaptureAction() {
  if (state.recorder) {
    await stopCapture();
    return;
  }

  await openMicrophonePicker();
}

async function handleAudioUploadAction() {
  setMessage(elements.appMessage, '', false);

  if (!state.session) {
    setMessage(elements.appMessage, 'Faca login antes de enviar um arquivo de audio.', true);
    return;
  }

  state.audioUploadPending = true;
  updateCaptureStateUi();

  try {
    const queueItem = await window.meetingCompanion.pickAudioUpload({
      projectId: elements.projectSelect.value || null,
    });

    if (!queueItem) {
      return;
    }

    await refreshRecordings();
    setMessage(
      elements.appMessage,
      `Audio ${queueItem.status === 'uploaded' ? 'enviado' : 'enfileirado'} com sucesso.`,
      false,
    );
  } catch (error) {
    setMessage(elements.appMessage, error instanceof Error ? error.message : String(error), true);
  } finally {
    state.audioUploadPending = false;
    updateCaptureStateUi();
  }
}

async function startCapture() {
  setMessage(elements.appMessage, '', false);

  if (!state.session) {
    setMessage(elements.appMessage, 'Faca login antes de iniciar a captura.', true);
    return;
  }

  if (!elements.targetSelect.value) {
    setMessage(elements.appMessage, 'Selecione uma tela ou janela.', true);
    return;
  }

  const title = elements.titleInput.value.trim() || defaultRecordingTitle();
  const target = state.captureTargets.find((item) => item.id === elements.targetSelect.value);
  state.selectedTargetName = target?.name ?? null;
  state.captureActionPending = 'starting';
  updateCaptureStateUi();

  try {
    await window.meetingCompanion.prepareCapture({ targetId: elements.targetSelect.value });
    const { sessionId } = await window.meetingCompanion.openCaptureSession();
    state.captureSessionId = sessionId;

    state.desktopStream = await navigator.mediaDevices.getDisplayMedia({
      audio: true,
      video: true,
    });

    if (state.desktopStream.getAudioTracks().length === 0) {
      throw new Error('O sistema nao entregou audio da reuniao. Verifique a permissao de screen capture com audio.');
    }

    const microphoneConstraints = state.selectedAudioInputId
      ? { deviceId: { exact: state.selectedAudioInputId } }
      : true;
    state.micStream = await navigator.mediaDevices.getUserMedia({
      audio: microphoneConstraints,
      video: false,
    });
    state.audioContext = new AudioContext();
    const destination = state.audioContext.createMediaStreamDestination();

    const systemSource = state.audioContext.createMediaStreamSource(new MediaStream(state.desktopStream.getAudioTracks()));
    const micSource = state.audioContext.createMediaStreamSource(new MediaStream(state.micStream.getAudioTracks()));

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
    state.captureActionPending = null;
    updateCaptureStateUi();
  } catch (error) {
    if (state.captureSessionId) {
      await window.meetingCompanion.abortCaptureSession({ sessionId: state.captureSessionId }).catch(() => undefined);
    }
    state.captureActionPending = null;
    await cleanupCaptureState();
    setMessage(elements.appMessage, error instanceof Error ? error.message : String(error), true);
  }
}

async function stopCapture() {
  if (!state.recorder || !state.captureSessionId) {
    return;
  }

  setMessage(elements.appMessage, '', false);
  state.captureActionPending = 'stopping';
  updateCaptureStateUi();

  const sessionId = state.captureSessionId;
  const title = elements.titleInput.value.trim() || defaultRecordingTitle();
  const projectId = elements.projectSelect.value || null;
  const sourceApp = elements.sourceSelect.value;
  const durationMs = state.startedAt ? Date.now() - state.startedAt : null;

  try {
    const queueItem = await finalizeCaptureSession({
      sessionId,
      title,
      projectId,
      sourceApp,
      durationMs,
      windowTitle: state.selectedTargetName,
    });

    await refreshRecordings();
    setMessage(
      elements.appMessage,
      `Captura finalizada. Upload ${queueItem.status === 'uploaded' ? 'concluido' : 'enfileirado'}.`,
      false,
    );
  } catch (error) {
    await cleanupCaptureState();
    setMessage(elements.appMessage, error instanceof Error ? error.message : String(error), true);
  }
}

async function finalizeCaptureSession(payload) {
  await stopMediaRecorder(state.recorder);
  const queueItem = await window.meetingCompanion.finishCaptureSession(payload);
  await cleanupCaptureState();
  return queueItem;
}

async function openRecordingDetail(recordingId) {
  elements.recordingDetailBackdrop.classList.remove('hidden');
  setMessage(elements.recordingDetailFeedback, '', false);
  elements.recordingDetailContent.innerHTML = `
    <article class="empty-state">
      <strong>Carregando detalhe</strong>
      <p>Buscando resumo, metadados e transcript completos.</p>
    </article>
  `;

  try {
    const recording = await window.meetingCompanion.getRecording({ recordingId });
    state.selectedRecording = recording;
    renderRecordingDetail();
  } catch (error) {
    state.selectedRecording = null;
    elements.recordingDetailContent.innerHTML = `
      <article class="empty-state">
        <strong>Falha ao carregar detalhe</strong>
        <p>${escapeHtml(error instanceof Error ? error.message : String(error))}</p>
      </article>
    `;
  }
}

function closeRecordingDetail() {
  elements.recordingDetailBackdrop.classList.add('hidden');
}

function renderRecordingDetail() {
  const recording = state.selectedRecording;
  if (!recording) {
    elements.recordingDetailContent.innerHTML = `
      <article class="empty-state">
        <strong>Gravacao indisponivel</strong>
        <p>Selecione outro item para continuar.</p>
      </article>
    `;
    return;
  }

  const processBusy = state.recordingActionPendingId === recording.id;

  elements.recordingDetailContent.innerHTML = `
    <section class="detail-hero panel panel--highlight">
      <div class="chip-row">
        ${renderStatusPill(recording.status)}
        ${renderDetailChip('Horario', formatDateTime(recording.createdAt))}
        ${renderDetailChip('Projeto', formatProjectLabel(recording.projectId))}
        ${renderDetailChip('Origem', formatRecordingSource(recording))}
        ${renderDetailChip('Autor', authorLabelFor(recording.createdByUserId))}
      </div>
      <div class="stack-sm">
        <h3>${escapeHtml(recording.noteArtifact?.title ?? recording.title)}</h3>
        <p>${escapeHtml(recording.summary?.overview ?? summarizeStatus(recording.status, recording.lastError))}</p>
      </div>
      ${renderChapterGrid(recording.summary?.chapters ?? [])}
    </section>

    <div class="detail-grid">
      <section class="detail-section">
        <div class="section-copy">
          <h2>Insights estruturados</h2>
          <p>Destaques, itens acionaveis e tags operacionais derivados da gravacao.</p>
        </div>
        ${renderDetailListCard('Highlights', recording.noteArtifact?.highlights ?? [], 'Nenhum highlight estruturado ainda.')}
        ${renderDetailListCard('Action items', recording.noteArtifact?.actionItems ?? [], 'Nenhum item acionavel estruturado ainda.')}
        ${renderTags(recording.noteArtifact?.tags ?? [])}
      </section>

      <section class="detail-section">
        <div class="section-copy">
          <h2>Acoes do operador</h2>
          <p>Reprocessamento, exportacao e vinculo de projeto em uma superficie unica.</p>
        </div>
        <div class="detail-actions">
          <button id="processRecordingButton" class="button button--primary button--full" type="button" ${processBusy ? 'disabled' : ''}>
            ${processBusy ? 'Processando...' : 'Processar novamente'}
          </button>
          <button id="exportMarkdownButton" class="button button--secondary button--full" type="button">Exportar markdown</button>
          <div class="detail-project-row">
            <label class="field">
              <span>Projeto vinculado</span>
              <select id="recordingProjectSelect">
                <option value="">Sem projeto</option>
                ${state.projects
                  .map((project) => `<option value="${escapeHtml(project.id)}" ${project.id === (recording.projectId ?? '') ? 'selected' : ''}>${escapeHtml(project.name)}</option>`)
                  .join('')}
              </select>
            </label>
            <button id="saveRecordingProjectButton" class="button button--secondary button--full" type="button">Salvar projeto</button>
          </div>
          ${recording.lastError ? `
            <article class="error-block">
              <strong>Ultimo erro do pipeline</strong>
              <p>${escapeHtml(recording.lastError)}</p>
            </article>
          ` : ''}
        </div>
      </section>
    </div>

    <section class="detail-section">
      <div class="section-copy">
        <h2>Transcript contextual</h2>
        <p>Leitura cronologica com speaker e timestamp para revisao rapida.</p>
      </div>
      <div class="transcript-stack">
        ${renderTranscript(recording.transcriptSegments ?? [])}
      </div>
    </section>
  `;

  elements.recordingDetailContent.querySelector('#processRecordingButton')?.addEventListener('click', () => {
    void handleProcessRecording(recording.id);
  });
  elements.recordingDetailContent.querySelector('#exportMarkdownButton')?.addEventListener('click', () => {
    void handleExportMarkdown(recording.id, recording.title);
  });
  elements.recordingDetailContent.querySelector('#saveRecordingProjectButton')?.addEventListener('click', () => {
    const value = elements.recordingDetailContent.querySelector('#recordingProjectSelect')?.value ?? '';
    void handleUpdateRecordingProject(recording.id, value || null);
  });
}

async function handleProcessRecording(recordingId) {
  state.recordingActionPendingId = recordingId;
  renderRecordingDetail();
  setMessage(elements.recordingDetailFeedback, '', false);

  try {
    const updated = await window.meetingCompanion.processRecording({
      recordingId,
      input: {},
    });
    replaceRecording(updated);
    state.selectedRecording = updated;
    renderLibrary();
    renderRecordingDetail();
    setMessage(elements.recordingDetailFeedback, 'Gravacao reenfileirada para processamento.', false);
  } catch (error) {
    setMessage(elements.recordingDetailFeedback, error instanceof Error ? error.message : String(error), true);
  } finally {
    state.recordingActionPendingId = null;
    if (state.selectedRecording?.id === recordingId) {
      renderRecordingDetail();
    }
  }
}

async function handleExportMarkdown(recordingId, fallbackTitle) {
  setMessage(elements.recordingDetailFeedback, '', false);

  try {
    const artifact = await window.meetingCompanion.exportRecordingMarkdown({ recordingId });
    const blob = new Blob([artifact.body], {
      type: artifact.contentType ?? 'text/markdown',
    });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = artifact.fileName ?? `${fallbackTitle}.md`;
    anchor.click();
    URL.revokeObjectURL(url);
    setMessage(elements.recordingDetailFeedback, 'Markdown exportado com sucesso.', false);
  } catch (error) {
    setMessage(elements.recordingDetailFeedback, error instanceof Error ? error.message : String(error), true);
  }
}

async function handleUpdateRecordingProject(recordingId, projectId) {
  setMessage(elements.recordingDetailFeedback, '', false);

  try {
    const updated = await window.meetingCompanion.updateRecording({
      recordingId,
      input: { projectId },
    });
    replaceRecording(updated);
    state.selectedRecording = updated;
    renderLibrary();
    renderRecordingDetail();
    setMessage(
      elements.recordingDetailFeedback,
      projectId ? 'Projeto da gravacao atualizado.' : 'Vinculo com projeto removido.',
      false,
    );
  } catch (error) {
    setMessage(elements.recordingDetailFeedback, error instanceof Error ? error.message : String(error), true);
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
  state.captureActionPending = null;
  updateCaptureStateUi();
}

function getFilteredRecordings() {
  const query = state.searchQuery.trim().toLowerCase();

  return state.recordings.filter((recording) => {
    if (state.recordingProjectFilterValue === FILTER_NONE && recording.projectId) {
      return false;
    }

    if (
      state.recordingProjectFilterValue !== FILTER_ALL &&
      state.recordingProjectFilterValue !== FILTER_NONE &&
      recording.projectId !== state.recordingProjectFilterValue
    ) {
      return false;
    }

    if (!query) {
      return true;
    }

    const haystack = [
      recording.title,
      recording.summary?.overview ?? '',
      (recording.noteArtifact?.tags ?? []).join(' '),
      (recording.transcriptSegments ?? []).map((segment) => segment.text).join(' '),
    ].join(' ').toLowerCase();

    return haystack.includes(query);
  });
}

function replaceRecording(updated) {
  if (!updated) {
    return;
  }

  const exists = state.recordings.some((item) => item.id === updated.id);
  state.recordings = exists
    ? state.recordings.map((item) => (item.id === updated.id ? { ...item, ...updated } : item))
    : [updated, ...state.recordings];
  renderHomeDeck();
}

function syncSelectedRecordingFromCollection() {
  if (!state.selectedRecording) {
    return;
  }

  const next = state.recordings.find((item) => item.id === state.selectedRecording.id);
  if (!next) {
    return;
  }

  state.selectedRecording = {
    ...state.selectedRecording,
    ...next,
  };
}

function renderStatusPill(status) {
  return `<div class="status-pill ${statusToneClass(status)}">${escapeHtml(formatRecordingStatus(status))}</div>`;
}

function renderMetaChip(label, value) {
  return `
    <div class="meta-chip">
      <span class="meta-chip__icon">${escapeHtml(metaIconFor(label))}</span>
      <strong>${escapeHtml(value)}</strong>
    </div>
  `;
}

function renderDetailChip(label, value) {
  return `
    <div class="detail-chip">
      <span class="detail-chip__icon">${escapeHtml(metaIconFor(label))}</span>
      <strong>${escapeHtml(value)}</strong>
    </div>
  `;
}

function renderChapterGrid(chapters) {
  if (!Array.isArray(chapters) || chapters.length === 0) {
    return '';
  }

  return `
    <div class="chapter-grid">
      ${chapters
        .map((chapter) => `
          <article class="chapter-card">
            <strong>${escapeHtml(chapter.heading)}</strong>
            <p>${escapeHtml(chapter.body)}</p>
          </article>
        `)
        .join('')}
    </div>
  `;
}

function renderDetailListCard(title, items, emptyLabel) {
  if (!items.length) {
    return `
      <article class="detail-list-card">
        <strong>${escapeHtml(title)}</strong>
        <p>${escapeHtml(emptyLabel)}</p>
      </article>
    `;
  }

  return `
    <article class="detail-list-card">
      <strong>${escapeHtml(title)}</strong>
      <ul>
        ${items.map((item) => `<li>${escapeHtml(item)}</li>`).join('')}
      </ul>
    </article>
  `;
}

function renderTags(tags) {
  if (!Array.isArray(tags) || tags.length === 0) {
    return '';
  }

  return `
    <div class="chip-row">
      ${tags.map((tag) => `<div class="status-pill status-pill--neutral">${escapeHtml(tag)}</div>`).join('')}
    </div>
  `;
}

function renderTranscript(segments) {
  if (!Array.isArray(segments) || segments.length === 0) {
    return `
      <article class="detail-list-card">
        <strong>Transcript indisponivel</strong>
        <p>A transcricao ainda nao esta disponivel para esta gravacao.</p>
      </article>
    `;
  }

  return segments
    .map((segment) => `
      <article class="transcript-card">
        <div class="transcript-card__meta">
          <h4 class="transcript-card__speaker">${escapeHtml(segment.speakerLabel)}</h4>
          <div class="status-pill status-pill--info">${escapeHtml(formatTimestamp(segment.startMs))}</div>
        </div>
        <p>${escapeHtml(segment.text)}</p>
      </article>
    `)
    .join('');
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
  const source = state.captureSources.some((item) => item.id === elements.sourceSelect.value)
    ? formatSourceApp(elements.sourceSelect.value)
    : 'Reuniao';
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

function metaIconFor(label) {
  switch (label) {
    case 'Horario':
      return 'TM';
    case 'Projeto':
      return 'PR';
    case 'Origem':
      return 'OR';
    case 'Autor':
      return 'AU';
    default:
      return '--';
  }
}

function authorLabelFor(createdByUserId) {
  if (state.session?.userId === createdByUserId) {
    return friendlySessionName();
  }

  return createdByUserId || 'Usuario do projeto';
}

function friendlySessionName() {
  const email = state.session?.email;
  if (!email) {
    return 'Voce';
  }

  const localPart = email.split('@').shift()?.trim() ?? '';
  return localPart || 'Voce';
}

function summarizeStatus(status, lastError) {
  switch (status) {
    case 'uploaded':
      return 'Arquivo enviado. O transcript sera processado em segundo plano.';
    case 'processing_transcript':
      return 'Transcript em andamento no backend.';
    case 'processing_summary':
      return 'Resumo estruturado em processamento.';
    case 'indexing':
      return 'Indexacao em andamento para busca e leitura.';
    case 'failed':
      return lastError || 'O pipeline reportou uma falha para este item.';
    case 'ready':
      return 'Nota pronta para leitura.';
    default:
      return 'Status operacional indisponivel.';
  }
}

function statusToneClass(status) {
  switch (status) {
    case 'uploaded':
    case 'processing_transcript':
    case 'processing_summary':
      return 'status-pill--accent';
    case 'indexing':
      return 'status-pill--info';
    case 'ready':
      return 'status-pill--success';
    case 'failed':
      return 'status-pill--warning';
    default:
      return 'status-pill--neutral';
  }
}

function formatRecordingSource(recording) {
  switch (recording?.sourceType) {
    case 'desktop_meeting':
      return formatSourceApp(recording?.captureMetadata?.sourceApp) || 'Reuniao online';
    case 'microphone':
      return 'Microfone';
    case 'upload':
      return 'Upload';
    default:
      return 'Indefinido';
  }
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
      return 'Audio do sistema';
    default:
      return 'Indefinido';
  }
}

function formatAudioInputLabel(device, index) {
  if (device?.label) {
    return device.label;
  }

  return `Microfone ${index + 1}`;
}

function formatRecordingStatus(status) {
  switch (status) {
    case 'uploaded':
      return 'Enviado';
    case 'processing_transcript':
      return 'Transcrevendo';
    case 'processing_summary':
      return 'Resumindo';
    case 'indexing':
      return 'Indexando';
    case 'ready':
      return 'Pronto';
    case 'failed':
      return 'Falhou';
    default:
      return status ?? 'Indefinido';
  }
}

function formatProjectLabel(projectId) {
  if (!projectId) {
    return 'Sem projeto';
  }

  return state.projects.find((project) => project.id === projectId)?.name ?? projectId;
}

function formatDateTime(value) {
  if (!value) {
    return 'Sem data';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(date);
}

function formatTimestamp(milliseconds) {
  const totalSeconds = Math.floor((Number(milliseconds) || 0) / 1000);
  const minutes = String(Math.floor(totalSeconds / 60)).padStart(2, '0');
  const seconds = String(totalSeconds % 60).padStart(2, '0');
  return `${minutes}:${seconds}`;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
