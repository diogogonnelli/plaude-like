import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../data/demo_content.dart';
import '../data/models.dart';
import '../data/plaude_api.dart';

class PlaudeController extends ChangeNotifier {
  PlaudeController({
    required this.api,
  });

  final PlaudeApi api;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  List<RecordingNote> _recordings = [];
  bool _isLoading = true;
  bool _backendAvailable = false;
  bool _isRecording = false;
  String _searchQuery = '';
  String? _recordingPath;
  String? _currentlyPlayingPath;
  String? _notice;
  final Set<String> _processingIds = <String>{};
  final Set<String> _chatBusyIds = <String>{};

  List<RecordingNote> get recordings {
    if (_searchQuery.isEmpty) {
      return _recordings;
    }

    final query = _searchQuery.toLowerCase();
    return _recordings.where((recording) {
      final haystack = [
        recording.title,
        recording.summary?.overview ?? '',
        recording.noteArtifact?.tags.join(' ') ?? '',
        recording.transcriptSegments.map((segment) => segment.text).join(' '),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get backendAvailable => _backendAvailable;
  bool get isRecording => _isRecording;
  String? get notice => _notice;
  String get searchQuery => _searchQuery;

  Future<void> bootstrap() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      _backendAvailable = await api.isHealthy();
      _recordings = _backendAvailable ? await api.listRecordings() : demoNotes;
      _notice = _backendAvailable
          ? 'Connected to local backend.'
          : 'Running in demo mode. Start the backend for live HTTP integration.';
    } catch (_) {
      _backendAvailable = false;
      _recordings = demoNotes;
      _notice = 'Backend unavailable. Showing local demo data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
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
      _notice = 'Recording capture is enabled for mobile and desktop builds. On web, use upload.';
      notifyListeners();
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _notice = 'Microphone permission was denied.';
      notifyListeners();
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/plaude_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _recordingPath = path;
    _isRecording = true;
    _notice = 'Recording in progress.';
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
      _notice = 'Recording finished without an output file.';
      notifyListeners();
      return;
    }

    await _createAndProcessRecording(
      title: 'Voice note ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      sourceType: 'microphone',
      audioPath: _recordingPath,
      durationMs: null,
    );
  }

  Future<void> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'mp4'],
      withData: kIsWeb,
    );

    final file = result?.files.singleOrNull;
    if (file == null) {
      return;
    }

    await _createAndProcessRecording(
      title: file.name,
      sourceType: 'upload',
      audioPath: file.path ?? file.name,
      durationMs: null,
    );
  }

  Future<void> _createAndProcessRecording({
    required String title,
    required String sourceType,
    String? audioPath,
    int? durationMs,
  }) async {
    final created = await _createRecording(
      title: title,
      sourceType: sourceType,
      audioPath: audioPath,
      durationMs: durationMs,
    );

    await processRecording(
      created.id,
      transcriptText: _mockTranscriptFor(title),
    );
  }

  Future<RecordingNote> _createRecording({
    required String title,
    required String sourceType,
    String? audioPath,
    int? durationMs,
  }) async {
    if (_backendAvailable) {
      try {
        final created = await api.createRecording(
          title: title,
          sourceType: sourceType,
          audioPath: audioPath,
          durationMs: durationMs,
        );
        _recordings = [created, ..._recordings];
        _notice = 'Recording registered. Processing started.';
        notifyListeners();
        return created;
      } catch (_) {
        _backendAvailable = false;
      }
    }

    final created = RecordingNote(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
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
    _notice = 'Created locally in demo mode.';
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
        _notice = 'Processing completed.';
        return;
      } catch (_) {
        _backendAvailable = false;
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
    _notice = 'Processed locally in demo mode.';
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
      _notice = 'Chat request failed. Staying in demo mode.';
      _backendAvailable = false;
      final assistantMessage = _buildLocalChatAnswer(current, trimmed);
      final refreshed = findById(recordingId);
      if (refreshed != null) {
        final session = refreshed.chatSession ?? baseSession;
        _replaceRecording(
          refreshed.copyWith(
            chatSession: ChatSession(
              id: session.id,
              recordingId: session.recordingId,
              messages: [...session.messages, assistantMessage],
            ),
          ),
        );
      }
    } finally {
      _chatBusyIds.remove(recordingId);
      notifyListeners();
    }
  }

  Future<ExportArtifact> exportRecording(String recordingId, String format) async {
    final current = findById(recordingId);
    if (current == null) {
      throw StateError('Recording not found');
    }

    if (_backendAvailable) {
      try {
        return await api.exportRecording(recordingId: recordingId, format: format);
      } catch (_) {
        _backendAvailable = false;
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
            '## Overview',
            current.summary?.overview ?? 'No summary',
            '',
            '## Highlights',
            ...highlights.map((item) => '- $item'),
            '',
            '## Action items',
            ...actionItems.map((item) => '- $item'),
            '',
            '## Transcript',
            '```text',
            transcript,
            '```',
          ].join('\n')
        : [
            current.noteArtifact?.title ?? current.title,
            '',
            current.summary?.overview ?? 'No summary',
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
      _notice = 'Playback is only available for local mobile or desktop recordings.';
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
        overview: 'Note processed locally with a structured overview, searchable transcript and grounded chat context.',
        chapters: [
          SummaryChapter(
            heading: 'Context',
            body: highlights.isNotEmpty ? highlights.first : 'No key context detected.',
          ),
          SummaryChapter(
            heading: 'Execution',
            body: actionItems.isNotEmpty ? actionItems.first : 'No explicit action item detected.',
          ),
        ],
      ),
      noteArtifact: NoteArtifact(
        title: base.title,
        tags: <String>[
          base.sourceType,
          if (base.title.toLowerCase().contains('launch')) 'launch' else 'note',
          'ai-ready',
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

    final actionItems = recording.noteArtifact?.actionItems.join('; ') ?? 'No action items were extracted yet.';
    final answerText = question.toLowerCase().contains('ação') ||
            question.toLowerCase().contains('next') ||
            question.toLowerCase().contains('próximo')
        ? 'Os próximos passos detectados são: $actionItems'
        : 'A nota indica: ${recording.summary?.overview ?? 'No summary available yet.'}';

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
      'Speaker 2: Vamos registrar responsáveis, riscos e próximos passos para o produto.',
      'Speaker 1: Precisamos manter busca, resumo estruturado e chat contextual no lançamento.',
    ].join('\n');
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
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    super.dispose();
  }
}

extension<T> on List<T> {
  T? get singleOrNull => length == 1 ? this[0] : null;
}
