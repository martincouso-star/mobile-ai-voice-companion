import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_companion/services/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('memory store round-trips settings', () async {
    final store = MemorySettingsStore();
    expect(await store.readBackendUrl(), isNull);
    await store.writeBackendUrl('http://127.0.0.1:8080');
    await store.writeSpeakReplies(false);
    expect(await store.readBackendUrl(), 'http://127.0.0.1:8080');
    expect(await store.readSpeakReplies(), isFalse);
  });

  test('shared preferences store round-trips settings', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = SharedPrefsSettingsStore(
      await SharedPreferences.getInstance(),
    );
    expect(await store.readSpeakReplies(), isNull);
    await store.writeBackendUrl('http://10.0.2.2:8080');
    await store.writeSpeakReplies(true);

    final reloaded = SharedPrefsSettingsStore(
      await SharedPreferences.getInstance(),
    );
    expect(await reloaded.readBackendUrl(), 'http://10.0.2.2:8080');
    expect(await reloaded.readSpeakReplies(), isTrue);
  });
}
