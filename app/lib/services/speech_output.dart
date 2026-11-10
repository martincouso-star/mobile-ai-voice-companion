/// Reads a reply aloud.
abstract class SpeechOutput {
  Future<void> speak(String text);

  Future<void> stop();
}
