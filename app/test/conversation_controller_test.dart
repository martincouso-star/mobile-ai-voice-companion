import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_companion/models/chat_message.dart';
import 'package:voice_companion/services/backend_settings.dart';
import 'package:voice_companion/services/chat_client.dart';
import 'package:voice_companion/services/settings_store.dart';
import 'package:voice_companion/state/conversation_controller.dart';

import 'support/fakes.dart';

void main() {
  late FakeChatClient chat;
  late FakeSpeechInput speech;
  late FakeSpeechOutput tts;
  late MemorySettingsStore store;
  late BackendSettings settings;
  late ConversationController controller;

  setUp(() {
    chat = FakeChatClient();
    speech = FakeSpeechInput();
    tts = FakeSpeechOutput();
    store = MemorySettingsStore();
    settings = BackendSettings('http://example.test:8080');
    controller = ConversationController(
      chat: chat,
      speech: speech,
      tts: tts,
      settings: settings,
      settingsStore: store,
    );
  });

  tearDown(() => controller.dispose());

  test('typed message is sent, shown, and spoken', () async {
    await controller.sendText('  Hello  ');

    expect(chat.sent, ['Hello']);
    expect(controller.messages.map((message) => message.text), [
      'Hello',
      'Echo: Hello',
    ]);
    expect(controller.messages.first.role, ChatRole.user);
    expect(controller.messages.last.role, ChatRole.assistant);
    expect(controller.sessionId, 'session-1');
    expect(controller.providerName, 'mock');
    expect(tts.spoken, ['Echo: Hello']);
    expect(controller.phase, CompanionPhase.idle);
  });

  test('empty text is ignored', () async {
    await controller.sendText('   ');
    expect(chat.sent, isEmpty);
    expect(controller.messages, isEmpty);
  });

  test('speak replies can be turned off', () async {
    await controller.setSpeakReplies(false);
    await controller.sendText('Hi');
    expect(tts.spoken, isEmpty);
    expect(store.speakReplies, isFalse);
  });

  test('api errors stay on screen with the user turn', () async {
    chat.error = ChatClientException('backend down', statusCode: 502);
    await controller.sendText('Hi');
    expect(controller.messages, hasLength(1));
    expect(controller.errorMessage, 'backend down');
    expect(controller.phase, CompanionPhase.idle);
    expect(tts.spoken, isEmpty);
  });

  test('push to talk sends the transcript', () async {
    await controller.pressMic();
    expect(controller.phase, CompanionPhase.listening);
    expect(controller.partialTranscript, 'hello from the mic');
    await controller.releaseMic();
    expect(speech.stopCalls, 1);
    expect(chat.sent, ['hello from the mic']);
    expect(controller.partialTranscript, isEmpty);
    expect(controller.messages.last.text, 'Echo: hello from the mic');
  });

  test('releasing during startup still sends the utterance', () async {
    speech.startGate = Completer<void>();
    final pressing = controller.pressMic();
    await Future<void>.delayed(Duration.zero);
    expect(speech.started, isTrue);
    await controller.releaseMic();
    speech.startGate!.complete();
    await pressing;
    expect(chat.sent, ['hello from the mic']);
  });

  test('unavailable recognizer explains that typing still works', () async {
    speech.available = false;
    await controller.pressMic();
    expect(chat.sent, isEmpty);
    expect(controller.errorMessage, contains('not available'));
    expect(controller.phase, CompanionPhase.idle);
  });

  test('new conversation deletes the server session', () async {
    await controller.sendText('Hi');
    await controller.newConversation();
    expect(controller.messages, isEmpty);
    expect(controller.sessionId, isNull);
    expect(chat.deleted, ['session-1']);
  });

  test('backend url is validated and stored', () async {
    expect(await controller.updateBackendUrl('not a url'), isFalse);
    expect(settings.baseUrl, 'http://example.test:8080');
    expect(await controller.updateBackendUrl('http://127.0.0.1:9000/'), isTrue);
    expect(settings.baseUrl, 'http://127.0.0.1:9000');
    expect(store.backendUrl, 'http://127.0.0.1:9000');
  });

  test('a speech synthesis failure keeps the written reply', () async {
    tts.failOnSpeak = true;
    await controller.sendText('Hi');
    expect(controller.messages, hasLength(2));
    expect(controller.errorMessage, contains('read aloud'));
    expect(controller.phase, CompanionPhase.idle);
  });
}
