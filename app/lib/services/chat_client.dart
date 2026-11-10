import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_settings.dart';

class ChatResult {
  const ChatResult({
    required this.sessionId,
    required this.reply,
    required this.provider,
  });

  final String sessionId;
  final String reply;
  final String provider;
}

class ChatClientException implements Exception {
  ChatClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class ChatClient {
  Future<ChatResult> sendMessage({required String message, String? sessionId});

  Future<void> deleteSession(String sessionId);
}

class HttpChatClient implements ChatClient {
  HttpChatClient({
    required this.settings,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _http = httpClient ?? http.Client();

  final BackendSettings settings;
  final http.Client _http;
  final Duration timeout;

  Uri _uri(String path) => Uri.parse('${settings.baseUrl}$path');

  @override
  Future<ChatResult> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    final payload = <String, String>{'message': message};
    if (sessionId != null && sessionId.isNotEmpty) {
      payload['session_id'] = sessionId;
    }
    final response = await _send(
      () => _http.post(
        _uri('/chat'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(payload),
      ),
    );
    _ensureSuccess(response);
    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw ChatClientException(
          'The companion sent a response the app could not read.',
        );
      }
      final reply = body['reply'];
      final id = body['session_id'];
      if (reply is! String || reply.isEmpty || id is! String || id.isEmpty) {
        throw ChatClientException('The companion sent an incomplete reply.');
      }
      final provider = body['provider'];
      return ChatResult(
        sessionId: id,
        reply: reply,
        provider: provider is String && provider.isNotEmpty
            ? provider
            : 'unknown',
      );
    } on ChatClientException {
      rethrow;
    } catch (_) {
      throw ChatClientException(
        'The companion sent a response the app could not read.',
      );
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final response = await _send(
      () => _http.delete(_uri('/sessions/${Uri.encodeComponent(sessionId)}')),
    );
    _ensureSuccess(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw ChatClientException('The companion took too long to respond.');
    } on http.ClientException {
      throw ChatClientException(
        "Couldn't reach the companion service. Check the backend URL.",
      );
    } on FormatException {
      throw ChatClientException(
        "Couldn't reach the companion service. Check the backend URL.",
      );
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw ChatClientException(
      _detail(response),
      statusCode: response.statusCode,
    );
  }

  String _detail(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        return body['detail'] as String;
      }
    } catch (_) {
      // Fall through to the status code.
    }
    return 'The companion service returned ${response.statusCode}.';
  }
}
