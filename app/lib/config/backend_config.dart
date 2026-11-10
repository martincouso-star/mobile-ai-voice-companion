/// Backend URL parsing and the compile-time default.
class BackendConfig {
  /// Android emulator alias for the host machine's loopback interface.
  static const fallbackUrl = 'http://10.0.2.2:8080';

  /// `BACKEND_URL` from `--dart-define`, or [fallbackUrl] when that is unset
  /// or not an absolute http(s) URL.
  static String fromEnvironment() {
    const defined = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: fallbackUrl,
    );
    return normalize(defined) ?? fallbackUrl;
  }

  /// Returns a URL without a trailing slash, or null when [raw] is unusable.
  static String? normalize(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }
    return trimmed;
  }
}
