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
      recordingId: json['recordingId'] as String? ?? json['recording_id'] as String,
      speakerLabel: json['speakerLabel'] as String? ?? json['speaker_label'] as String,
      startMs: json['startMs'] as int? ?? json['start_ms'] as int,
      endMs: json['endMs'] as int? ?? json['end_ms'] as int,
      text: json['text'] as String,
    );
  }
}

class RecordingSummary {
  const RecordingSummary({
    required this.overview,
    required this.chapters,
  });

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
  const SummaryChapter({
    required this.heading,
    required this.body,
  });

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
      highlights: (json['highlights'] as List<dynamic>? ?? const []).cast<String>(),
      actionItems: (json['actionItems'] as List<dynamic>? ?? json['action_items'] as List<dynamic>? ?? const [])
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
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
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
      recordingId: json['recordingId'] as String? ?? json['recording_id'] as String,
      messages: rawMessages
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecordingNote {
  const RecordingNote({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.transcriptSegments,
    this.durationMs,
    this.audioPath,
    this.summary,
    this.noteArtifact,
    this.chatSession,
    this.lastError,
  });

  final String id;
  final String title;
  final String sourceType;
  final ProcessingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? durationMs;
  final String? audioPath;
  final List<TranscriptSegment> transcriptSegments;
  final RecordingSummary? summary;
  final NoteArtifact? noteArtifact;
  final ChatSession? chatSession;
  final String? lastError;

  bool get isReady => status == ProcessingStatus.ready;

  RecordingNote copyWith({
    String? title,
    ProcessingStatus? status,
    DateTime? updatedAt,
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
      title: title ?? this.title,
      sourceType: sourceType,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    final rawSegments = (json['transcriptSegments'] as List<dynamic>? ?? json['transcript_segments'] as List<dynamic>? ?? const []);
    return RecordingNote(
      id: json['id'] as String,
      title: json['title'] as String,
      sourceType: json['sourceType'] as String? ?? json['source_type'] as String,
      status: ProcessingStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
      durationMs: json['durationMs'] as int? ?? json['duration_ms'] as int?,
      audioPath: json['audioPath'] as String? ?? json['audio_path'] as String?,
      transcriptSegments: rawSegments
          .map((item) => TranscriptSegment.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] == null ? null : RecordingSummary.fromJson(json['summary'] as Map<String, dynamic>),
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
      contentType: json['contentType'] as String? ?? json['content_type'] as String,
      body: json['body'] as String,
    );
  }
}
