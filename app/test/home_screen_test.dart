import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_companion/app.dart';
import 'package:voice_companion/services/backend_settings.dart';
import 'package:voice_companion/services/chat_client.dart';
import 'package:voice_companion/services/settings_store.dart';
import 'package:voice_companion/state/conversation_controller.dart';

import 'support/fakes.dart';

void main() {
  late FakeChatClient chat;
  late FakeSpeechInput speech;
  late FakeSpeechOutput tts;
  late ConversationController controller;

  setUp(() {
    chat = FakeChatClient();
    speech = FakeSpeechInput();
    tts = FakeSpeechOutput();
    controller = ConversationController(
      chat: chat,
      speech: speech,
      tts: tts,
      settings: BackendSettings('http://10.0.2.2:8080'),
      settingsStore: MemorySettingsStore(),
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(VoiceCompanionApp(controller: controller));
  }

  testWidgets('lays out on a small phone and in landscape', (tester) async {
    Future<void> at(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await pumpApp(tester);
      expect(tester.takeException(), isNull);
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await at(const Size(360, 640));
    await at(const Size(640, 360));
  });

  testWidgets('starts with an empty conversation', (tester) async {
    await pumpApp(tester);
    expect(
      find.text('Hold the mic and talk, or type a message.'),
      findsOneWidget,
    );
    expect(find.text('Hold to talk'), findsOneWidget);
    expect(find.byKey(const Key('push-to-talk')), findsOneWidget);
  });

  testWidgets('typing a message shows the exchange', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('message-field')), 'Hello');
    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Echo: Hello'), findsOneWidget);
    expect(find.text('Replies from mock'), findsOneWidget);
    expect(tts.spoken, ['Echo: Hello']);
    expect(
      find.text('Hold the mic and talk, or type a message.'),
      findsNothing,
    );
  });

  testWidgets('holding the mic sends the transcript', (tester) async {
    await pumpApp(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('push-to-talk'))),
    );
    await tester.pump();
    expect(find.text('Listening…'), findsOneWidget);
    expect(find.byKey(const Key('partial-transcript')), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('hello from the mic'), findsOneWidget);
    expect(find.text('Echo: hello from the mic'), findsOneWidget);
    expect(controller.phase, CompanionPhase.idle);
  });

  testWidgets('shows an error when the api fails', (tester) async {
    chat.error = ChatClientException('backend down');
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('message-field')), 'Hi');
    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error-text')), findsOneWidget);
    expect(find.text('backend down'), findsOneWidget);
    expect(find.text('Hi'), findsOneWidget);
  });

  testWidgets('settings save a backend url and toggle speech', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('backend-url-field')),
      'http://127.0.0.1:9999/',
    );
    await tester.tap(find.byKey(const Key('save-backend-url')));
    await tester.pumpAndSettle();

    expect(controller.settings.baseUrl, 'http://127.0.0.1:9999');
    expect(find.text('Settings'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('speak-replies-switch')));
    await tester.pumpAndSettle();
    expect(controller.speakReplies, isFalse);

    await tester.enterText(
      find.byKey(const Key('backend-url-field')),
      'not a url',
    );
    await tester.tap(find.byKey(const Key('save-backend-url')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a full http or https URL.'), findsOneWidget);
    expect(controller.settings.baseUrl, 'http://127.0.0.1:9999');
  });
}
