import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/app_config.dart';
import '../data/demo_content.dart';
import '../data/models.dart';
import '../data/plaude_api.dart';

class PlaudeController extends ChangeNotifier {
  PlaudeController({
    required this.api,
    this.supabaseClient,
    bool? authRequiredOverride,
  }) : _authRequired = authRequiredOverride ?? AppConfig.hasSupabase;

  final PlaudeApi api;
  final SupabaseClient? supabaseClient;
  final bool _authRequired;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<AuthState>? _authSubscription;

  List<Project> _projects = const [];
  List<RecordingNote> _recordings = [];
  bool _isLoading = true;
  bool _backendAvailable = false;
  bool _isRecording = false;
  bool _authReady = false;
  bool _authBusy = false;
  String _searchQuery = '';
  String? _recordingPath;
  String? _currentlyPlayingPath;
  String? _notice;
  String? _activeProjectId;
  Session? _session;
  final Set<String> _processingIds = <String>{};
  final Set<String> _chatBusyIds = <String>{};

  bool get requiresAuth => _authRequired;
  bool get authReady => _authReady;
  bool get authBusy => _authBusy;
  bool get isAuthenticated => !_authRequired || _session != null;
  String? get sessionEmail => _session?.user.email;
  String? get accessToken => _session?.accessToken;
  List<Project> get projects => _projects;
  List<RecordingNote> get allRecordings => List.unmodifiable(_recordings);
  bool get isLoading => _isLoading;
  bool get backendAvailable => _backendAvailable;
  bool get isRecording => _isRecording;
  String? get notice => _notice;
  String get searchQuery => _searchQuery;
  String? get activeProjectId => _activeProjectId;
  Project? get activeProject {
    if (_activeProjectId == null) return null;
    for (final project in _projects) {
      if (project.id == _activeProjectId) return project;
    }
    return null;
  }

  List<RecordingNote> get recordings => _filteredRecordings();

  List<RecordingNote> get processingRecordings => recordings
      .where((recording) => recording.status != ProcessingStatus.ready && recording.status != ProcessingStatus.failed)
      .toList();

  List<RecordingNote> get readyRecordings =>
      recordings.where((recording) => recording.status == ProcessingStatus.ready).toList();

  List<RecordingNote> get failedRecordings =>
      recordings.where((recording) => recording.status == ProcessingStatus.failed).toList();

  Future<void> bootstrap() async {
    if (_authRequired && supabaseClient != null) {
      _session = supabaseClient!.auth.currentSession;
      _authReady = true;
      _authSubscription ??= supabaseClient!.auth.onAuthStateChange.listen((event) {
        _session = event.session;
        if (_session == null) {
          _clearSignedOutState();
        } else {
          unawaited(refresh());
        }
        notifyListeners();
      });

      if (_session != null) {
        await refresh();
      } else {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    _authReady = true;
    await refresh();
  }

  Future<void> signIn(String email, String password) async {
    if (supabaseClient == null) {
      throw StateError('Supabase Auth não está configurado.');
    }

    _authBusy = true;
    _notice = null;
    notifyListeners();

    try {
      final response = await supabaseClient!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _session = response.session;
      _notice = 'Sessão iniciada.';
      await refresh();
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _authBusy = true;
    notifyListeners();
    try {
      await supabaseClient?.auth.signOut();
      _session = null;
      _clearSignedOutState();
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_authRequired && _session == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _backendAvailable = await api.isHealthy();
      if (_backendAvailable) {
        _projects = await api.listProjects();
        _activeProjectId ??= _projects.isNotEmpty ? _projects.first.id : null;
        _recordings = await api.listRecordings(
          projectId: _activeProjectId,
          query: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        );
        _notice = 'Conectado ao backend.';
      } else {
        _loadDemoData();
        _notice = 'Executando em modo de demonstração. Inicie o backend para usar a integração HTTP real.';
      }
    } catch (_) {
      _backendAvailable = false;
      if (_authRequired) {
        _projects = const [];
        _recordings = const [];
        _notice = 'Não foi possível carregar os dados do backend autenticado.';
      } else {
        _loadDemoData();
        _notice = 'Backend indisponível. Exibindo dados locais de demonstração.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearSignedOutState() {
    _projects = const [];
    _recordings = const [];
    _backendAvailable = false;
    _activeProjectId = null;
    _notice = null;
    _isLoading = false;
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> changeActiveProject(String? projectId) async {
    _activeProjectId = projectId;
    notifyListeners();
    if (_backendAvailable) {
      await refresh();
    }
  }

  RecordingNote? findById(String id) {
    for (final recording in _recordings) {
      if (recording.id == id) {
        return recording;
      }
    }
    return null;
  }

  bool isProcessing(String recordingId) => _processingIds.contains(recordingId);
  bool isChatBusy(String recordingId) => _chatBusyIds.contains(recordingId);
  bool isPlayable(String? path) => !kIsWeb && path != null && !path.startsWith('demo/');
  bool isCurrentlyPlaying(String? path) => path != null && path == _currentlyPlayingPath && _player.playing;

  Future<void> startRecording() async {
    if (kIsWeb) {
      _notice = 'A captura por microfone esta disponivel nas versoes mobile e desktop. Na web, use o envio de audio.';
      notifyListeners();
      return;
    }

    if (_activeProjectId == null) {
      _notice = 'Selecione um projeto antes de gravar.';
      notifyListeners();
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _notice = 'A permissao de microfone foi negada.';
      notifyListeners();
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/plaude_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _recordingPath = path;
    _isRecording = true;
    _notice = 'Gravacao em andamento.';
    notifyListeners();
  }

  Future<void> stopRecordingAndProcess() async {
    if (!_isRecording) {
      return;
    }

    final path = await _recorder.stop();
    _isRecording = false;
    _recordingPath = path ?? _recordingPath;
    notifyListeners();

    if (_recordingPath == null) {
      _notice = 'A gravacao terminou sem gerar um arquivo de saida.';
      notifyListeners();
      return;
    }

    final projectId = _activeProjectId;
    if (projectId == null) {
      _notice = 'Selecione um projeto antes de enviar a gravacao.';
      notifyListeners();
      return;
    }

    if (_backendAvailable) {
      final filePath = _recordingPath!;
      final file = File(filePath);
      final platformFile = PlatformFile(
        name: file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'gravacao.m4a',
        path: file.path,
        size: await file.length(),
      );
      await _uploadAndWatch(
        platformFile: platformFile,
        title: 'Nota de voz ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        projectId: projectId,
        sourceType: 'microphone',
      );
      return;
    }

    await _createAndProcessRecording(
      title: 'Nota de voz ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      projectId: projectId,
      sourceType: 'microphone',
      audioPath: _recordingPath,
      durationMs: null,
    );
  }

  Future<void> pickAudioFile() async {
    final file = (await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'mp4'],
      withData: kIsWeb,
    ))
        ?.files
        .singleOrNull;

    if (file == null) {
      return;
    }

    final projectId = _activeProjectId;
    if (projectId == null) {
      _notice = 'Selecione um projeto antes de enviar um audio.';
      notifyListeners();
      return;
    }

    if (_backendAvailable) {
      await _uploadAndWatch(
        platformFile: file,
        title: file.name,
        projectId: projectId,
        sourceType: 'upload',
      );
      return;
    }

    await _createAndProcessRecording(
      title: file.name,
      projectId: projectId,
      sourceType: 'upload',
      audioPath: file.path ?? file.name,
      durationMs: null,
    );
  }

  Future<void> _createAndProcessRecording({
    required String title,
    required String projectId,
    required String sourceType,
    String? audioPath,
    int? durationMs,
  }) async {
    RecordingNote created;
    try {
      created = await _createRecording(
        title: title,
        projectId: projectId,
        sourceType: sourceType,
        audioPath: audioPath,
        durationMs: durationMs,
      );
    } catch (_) {
      return;
    }

    await processRecording(
      created.id,
      transcriptText: _mockTranscriptFor(title),
    );
  }

  Future<void> _uploadAndWatch({
    required PlatformFile platformFile,
    required String title,
    required String projectId,
    required String sourceType,
  }) async {
    try {
      final created = await api.uploadRecording(
        file: platformFile,
        title: title,
        projectId: projectId,
        sourceType: sourceType,
      );
      _recordings = [created, ..._recordings.where((recording) => recording.id != created.id)];
      _notice = 'Arquivo enviado. A transcricao sera processada em segundo plano.';
      notifyListeners();
      unawaited(_watchRecordingUntilSettled(created.id));
    } catch (error) {
      _notice = 'Falha ao enviar o audio: $error';
      notifyListeners();
    }
  }

  Future<void> _watchRecordingUntilSettled(String recordingId) async {
    const maxAttempts = 120;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final refreshed = await api.getRecording(recordingId);
        _replaceRecording(refreshed);
        if (refreshed.status == ProcessingStatus.ready) {
          _notice = 'Transcricao concluida e nota pronta.';
          notifyListeners();
          return;
        }
        if (refreshed.status == ProcessingStatus.failed) {
          _notice = refreshed.lastError ?? 'A transcricao falhou.';
          notifyListeners();
          return;
        }
      } catch (_) {
        _notice = 'Nao foi possivel acompanhar o status da transcricao.';
        notifyListeners();
        return;
      }
    }

    _notice = 'O processamento ainda esta em andamento. Atualize a biblioteca em alguns instantes.';
    notifyListeners();
  }

  Future<RecordingNote> _createRecording({
    required String title,
    required String projectId,
    required String sourceType,
    String? audioPath,
    int? durationMs,
  }) async {
    if (_backendAvailable) {
      try {
        final created = await api.createRecording(
          title: title,
          projectId: projectId,
          sourceType: sourceType,
          audioPath: audioPath,
          durationMs: durationMs,
        );
        _recordings = [created, ..._recordings];
        _notice = 'Gravacao registrada. Processamento iniciado.';
        notifyListeners();
        return created;
      } catch (_) {
        _notice = 'Falha ao criar a gravacao no backend.';
        notifyListeners();
        throw StateError('Falha ao criar a gravacao no backend.');
      }
    }

    final created = RecordingNote(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      projectId: projectId,
      createdByUserId: 'demo-user',
      title: title,
      sourceType: sourceType,
      status: ProcessingStatus.uploaded,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      durationMs: durationMs,
      audioPath: audioPath,
      transcriptSegments: const [],
      chatSession: const ChatSession(
        id: 'local-session',
        recordingId: 'local-session',
        messages: [],
      ),
    );

    _recordings = [created, ..._recordings];
    _notice = 'Criado localmente em modo de demonstracao.';
    notifyListeners();
    return created;
  }

  Future<void> processRecording(String recordingId, {String? transcriptText}) async {
    final current = findById(recordingId);
    if (current == null) {
      return;
    }

    _processingIds.add(recordingId);
    _replaceRecording(
      current.copyWith(
        status: ProcessingStatus.processingTranscript,
        updatedAt: DateTime.now(),
      ),
    );

    if (_backendAvailable) {
      try {
        final processed = await api.processRecording(
          recordingId: recordingId,
          transcriptText: transcriptText,
        );
        _replaceRecording(processed);
        _notice = 'Processamento concluido.';
        return;
      } catch (_) {
        _notice = 'Falha ao processar a gravacao no backend.';
        return;
      } finally {
        _processingIds.remove(recordingId);
        notifyListeners();
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    _replaceRecording(current.copyWith(
      status: ProcessingStatus.processingSummary,
      updatedAt: DateTime.now(),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final processed = _buildLocalProcessedRecording(current, transcriptText ?? _mockTranscriptFor(current.title));
    _replaceRecording(processed);
    _processingIds.remove(recordingId);
    _notice = 'Processado localmente em modo de demonstracao.';
    notifyListeners();
  }

  Future<void> sendChat(String recordingId, String question) async {
    final trimmed = question.trim();
    final current = findById(recordingId);
    if (current == null || trimmed.isEmpty) {
      return;
    }

    final baseSession = current.chatSession ??
        ChatSession(
          id: 'session-$recordingId',
          recordingId: recordingId,
          messages: const [],
        );

    final userMessage = ChatMessage(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    _chatBusyIds.add(recordingId);
    _replaceRecording(
      current.copyWith(
        chatSession: ChatSession(
          id: baseSession.id,
          recordingId: baseSession.recordingId,
          messages: [...baseSession.messages, userMessage],
        ),
      ),
    );

    try {
      final assistantMessage = _backendAvailable
          ? await api.askQuestion(recordingId: recordingId, question: trimmed)
          : _buildLocalChatAnswer(current, trimmed);

      final refreshed = findById(recordingId);
      if (refreshed == null) {
        return;
      }

      final session = refreshed.chatSession ??
          ChatSession(
            id: baseSession.id,
            recordingId: recordingId,
            messages: [userMessage],
          );

      _replaceRecording(
        refreshed.copyWith(
          chatSession: ChatSession(
            id: session.id,
            recordingId: session.recordingId,
            messages: [...session.messages, assistantMessage],
          ),
        ),
      );
    } catch (_) {
      _notice = 'A solicitacao de chat falhou.';
    } finally {
      _chatBusyIds.remove(recordingId);
      notifyListeners();
    }
  }

  Future<ExportArtifact> exportRecording(String recordingId, String format) async {
    final current = findById(recordingId);
    if (current == null) {
      throw StateError('Gravacao nao encontrada');
    }

    if (_backendAvailable) {
      try {
        return await api.exportRecording(recordingId: recordingId, format: format);
      } catch (_) {
        _notice = 'Falha ao exportar a nota pelo backend.';
        notifyListeners();
      }
    }

    final highlights = current.noteArtifact?.highlights ?? const <String>[];
    final actionItems = current.noteArtifact?.actionItems ?? const <String>[];
    final transcript = current.transcriptSegments
        .map((segment) => '${segment.speakerLabel}: ${segment.text}')
        .join('\n');

    final body = format == 'md'
        ? [
            '# ${current.noteArtifact?.title ?? current.title}',
            '',
            '## Resumo',
            current.summary?.overview ?? 'Sem resumo',
            '',
            '## Destaques',
            ...highlights.map((item) => '- $item'),
            '',
            '## Itens de acao',
            ...actionItems.map((item) => '- $item'),
            '',
            '## Transcricao',
            '```text',
            transcript,
            '```',
          ].join('\n')
        : [
            current.noteArtifact?.title ?? current.title,
            '',
            current.summary?.overview ?? 'Sem resumo',
            '',
            transcript,
          ].join('\n');

    return ExportArtifact(
      format: format,
      fileName: '${current.id}.$format',
      contentType: format == 'md' ? 'text/markdown' : 'text/plain',
      body: body,
    );
  }

  Future<void> togglePlayback(String path) async {
    if (!isPlayable(path)) {
      _notice = 'A reproducao esta disponivel apenas para gravacoes locais em mobile ou desktop.';
      notifyListeners();
      return;
    }

    if (_currentlyPlayingPath == path && _player.playing) {
      await _player.pause();
      _currentlyPlayingPath = null;
      notifyListeners();
      return;
    }

    await _player.setFilePath(path);
    await _player.play();
    _currentlyPlayingPath = path;
    notifyListeners();
  }

  RecordingNote _buildLocalProcessedRecording(RecordingNote base, String transcriptText) {
    final lines = transcriptText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final segments = <TranscriptSegment>[
      for (var index = 0; index < lines.length; index++)
        TranscriptSegment(
          id: '${base.id}-$index',
          recordingId: base.id,
          speakerLabel: lines[index].startsWith('Speaker') ? lines[index].split(':').first : 'Speaker ${(index % 2) + 1}',
          startMs: index * 28000,
          endMs: (index * 28000) + 22000,
          text: lines[index].contains(':') ? lines[index].split(':').skip(1).join(':').trim() : lines[index],
        ),
    ];

    final highlights = segments.take(2).map((segment) => segment.text).toList();
    final actionItems = segments
        .where((segment) => segment.text.toLowerCase().contains('precis') || segment.text.toLowerCase().contains('vamos'))
        .map((segment) => segment.text)
        .take(3)
        .toList();

    return base.copyWith(
      title: base.title,
      status: ProcessingStatus.ready,
      updatedAt: DateTime.now(),
      transcriptSegments: segments,
      summary: RecordingSummary(
        overview: 'Nota processada localmente com resumo estruturado, transcricao pesquisavel e contexto pronto para chat.',
        chapters: [
          SummaryChapter(
            heading: 'Contexto',
            body: highlights.isNotEmpty ? highlights.first : 'Nenhum contexto principal detectado.',
          ),
          SummaryChapter(
            heading: 'Execucao',
            body: actionItems.isNotEmpty ? actionItems.first : 'Nenhum item de acao explicito foi detectado.',
          ),
        ],
      ),
      noteArtifact: NoteArtifact(
        title: base.title,
        tags: <String>[
          base.sourceType,
          if (base.title.toLowerCase().contains('lanc')) 'lancamento' else 'nota',
          'ia-pronta',
        ],
        highlights: highlights,
        actionItems: actionItems,
      ),
      chatSession: ChatSession(
        id: 'session-${base.id}',
        recordingId: base.id,
        messages: base.chatSession?.messages ?? const [],
      ),
    );
  }

  ChatMessage _buildLocalChatAnswer(RecordingNote recording, String question) {
    final citations = recording.transcriptSegments.take(2).map((segment) {
      return ChatCitation(
        segmentId: segment.id,
        startMs: segment.startMs,
        endMs: segment.endMs,
        quote: segment.text,
      );
    }).toList();

    final actionItems = recording.noteArtifact?.actionItems.join('; ') ?? 'Nenhum item de acao foi extraido ainda.';
    final lowerQuestion = question.toLowerCase();
    final answerText = lowerQuestion.contains('acao') ||
            lowerQuestion.contains('next') ||
            lowerQuestion.contains('proximo')
        ? 'Os proximos passos detectados sao: $actionItems'
        : 'A nota indica: ${recording.summary?.overview ?? 'Ainda nao ha resumo disponivel.'}';

    return ChatMessage(
      id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
      role: 'assistant',
      content: answerText,
      createdAt: DateTime.now(),
      citations: citations,
    );
  }

  String _mockTranscriptFor(String title) {
    return [
      'Speaker 1: Esta nota chamada $title precisa consolidar o contexto da conversa.',
      'Speaker 2: Vamos registrar responsaveis, riscos e proximos passos para o produto.',
      'Speaker 1: Precisamos manter busca, resumo estruturado e chat contextual no lancamento.',
    ].join('\n');
  }

  List<RecordingNote> _filteredRecordings() {
    return _recordings.where((recording) {
      if (_activeProjectId != null && recording.projectId != _activeProjectId) {
        return false;
      }
      if (_searchQuery.isEmpty) {
        return true;
      }

      final query = _searchQuery.toLowerCase();
      final haystack = [
        recording.title,
        recording.summary?.overview ?? '',
        recording.noteArtifact?.tags.join(' ') ?? '',
        recording.transcriptSegments.map((segment) => segment.text).join(' '),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  void _loadDemoData() {
      _projects = [
        Project(
          id: 'project-demo',
          name: 'Projeto demo',
          slug: 'projeto-demo',
          status: 'active',
          createdAt: DateTime(2026, 3, 26, 10, 0, 0),
          updatedAt: DateTime(2026, 3, 26, 10, 0, 0),
        ),
      ];
    _activeProjectId ??= 'project-demo';
    _recordings = demoNotes;
  }

  void _replaceRecording(RecordingNote next) {
    _recordings = [
      for (final recording in _recordings)
        if (recording.id == next.id) next else recording,
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    super.dispose();
  }
}

extension<T> on List<T> {
  T? get singleOrNull => length == 1 ? this[0] : null;
}
