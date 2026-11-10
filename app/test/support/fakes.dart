import 'dart:async';

import 'package:voice_companion/services/chat_client.dart';
import 'package:voice_companion/services/speech_input.dart';
import 'package:voice_companion/services/speech_output.dart';

class FakeChatClient implements ChatClient {
  FakeChatClient({this.error, this.sessionId = 'session-1'});

  ChatClientException? error;
  String sessionId;
  final List<String> sent = <String>[];
  final List<String> deleted = <String>[];

  @override
  Future<ChatResult> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    sent.add(message);
    if (error != null) {
      throw error!;
    }
    return ChatResult(
      sessionId: sessionId ?? this.sessionId,
      reply: 'Echo: $message',
      provider: 'mock',
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    deleted.add(sessionId);
  }
}

class FakeSpeechInput implements SpeechInput {
  FakeSpeechInput({this.available = true, this.result = 'hello from the mic'});

  bool available;
  String result;
  bool started = false;
  int stopCalls = 0;
  Completer<void>? startGate;
  void Function(String partial)? _onTranscript;

  @override
  bool get isAvailable => available;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start({
    required void Function(String partial) onTranscript,
  }) async {
    started = true;
    _onTranscript = onTranscript;
    onTranscript(result);
    final gate = startGate;
    if (gate != null) {
      await gate.future;
    }
  }

  @override
  Future<String> stop() async {
    stopCalls += 1;
    started = false;
    return result;
  }

  void emit(String text) {
    result = text;
    _onTranscript?.call(text);
  }
}

class FakeSpeechOutput implements SpeechOutput {
  final List<String> spoken = <String>[];
  int stopCalls = 0;
  bool failOnSpeak = false;

  @override
  Future<void> speak(String text) async {
    if (failOnSpeak) {
      throw StateError('tts failed');
    }
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}
