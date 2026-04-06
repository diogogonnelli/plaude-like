enum ProcessingStatus {
  uploaded,
  processingTranscript,
  processingSummary,
  indexing,
  ready,
  failed;

  String get apiValue => switch (this) {
    ProcessingStatus.uploaded => 'uploaded',
    ProcessingStatus.processingTranscript => 'processing_transcript',
    ProcessingStatus.processingSummary => 'processing_summary',
    ProcessingStatus.indexing => 'indexing',
    ProcessingStatus.ready => 'ready',
    ProcessingStatus.failed => 'failed',
  };

  String get label => switch (this) {
    ProcessingStatus.uploaded => 'Enviado',
    ProcessingStatus.processingTranscript => 'Transcrevendo',
    ProcessingStatus.processingSummary => 'Resumindo',
    ProcessingStatus.indexing => 'Indexando',
    ProcessingStatus.ready => 'Pronto',
    ProcessingStatus.failed => 'Falhou',
  };

  static ProcessingStatus fromApi(String value) {
    return ProcessingStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => ProcessingStatus.uploaded,
    );
  }
}

class CaptureMetadata {
  const CaptureMetadata({
    required this.sourceApp,
    required this.platform,
    required this.captureMode,
    required this.helperVersion,
    this.windowTitle,
  });

  final String sourceApp;
  final String platform;
  final String captureMode;
  final String helperVersion;
  final String? windowTitle;

  String get sourceLabel => switch (sourceApp) {
    'teams' => 'Teams',
    'zoom' => 'Zoom',
    'meet' => 'Google Meet',
    'system_audio' => 'Áudio do sistema',
    _ => sourceApp,
  };

  String get platformLabel => switch (platform) {
    'windows' => 'Windows',
    'macos' => 'macOS',
    _ => platform,
  };

  factory CaptureMetadata.fromJson(Map<String, dynamic> json) {
    return CaptureMetadata(
      sourceApp: json['sourceApp'] as String? ?? json['source_app'] as String,
      platform: json['platform'] as String,
      captureMode:
          json['captureMode'] as String? ?? json['capture_mode'] as String,
      helperVersion:
          json['helperVersion'] as String? ??
          json['helper_version'] as String,
      windowTitle:
          json['windowTitle'] as String? ?? json['window_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceApp': sourceApp,
      'platform': platform,
      'captureMode': captureMode,
      'helperVersion': helperVersion,
      if (windowTitle != null) 'windowTitle': windowTitle,
    };
  }
}

class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.recordingId,
    required this.speakerLabel,
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  final String id;
  final String recordingId;
  final String speakerLabel;
  final int startMs;
  final int endMs;
  final String text;

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      id: json['id'] as String,
      recordingId:
          json['recordingId'] as String? ?? json['recording_id'] as String,
      speakerLabel:
          json['speakerLabel'] as String? ?? json['speaker_label'] as String,
      startMs: json['startMs'] as int? ?? json['start_ms'] as int,
      endMs: json['endMs'] as int? ?? json['end_ms'] as int,
      text: json['text'] as String,
    );
  }
}

class RecordingSummary {
  const RecordingSummary({required this.overview, required this.chapters});

  final String overview;
  final List<SummaryChapter> chapters;

  factory RecordingSummary.fromJson(Map<String, dynamic> json) {
    final rawChapters = (json['chapters'] as List<dynamic>? ?? const []);
    return RecordingSummary(
      overview: json['overview'] as String,
      chapters: rawChapters
          .map((item) => SummaryChapter.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SummaryChapter {
  const SummaryChapter({required this.heading, required this.body});

  final String heading;
  final String body;

  factory SummaryChapter.fromJson(Map<String, dynamic> json) {
    return SummaryChapter(
      heading: json['heading'] as String,
      body: json['body'] as String,
    );
  }
}

class NoteArtifact {
  const NoteArtifact({
    required this.title,
    required this.tags,
    required this.highlights,
    required this.actionItems,
  });

  final String title;
  final List<String> tags;
  final List<String> highlights;
  final List<String> actionItems;

  factory NoteArtifact.fromJson(Map<String, dynamic> json) {
    return NoteArtifact(
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      highlights: (json['highlights'] as List<dynamic>? ?? const [])
          .cast<String>(),
      actionItems:
          (json['actionItems'] as List<dynamic>? ??
                  json['action_items'] as List<dynamic>? ??
                  const [])
              .cast<String>(),
    );
  }
}

class ChatCitation {
  const ChatCitation({
    required this.segmentId,
    required this.startMs,
    required this.endMs,
    required this.quote,
  });

  final String segmentId;
  final int startMs;
  final int endMs;
  final String quote;

  factory ChatCitation.fromJson(Map<String, dynamic> json) {
    return ChatCitation(
      segmentId: json['segmentId'] as String? ?? json['segment_id'] as String,
      startMs: json['startMs'] as int? ?? json['start_ms'] as int,
      endMs: json['endMs'] as int? ?? json['end_ms'] as int,
      quote: json['quote'] as String,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.citations = const [],
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final List<ChatCitation> citations;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawCitations = (json['citations'] as List<dynamic>? ?? const []);
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      citations: rawCitations
          .map((item) => ChatCitation.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.recordingId,
    required this.messages,
  });

  final String id;
  final String recordingId;
  final List<ChatMessage> messages;

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final rawMessages = (json['messages'] as List<dynamic>? ?? const []);
    return ChatSession(
      id: json['id'] as String,
      recordingId:
          json['recordingId'] as String? ?? json['recording_id'] as String,
      messages: rawMessages
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecordingNote {
  const RecordingNote({
    required this.id,
    required this.projectId,
    required this.createdByUserId,
    required this.title,
    required this.sourceType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.transcriptSegments,
    this.captureMetadata,
    this.durationMs,
    this.audioPath,
    this.summary,
    this.noteArtifact,
    this.chatSession,
    this.lastError,
  });

  final String id;
  final String? projectId;
  final String createdByUserId;
  final String title;
  final String sourceType;
  final ProcessingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CaptureMetadata? captureMetadata;
  final int? durationMs;
  final String? audioPath;
  final List<TranscriptSegment> transcriptSegments;
  final RecordingSummary? summary;
  final NoteArtifact? noteArtifact;
  final ChatSession? chatSession;
  final String? lastError;

  bool get isReady => status == ProcessingStatus.ready;

  RecordingNote copyWith({
    String? projectId,
    bool clearProjectId = false,
    String? title,
    ProcessingStatus? status,
    DateTime? updatedAt,
    CaptureMetadata? captureMetadata,
    int? durationMs,
    String? audioPath,
    List<TranscriptSegment>? transcriptSegments,
    RecordingSummary? summary,
    NoteArtifact? noteArtifact,
    ChatSession? chatSession,
    String? lastError,
  }) {
    return RecordingNote(
      id: id,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      createdByUserId: createdByUserId,
      title: title ?? this.title,
      sourceType: sourceType,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      captureMetadata: captureMetadata ?? this.captureMetadata,
      durationMs: durationMs ?? this.durationMs,
      audioPath: audioPath ?? this.audioPath,
      transcriptSegments: transcriptSegments ?? this.transcriptSegments,
      summary: summary ?? this.summary,
      noteArtifact: noteArtifact ?? this.noteArtifact,
      chatSession: chatSession ?? this.chatSession,
      lastError: lastError ?? this.lastError,
    );
  }

  factory RecordingNote.fromJson(Map<String, dynamic> json) {
    final rawSegments =
        (json['transcriptSegments'] as List<dynamic>? ??
        json['transcript_segments'] as List<dynamic>? ??
        const []);
    return RecordingNote(
      id: json['id'] as String,
      projectId:
          json['projectId'] as String? ??
          json['project_id'] as String?,
      createdByUserId:
          json['createdByUserId'] as String? ??
          json['created_by_user_id'] as String? ??
          json['userId'] as String? ??
          'demo-user',
      title: json['title'] as String,
      sourceType:
          json['sourceType'] as String? ?? json['source_type'] as String,
      status: ProcessingStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['updated_at'] as String,
      ),
      captureMetadata: json['captureMetadata'] == null
          ? null
          : CaptureMetadata.fromJson(
              json['captureMetadata'] as Map<String, dynamic>,
            ),
      durationMs: json['durationMs'] as int? ?? json['duration_ms'] as int?,
      audioPath: json['audioPath'] as String? ?? json['audio_path'] as String?,
      transcriptSegments: rawSegments
          .map(
            (item) => TranscriptSegment.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      summary: json['summary'] == null
          ? null
          : RecordingSummary.fromJson(json['summary'] as Map<String, dynamic>),
      noteArtifact: json['noteArtifact'] == null
          ? null
          : NoteArtifact.fromJson(json['noteArtifact'] as Map<String, dynamic>),
      chatSession: json['chatSession'] == null
          ? null
          : ChatSession.fromJson(json['chatSession'] as Map<String, dynamic>),
      lastError: json['lastError'] as String? ?? json['last_error'] as String?,
    );
  }
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['updated_at'] as String,
      ),
    );
  }
}

class ExportArtifact {
  const ExportArtifact({
    required this.format,
    required this.fileName,
    required this.contentType,
    required this.body,
  });

  final String format;
  final String fileName;
  final String contentType;
  final String body;

  factory ExportArtifact.fromJson(Map<String, dynamic> json) {
    return ExportArtifact(
      format: json['format'] as String,
      fileName: json['fileName'] as String? ?? json['file_name'] as String,
      contentType:
          json['contentType'] as String? ?? json['content_type'] as String,
      body: json['body'] as String,
    );
  }
}
