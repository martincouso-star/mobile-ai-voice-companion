/// Push-to-talk speech recognition.
///
/// [start] may call [onTranscript] more than once with a growing partial.
/// [stop] returns the best transcript captured for that hold.
abstract class SpeechInput {
  Future<void> initialize();

  bool get isAvailable;

  Future<void> start({required void Function(String partial) onTranscript});

  Future<String> stop();
}
