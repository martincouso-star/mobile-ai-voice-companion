import 'package:flutter_tts/flutter_tts.dart';

import 'speech_output.dart';

class FlutterTtsOutput implements SpeechOutput {
  FlutterTtsOutput({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  var _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    _configured = true;
  }

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  @override
  Future<void> stop() => _tts.stop();
}
