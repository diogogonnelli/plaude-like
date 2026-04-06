const state = {
  session: null,
  projects: [],
  recordings: [],
  selectedRecording: null,
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
  refreshRecordingsButton: document.getElementById('refreshRecordingsButton'),
  signOutButton: document.getElementById('signOutButton'),
  queueTableBody: document.getElementById('queueTableBody'),
  recordingsTableBody: document.getElementById('recordingsTableBody'),
  recordingDetailBackdrop: document.getElementById('recordingDetailBackdrop'),
  recordingDetailContent: document.getElementById('recordingDetailContent'),
  recordingDetailFeedback: document.getElementById('recordingDetailFeedback'),
  closeDetailButton: document.getElementById('closeDetailButton'),
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
  elements.refreshRecordingsButton.addEventListener('click', refreshRecordings);
  elements.startButton.addEventListener('click', startCapture);
  elements.stopButton.addEventListener('click', stopCapture);
  elements.retryButton.addEventListener('click', retryUploads);
  elements.closeDetailButton.addEventListener('click', closeRecordingDetail);
  elements.recordingDetailBackdrop.addEventListener('click', (event) => {
    if (event.target === elements.recordingDetailBackdrop) {
      closeRecordingDetail();
    }
  });
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
  state.recordings = payload.recordings ?? [];
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
    state.recordings = payload.recordings ?? [];
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
  state.recordings = [];
  state.selectedRecording = null;
  state.queue = [];
  closeRecordingDetail();
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

async function refreshRecordings() {
  if (!state.session) {
    state.recordings = [];
    renderRecordings();
    return;
  }

  state.recordings = await window.meetingCompanion.listRecordings().catch(() => []);
  renderRecordings();
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
    renderRecordings();
  }

  updateCaptureStateUi();
}

function renderProjects() {
  const currentValue = elements.projectSelect.value;
  elements.projectSelect.innerHTML = [
    '<option value="">Sem projeto</option>',
    ...state.projects.map((project) => `<option value="${project.id}">${escapeHtml(project.name)}</option>`),
  ].join('');

  if (currentValue === '' || state.projects.some((project) => project.id === currentValue)) {
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
          <div class="table-secondary">${escapeHtml(formatProjectLabel(item.projectId))}</div>
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

function renderRecordings() {
  if (state.recordings.length === 0) {
    elements.recordingsTableBody.innerHTML = `
      <tr>
        <td colspan="4"><span class="muted">Nenhuma gravação encontrada para este usuário.</span></td>
      </tr>
    `;
    return;
  }

  elements.recordingsTableBody.innerHTML = state.recordings
    .map((item) => `
      <tr data-recording-id="${escapeHtml(item.id)}" class="clickable-row">
        <td>
          <div class="table-primary">${escapeHtml(item.title)}</div>
          <div class="table-secondary">${escapeHtml(formatProjectLabel(item.projectId))}</div>
        </td>
        <td>
          <div class="table-primary">${escapeHtml(formatRecordingSource(item))}</div>
          <div class="table-secondary">${escapeHtml(formatPlatform(item.captureMetadata?.platform))}</div>
        </td>
        <td><span class="status ${escapeHtml(item.status)}">${escapeHtml(formatRecordingStatus(item.status))}</span></td>
        <td><div class="table-secondary">${escapeHtml(formatDateTime(item.createdAt))}</div></td>
      </tr>
    `)
    .join('');

  for (const row of elements.recordingsTableBody.querySelectorAll('[data-recording-id]')) {
    row.addEventListener('click', () => {
      const recordingId = row.getAttribute('data-recording-id');
      if (recordingId) {
        void openRecordingDetail(recordingId);
      }
    });
  }
}

function updateCaptureStateUi() {
  const recording = Boolean(state.recorder);
  elements.startButton.disabled = recording || !state.session;
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
  const projectId = elements.projectSelect.value || null;
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

async function openRecordingDetail(recordingId) {
  elements.recordingDetailBackdrop.classList.remove('hidden');
  setMessage(elements.recordingDetailFeedback, '', false);
  elements.recordingDetailContent.innerHTML = `
    <div class="empty-card">
      <strong>Carregando detalhe</strong>
      <span>Buscando grafo completo da gravação.</span>
    </div>
  `;

  try {
    const recording = await window.meetingCompanion.getRecording({ recordingId });
    state.selectedRecording = recording;
    renderRecordingDetail();
  } catch (error) {
    state.selectedRecording = null;
    elements.recordingDetailContent.innerHTML = `
      <div class="empty-card">
        <strong>Falha ao carregar detalhe</strong>
        <span>${escapeHtml(error instanceof Error ? error.message : String(error))}</span>
      </div>
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
      <div class="empty-card">
        <strong>Gravação indisponível</strong>
        <span>Selecione outra linha para continuar.</span>
      </div>
    `;
    return;
  }

  const transcriptHtml = recording.transcriptSegments?.length
    ? recording.transcriptSegments
        .map((segment) => `
          <article class="transcript-card">
            <div class="transcript-meta">
              <strong>${escapeHtml(segment.speakerLabel)}</strong>
              <span>${escapeHtml(formatTimestamp(segment.startMs))}</span>
            </div>
            <p>${escapeHtml(segment.text)}</p>
          </article>
        `)
        .join('')
    : '<span class="table-secondary">Transcript indisponível.</span>';

  const highlightsHtml = recording.noteArtifact?.highlights?.length
    ? `<ul class="detail-list">${recording.noteArtifact.highlights
        .map((item) => `<li>${escapeHtml(item)}</li>`)
        .join('')}</ul>`
    : '<span class="table-secondary">Sem highlights estruturados.</span>';

  const actionItemsHtml = recording.noteArtifact?.actionItems?.length
    ? `<ul class="detail-list">${recording.noteArtifact.actionItems
        .map((item) => `<li>${escapeHtml(item)}</li>`)
        .join('')}</ul>`
    : '<span class="table-secondary">Sem action items estruturados.</span>';

  const chaptersHtml = recording.summary?.chapters?.length
    ? `<div class="chapter-grid">${recording.summary.chapters
        .map((chapter) => `
          <article class="chapter-card">
            <strong>${escapeHtml(chapter.heading)}</strong>
            <p>${escapeHtml(chapter.body)}</p>
          </article>
        `)
        .join('')}</div>`
    : '';

  const projectName = formatProjectLabel(recording.projectId);
  const authorName = state.session?.userId === recording.createdByUserId
    ? (state.session?.email ?? 'Você')
    : (recording.createdByUserId ?? '—');

  elements.recordingDetailContent.innerHTML = `
    <div class="detail-stack">
      <div class="detail-metadata">
        ${renderDetailItem('Recording ID', recording.id)}
        ${renderDetailItem('Projeto', projectName)}
        ${renderDetailItem('Autor', authorName)}
        ${renderDetailItem('Origem', formatRecordingSource(recording))}
        ${renderDetailItem('Plataforma', formatPlatform(recording.captureMetadata?.platform))}
        ${renderDetailItem('Status', formatRecordingStatus(recording.status))}
        ${renderDetailItem('Job ID', recording.transcriptionJobId ?? '—')}
        ${renderDetailItem('Criada em', formatDateTime(recording.createdAt))}
        ${renderDetailItem('Atualizada em', formatDateTime(recording.updatedAt))}
      </div>

      <section class="detail-block">
        <div class="actions">
          <button id="exportMarkdownButton" class="button primary" type="button">Exportar markdown</button>
          <select id="recordingProjectSelect">
            <option value="">Sem projeto</option>
            ${state.projects.map((project) => `<option value="${escapeHtml(project.id)}" ${project.id === (recording.projectId ?? '') ? 'selected' : ''}>${escapeHtml(project.name)}</option>`).join('')}
          </select>
          <button id="saveRecordingProjectButton" class="button ghost" type="button">Salvar projeto</button>
          <button id="closeDetailSecondaryButton" class="button ghost" type="button">Fechar</button>
        </div>
      </section>

      <section class="detail-block">
        <h4>Resumo executivo</h4>
        <p>${escapeHtml(recording.summary?.overview ?? 'Sem resumo disponível.')}</p>
        ${chaptersHtml}
      </section>

      <section class="detail-block">
        <h4>Highlights</h4>
        ${highlightsHtml}
      </section>

      <section class="detail-block">
        <h4>Action items</h4>
        ${actionItemsHtml}
      </section>

      <section class="detail-block">
        <h4>Transcript</h4>
        <div class="transcript-stack">${transcriptHtml}</div>
      </section>

      ${recording.lastError ? `
        <section class="detail-block error-block">
          <h4>lastError</h4>
          <p>${escapeHtml(recording.lastError)}</p>
        </section>
      ` : ''}
    </div>
  `;

  elements.recordingDetailContent.querySelector('#exportMarkdownButton')?.addEventListener('click', () => {
    void handleExportMarkdown(recording.id, recording.title);
  });
  elements.recordingDetailContent.querySelector('#saveRecordingProjectButton')?.addEventListener('click', () => {
    const value = elements.recordingDetailContent.querySelector('#recordingProjectSelect')?.value ?? '';
    void handleUpdateRecordingProject(recording.id, value || null);
  });
  elements.recordingDetailContent.querySelector('#closeDetailSecondaryButton')?.addEventListener('click', closeRecordingDetail);
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
    state.selectedRecording = updated;
    state.recordings = state.recordings.map((item) => item.id === updated.id ? updated : item);
    renderRecordings();
    renderRecordingDetail();
    setMessage(
      elements.recordingDetailFeedback,
      projectId ? 'Projeto da gravação atualizado.' : 'Vínculo com projeto removido.',
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

function formatRecordingSource(recording) {
  switch (recording?.sourceType) {
    case 'desktop_meeting':
      return formatSourceApp(recording?.captureMetadata?.sourceApp) || 'Reunião online';
    case 'microphone':
      return 'Microfone';
    case 'upload':
      return 'Upload';
    default:
      return '—';
  }
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
      return status ?? '—';
  }
}

function formatDateTime(value) {
  if (!value) {
    return '—';
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

function renderDetailItem(label, value) {
  return `
    <div class="detail-item">
      <span>${escapeHtml(label)}</span>
      <strong>${escapeHtml(value)}</strong>
    </div>
  `;
}

function formatProjectLabel(projectId) {
  if (!projectId) {
    return 'Sem projeto';
  }

  return state.projects.find((project) => project.id === projectId)?.name ?? projectId;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
