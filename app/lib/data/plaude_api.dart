import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class PlaudeApi {
  PlaudeApi({
    required this.baseUrl,
    this.accessTokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String?> Function()? accessTokenProvider;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse(baseUrl).replace(
      path: path,
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }

  Future<Map<String, String>> _headers({
    bool includeJsonContentType = true,
  }) async {
    final headers = <String, String>{
      'cache-control': 'no-cache',
      'pragma': 'no-cache',
    };

    if (includeJsonContentType) {
      headers['content-type'] = 'application/json';
    }

    final token = await accessTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['authorization'] = 'Bearer $token';
    } else {
      headers['x-user-id'] = 'demo-user';
    }

    return headers;
  }

  Future<bool> isHealthy() async {
    final response = await _client.get(
      _uri('/health', {
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      }),
      headers: await _headers(),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<List<RecordingNote>> listRecordings({
    String? query,
    String? projectId,
    bool withoutProject = false,
  }) async {
    final requestQuery = <String, String>{
      '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    if (query != null && query.isNotEmpty) {
      requestQuery['query'] = query;
    }
    if (projectId != null && projectId.isNotEmpty) {
      requestQuery['projectId'] = projectId;
    }
    if (withoutProject) {
      requestQuery['withoutProject'] = 'true';
    }

    final response = await _client.get(
      _uri('/recordings', requestQuery),
      headers: await _headers(),
    );
    final payload = _decode(response);
    final raw = payload['data'] as List<dynamic>;
    return raw
        .map((item) => RecordingNote.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Project>> listProjects() async {
    final response = await _client.get(
      _uri('/projects', {
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      }),
      headers: await _headers(),
    );
    final payload = _decode(response);
    final raw = payload['data'] as List<dynamic>;
    return raw
        .map((item) => Project.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RecordingNote> createRecording({
    required String title,
    String? projectId,
    required String sourceType,
    CaptureMetadata? captureMetadata,
    String? audioPath,
    int? durationMs,
  }) async {
    final requestPayload = <String, dynamic>{
      'title': title,
      'sourceType': sourceType,
    };
    if (projectId != null && projectId.isNotEmpty) {
      requestPayload['projectId'] = projectId;
    }
    if (captureMetadata != null) {
      requestPayload['captureMetadata'] = captureMetadata.toJson();
    }
    if (audioPath != null) {
      requestPayload['audioPath'] = audioPath;
    }
    if (durationMs != null) {
      requestPayload['durationMs'] = durationMs;
    }

    final response = await _client.post(
      _uri('/recordings'),
      headers: await _headers(),
      body: jsonEncode(requestPayload),
    );
    final payload = _decode(response);
    return RecordingNote.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<RecordingNote> uploadRecording({
    required PlatformFile file,
    required String title,
    String? projectId,
    String sourceType = 'upload',
    CaptureMetadata? captureMetadata,
    int? durationMs,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/recordings/upload'));
    request.headers.addAll(await _headers(includeJsonContentType: false));
    request.fields['title'] = title;
    if (projectId != null && projectId.isNotEmpty) {
      request.fields['projectId'] = projectId;
    }
    request.fields['sourceType'] = sourceType;
    if (captureMetadata != null) {
      request.fields['captureMetadata'] = jsonEncode(captureMetadata.toJson());
    }
    if (durationMs != null) {
      request.fields['durationMs'] = durationMs.toString();
    }

    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );
    } else if (file.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
    } else {
      throw PlaudeApiException('Arquivo sem bytes ou caminho local.');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final payload = _decode(response);
    return RecordingNote.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<RecordingNote> processRecording({
    required String recordingId,
    String? transcriptText,
  }) async {
    final requestPayload = <String, dynamic>{};
    if (transcriptText != null) {
      requestPayload['transcriptText'] = transcriptText;
    }

    final response = await _client.post(
      _uri('/recordings/$recordingId/process'),
      headers: await _headers(),
      body: jsonEncode(requestPayload),
    );
    final payload = _decode(response);
    return RecordingNote.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<RecordingNote> getRecording(String recordingId) async {
    final response = await _client.get(
      _uri('/recordings/$recordingId', {
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      }),
      headers: await _headers(),
    );
    final payload = _decode(response);
    return RecordingNote.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<RecordingNote> updateRecording({
    required String recordingId,
    String? title,
    String? projectId,
    bool clearProjectId = false,
  }) async {
    final requestPayload = <String, dynamic>{};
    if (title != null && title.isNotEmpty) {
      requestPayload['title'] = title;
    }
    if (clearProjectId) {
      requestPayload['projectId'] = null;
    } else if (projectId != null && projectId.isNotEmpty) {
      requestPayload['projectId'] = projectId;
    }

    final response = await _client.patch(
      _uri('/recordings/$recordingId'),
      headers: await _headers(),
      body: jsonEncode(requestPayload),
    );
    final payload = _decode(response);
    return RecordingNote.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> askQuestion({
    required String recordingId,
    required String question,
  }) async {
    final response = await _client.post(
      _uri('/recordings/$recordingId/chat'),
      headers: await _headers(),
      body: jsonEncode({'question': question}),
    );
    final payload = _decode(response);
    return ChatMessage.fromJson(payload['answer'] as Map<String, dynamic>);
  }

  Future<ExportArtifact> exportRecording({
    required String recordingId,
    required String format,
  }) async {
    final response = await _client.post(
      _uri('/recordings/$recordingId/export'),
      headers: await _headers(),
      body: jsonEncode({'format': format}),
    );
    final payload = _decode(response);
    return ExportArtifact.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _decode(http.Response response) {
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlaudeApiException(
        'Request failed with ${response.statusCode}: ${response.body}',
      );
    }
  }
}

class PlaudeApiException implements Exception {
  PlaudeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
