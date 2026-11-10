import 'package:flutter/foundation.dart';

import '../config/backend_config.dart';
import '../models/chat_message.dart';
import '../services/backend_settings.dart';
import '../services/chat_client.dart';
import '../services/settings_store.dart';
import '../services/speech_input.dart';
import '../services/speech_output.dart';

enum CompanionPhase { idle, listening, thinking, speaking }

/// Owns one on-screen conversation and the mic / speech lifecycle.
class ConversationController extends ChangeNotifier {
  ConversationController({
    required this.chat,
    required this.speech,
    required this.tts,
    required this.settings,
    this.settingsStore,
    this._speakReplies = true,
  });

  final ChatClient chat;
  final SpeechInput speech;
  final SpeechOutput tts;
  final BackendSettings settings;
  final SettingsStore? settingsStore;

  final List<ChatMessage> messages = <ChatMessage>[];
  CompanionPhase phase = CompanionPhase.idle;
  String partialTranscript = '';
  String? errorMessage;
  String? sessionId;
  String? providerName;

  bool _speakReplies;
  bool _holdWanted = false;
  bool _startingMic = false;
  bool _listening = false;

  bool get speakReplies => _speakReplies;

  bool get canSend =>
      phase != CompanionPhase.thinking && phase != CompanionPhase.listening;

  /// Begin listening. Safe to call again while a hold is already active.
  Future<void> pressMic() async {
    if (_holdWanted || phase == CompanionPhase.thinking) {
      return;
    }
    _holdWanted = true;
    _startingMic = true;
    errorMessage = null;
    partialTranscript = '';
    notifyListeners();
    try {
      await speech.initialize();
      if (!_holdWanted) {
        return;
      }
      if (!speech.isAvailable) {
        errorMessage = 'Speech recognition is not available on this device. You can type instead.';
        _holdWanted = false;
        notifyListeners();
        return;
      }
      phase = CompanionPhase.listening;
      _listening = true;
      notifyListeners();
      await speech.start(
        onTranscript: (text) {
          partialTranscript = text;
          notifyListeners();
        },
      );
    } catch (_) {
      _listening = false;
      _holdWanted = false;
      phase = CompanionPhase.idle;
      errorMessage = 'Could not start the microphone.';
      notifyListeners();
    } finally {
      _startingMic = false;
    }
    if (!_holdWanted && _listening) {
      await _finishUtterance();
    }
  }

  /// End the current hold and send whatever was recognized.
  Future<void> releaseMic() async {
    if (!_holdWanted) {
      return;
    }
    _holdWanted = false;
    if (_startingMic) {
      return;
    }
    if (!_listening) {
      return;
    }
    await _finishUtterance();
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || phase == CompanionPhase.thinking || _listening) {
      return;
    }
    try {
      await tts.stop();
    } catch (_) {
      // Playback may already be stopped.
    }
    messages.add(ChatMessage.user(trimmed));
    phase = CompanionPhase.thinking;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await chat.sendMessage(
        message: trimmed,
        sessionId: sessionId,
      );
      sessionId = result.sessionId;
      providerName = result.provider;
      messages.add(ChatMessage.assistant(result.reply));
      if (_speakReplies && result.reply.trim().isNotEmpty) {
        phase = CompanionPhase.speaking;
        notifyListeners();
        try {
          await tts.speak(result.reply);
        } catch (_) {
          errorMessage =
              "The reply is on screen, but it couldn't be read aloud.";
        }
      }
      phase = CompanionPhase.idle;
    } on ChatClientException catch (error) {
      phase = CompanionPhase.idle;
      errorMessage = error.message;
    } catch (_) {
      phase = CompanionPhase.idle;
      errorMessage = 'Something went wrong talking to the companion.';
    }
    notifyListeners();
  }

  /// True when [url] was saved. False when it is not an http(s) URL.
  Future<bool> updateBackendUrl(String url) async {
    if (BackendConfig.normalize(url) == null) {
      return false;
    }
    settings.update(url);
    await settingsStore?.writeBackendUrl(settings.baseUrl);
    return true;
  }

  Future<void> setSpeakReplies(bool value) async {
    _speakReplies = value;
    if (!value) {
      try {
        await tts.stop();
      } catch (_) {
        // Ignore a synthesizer that is already idle.
      }
    }
    await settingsStore?.writeSpeakReplies(value);
    notifyListeners();
  }

  Future<void> newConversation() async {
    if (_listening) {
      _listening = false;
      _holdWanted = false;
      try {
        await speech.stop();
      } catch (_) {
        // The recognizer may already have stopped.
      }
    }
    final previous = sessionId;
    messages.clear();
    sessionId = null;
    providerName = null;
    partialTranscript = '';
    errorMessage = null;
    phase = CompanionPhase.idle;
    notifyListeners();
    if (previous == null) {
      return;
    }
    try {
      await chat.deleteSession(previous);
    } catch (_) {
      // The screen is already clear. Process memory on the server expires
      // when that process does.
    }
  }

  Future<void> _finishUtterance() async {
    _listening = false;
    var spoken = '';
    try {
      spoken = (await speech.stop()).trim();
    } catch (_) {
      spoken = '';
    }
    if (spoken.isEmpty) {
      spoken = partialTranscript.trim();
    }
    partialTranscript = '';
    if (spoken.isEmpty) {
      phase = CompanionPhase.idle;
      notifyListeners();
      return;
    }
    await sendText(spoken);
  }
}
