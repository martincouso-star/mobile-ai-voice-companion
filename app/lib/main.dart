import 'package:flutter/material.dart';

import 'app.dart';
import 'config/backend_config.dart';
import 'services/backend_settings.dart';
import 'services/chat_client.dart';
import 'services/device_speech_input.dart';
import 'services/flutter_tts_output.dart';
import 'services/settings_store.dart';
import 'state/conversation_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await SharedPrefsSettingsStore.load();
  final savedUrl = await store.readBackendUrl();
  final settings = BackendSettings(
    BackendConfig.normalize(savedUrl ?? '') ?? BackendConfig.fromEnvironment(),
  );
  final speakReplies = await store.readSpeakReplies() ?? true;
  final controller = ConversationController(
    chat: HttpChatClient(settings: settings),
    speech: DeviceSpeechInput(),
    tts: FlutterTtsOutput(),
    settings: settings,
    settingsStore: store,
    speakReplies: speakReplies,
  );
  runApp(VoiceCompanionApp(controller: controller));
}
