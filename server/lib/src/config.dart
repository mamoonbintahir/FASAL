import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';

final _log = Logger('config');

/// Server configuration from environment variables (see `.env.example`).
/// No secret has a hardcoded production value.
class Config {
  Config({
    this.port = 8080,
    this.host = '0.0.0.0',
    this.production = false,
    required this.jwtSecret,
    this.mongoUri,
    this.weatherProvider = 'openmeteo',
    this.corsOrigins = '*',
    this.tokenTtl = const Duration(days: 30),
    this.otpTtl = const Duration(minutes: 5),
    this.otpResendAfter = const Duration(seconds: 60),
    this.otpMaxAttempts = 5,
    this.weatherCacheTtl = const Duration(minutes: 30),
  });

  final int port;
  final String host;
  final bool production;
  final String jwtSecret;
  final String? mongoUri;
  final String weatherProvider;
  final String corsOrigins;
  final Duration tokenTtl;
  final Duration otpTtl;
  final Duration otpResendAfter;
  final int otpMaxAttempts;
  final Duration weatherCacheTtl;

  /// In development the OTP is returned in the API response so the app can be
  /// tested without an SMS provider. Never in production.
  bool get echoOtp => !production;

  factory Config.fromEnvironment([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    final production = (e['APP_ENV'] ?? 'development') == 'production';
    var secret = e['JWT_SECRET'] ?? '';
    if (secret.length < 32) {
      if (production) {
        throw StateError('JWT_SECRET must be set to at least 32 characters in production');
      }
      final r = Random.secure();
      secret = base64Url.encode(List<int>.generate(48, (_) => r.nextInt(256)));
      _log.warning('JWT_SECRET not set — using a random development secret (tokens reset on restart).');
    }
    final mongo = e['MONGODB_URI'];
    return Config(
      port: int.tryParse(e['PORT'] ?? '') ?? 8080,
      host: e['HOST'] ?? '0.0.0.0',
      production: production,
      jwtSecret: secret,
      mongoUri: (mongo == null || mongo.isEmpty) ? null : mongo,
      weatherProvider: e['WEATHER_PROVIDER'] ?? 'openmeteo',
      corsOrigins: e['CORS_ORIGINS'] ?? '*',
    );
  }
}
