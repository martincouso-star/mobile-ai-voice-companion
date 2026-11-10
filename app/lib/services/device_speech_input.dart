import 'package:speech_to_text/speech_to_text.dart';

import 'speech_input.dart';

/// Device recognizer via the `speech_to_text` plugin.
///
/// Android uses the platform speech recognizer. iOS uses the Speech
/// framework. Both need the permissions declared in the app manifests.
class DeviceSpeechInput implements SpeechInput {
  DeviceSpeechInput({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  var _ready = false;
  String _latest = '';

  @override
  bool get isAvailable => _ready;

  @override
  Future<void> initialize() async {
    if (_ready) {
      return;
    }
    _ready = await _speech.initialize();
  }

  @override
  Future<void> start({
    required void Function(String partial) onTranscript,
  }) async {
    _latest = '';
    if (!_ready) {
      throw StateError('Speech recognition is not initialized');
    }
    await _speech.listen(
      onResult: (result) {
        _latest = result.recognizedWords;
        // The platform may deliver a final result shortly after stop().
        // The controller sends whatever is here when the button is released.
        onTranscript(_latest);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<String> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    return _latest;
  }
}
