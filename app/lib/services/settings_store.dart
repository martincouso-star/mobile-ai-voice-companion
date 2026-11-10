import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the backend URL and whether replies are spoken.
abstract class SettingsStore {
  Future<String?> readBackendUrl();

  Future<void> writeBackendUrl(String url);

  Future<bool?> readSpeakReplies();

  Future<void> writeSpeakReplies(bool value);
}

class MemorySettingsStore implements SettingsStore {
  String? backendUrl;
  bool? speakReplies;

  @override
  Future<String?> readBackendUrl() async => backendUrl;

  @override
  Future<void> writeBackendUrl(String url) async {
    backendUrl = url;
  }

  @override
  Future<bool?> readSpeakReplies() async => speakReplies;

  @override
  Future<void> writeSpeakReplies(bool value) async {
    speakReplies = value;
  }
}

class SharedPrefsSettingsStore implements SettingsStore {
  SharedPrefsSettingsStore(this._prefs);

  static const backendUrlKey = 'backend_url';
  static const speakRepliesKey = 'speak_replies';

  final SharedPreferences _prefs;

  static Future<SharedPrefsSettingsStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsSettingsStore(prefs);
  }

  @override
  Future<String?> readBackendUrl() async => _prefs.getString(backendUrlKey);

  @override
  Future<void> writeBackendUrl(String url) async {
    await _prefs.setString(backendUrlKey, url);
  }

  @override
  Future<bool?> readSpeakReplies() async {
    if (!_prefs.containsKey(speakRepliesKey)) {
      return null;
    }
    return _prefs.getBool(speakRepliesKey);
  }

  @override
  Future<void> writeSpeakReplies(bool value) async {
    await _prefs.setBool(speakRepliesKey, value);
  }
}
