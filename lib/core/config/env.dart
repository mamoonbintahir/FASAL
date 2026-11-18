/// Build-time environment configuration.
///
/// Values come from `--dart-define`, so no URLs or keys are hardcoded:
///
/// ```
/// flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=https://api.example.com/v1
/// ```
///
/// Secrets (API keys for weather etc.) must live on the backend, never in the app.
abstract final class Env {
  /// Phase 1 runs entirely on mock repositories.
  static const bool useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

  /// Base URL of the future Node.js/Express REST API. Must be HTTPS in production.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const Duration apiTimeout = Duration(seconds: 20);

  /// Simulated network delay for mock repositories so loading states are visible.
  static const Duration mockLatency = Duration(milliseconds: 350);

  static const String appVersion = '0.1.0 (Phase 1 – frontend demo)';
}
