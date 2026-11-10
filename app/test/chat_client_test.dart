import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voice_companion/config/backend_config.dart';
import 'package:voice_companion/services/backend_settings.dart';
import 'package:voice_companion/services/chat_client.dart';

void main() {
  test('normalize accepts http urls and strips a trailing slash', () {
    expect(
      BackendConfig.normalize(' http://127.0.0.1:8080/ '),
      'http://127.0.0.1:8080',
    );
    expect(BackendConfig.normalize('ftp://example.test'), isNull);
    expect(BackendConfig.normalize('example.test'), isNull);
  });

  test('posts the transcript and parses the reply', () async {
    final settings = BackendSettings('http://example.test/');
    final client = HttpChatClient(
      settings: settings,
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'http://example.test/chat');
        expect(request.headers['content-type'], contains('application/json'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {'message': 'hi', 'session_id': 'abc'});
        return http.Response(
          jsonEncode({
            'session_id': 'abc',
            'reply': 'hello',
            'provider': 'mock',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await client.sendMessage(message: 'hi', sessionId: 'abc');
    expect(result.reply, 'hello');
    expect(result.sessionId, 'abc');
    expect(result.provider, 'mock');
  });

  test('surfaces FastAPI error detail', () async {
    final client = HttpChatClient(
      settings: BackendSettings('http://example.test'),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'The companion could not produce a reply.'}),
          502,
        ),
      ),
    );

    expect(
      () => client.sendMessage(message: 'hi'),
      throwsA(
        isA<ChatClientException>().having(
          (error) => error.message,
          'message',
          'The companion could not produce a reply.',
        ),
      ),
    );
  });

  test('times out with a readable error', () async {
    final pending = Completer<http.Response>();
    final client = HttpChatClient(
      settings: BackendSettings('http://example.test'),
      timeout: const Duration(milliseconds: 20),
      httpClient: MockClient((_) => pending.future),
    );

    expect(
      () => client.sendMessage(message: 'hi'),
      throwsA(
        isA<ChatClientException>().having(
          (error) => error.message,
          'message',
          'The companion took too long to respond.',
        ),
      ),
    );
  });

  test('deletes a session', () async {
    final client = HttpChatClient(
      settings: BackendSettings('http://example.test'),
      httpClient: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(
          request.url.toString(),
          'http://example.test/sessions/session%201',
        );
        return http.Response('', 204);
      }),
    );

    await client.deleteSession('session 1');
  });
}
