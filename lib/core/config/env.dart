/// Build-time environment configuration (from `--dart-define`, never hardcoded).
///
/// Offline demo (mock data, no sign-in):
/// ```
/// flutter run
/// ```
/// Against the FASAL Dart server (phone sign-in, real weather, synced data):
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # Android emulator → local server
/// flutter run --dart-define=API_BASE_URL=https://api.your-domain.com
/// ```
/// Secrets (weather keys, DB credentials) live on the server, never in the app.
abstract final class Env {
  /// Base URL of the FASAL API (without `/v1`). Must be HTTPS in production.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Mock repositories are used when no API URL is configured.
  static const bool useMockData = apiBaseUrl == '';

  static const Duration apiTimeout = Duration(seconds: 20);

  /// Simulated network delay for mock repositories so loading states are visible.
  static const Duration mockLatency = Duration(milliseconds: 350);

  static const String appVersion = '0.2.0 (Phase 2)';
}
