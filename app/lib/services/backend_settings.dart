import 'package:flutter/foundation.dart';

import '../config/backend_config.dart';

/// The API base URL the chat client reads on each request.
class BackendSettings extends ChangeNotifier {
  BackendSettings(String baseUrl)
    : _baseUrl = BackendConfig.normalize(baseUrl) ?? BackendConfig.fallbackUrl;

  String _baseUrl;

  String get baseUrl => _baseUrl;

  void update(String url) {
    final normalized = BackendConfig.normalize(url);
    if (normalized == null) {
      throw ArgumentError.value(url, 'url', 'Expected an absolute http(s) URL');
    }
    if (_baseUrl == normalized) {
      return;
    }
    _baseUrl = normalized;
    notifyListeners();
  }
}
