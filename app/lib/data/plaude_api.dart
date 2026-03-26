import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class PlaudeApi {
  PlaudeApi({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Map<String, String> _headers = const {
    'content-type': 'application/json',
    'x-user-id': 'demo-user',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse(baseUrl).replace(
      path: path,
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }

  Future<bool> isHealthy() async {
    final response = await _client.get(_uri('/health'));
    return response.statusCode == 200;
  }

  Future<List<RecordingNote>> listRecordings({String? query}) async {
    final response = await _client.get(
      _uri('/recordings', query == null || query.isEmpty ? null : {'query': query}),
      headers: _headers,
    );
    final payload = _decode(response);
    final raw = payload['data'] as List<dynamic>;
    return raw.map((item) => RecordingNote.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<RecordingNote> createRecording({
    required String title,
    required String sourceType,
    String? audioPath,
    int? durationMs,
  }) async {
    final response = await _client.post(
      _uri('/recordings'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'sourceType': sourceType,
        'audioPath': audioPath,
        'durationMs': durationMs,
      }),
    );
    final payload = _decode(response);
    return RecordingNote.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<RecordingNote> processRecording({
    required String recordingId,
    String? transcriptText,
  }) async {
    final response = await _client.post(
      _uri('/recordings/$recordingId/process'),
      headers: _headers,
      body: jsonEncode({
        'transcriptText': transcriptText,
      }),
    );
    final payload = _decode(response);
    return RecordingNote.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<RecordingNote> getRecording(String recordingId) async {
    final response = await _client.get(
      _uri('/recordings/$recordingId'),
      headers: _headers,
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
      headers: _headers,
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
      headers: _headers,
      body: jsonEncode({'format': format}),
    );
    final payload = _decode(response);
    return ExportArtifact.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlaudeApiException(
        'Request failed with ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class PlaudeApiException implements Exception {
  PlaudeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
