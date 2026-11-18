import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fasal_core/models.dart' show normalizePkPhone;
import 'package:logging/logging.dart';

import '../config.dart';
import '../http/api.dart';
import '../store/database.dart';
import 'jwt.dart';

final _log = Logger('auth');

/// Sends the OTP text message. Plug in an SMS gateway (e.g. Twilio, a local
/// Pakistani aggregator) by implementing this; the default only logs.
abstract interface class SmsSender {
  Future<void> send(String phone, String message);
}

class LoggingSmsSender implements SmsSender {
  @override
  Future<void> send(String phone, String message) async =>
      _log.info('SMS to ${phone.substring(0, 6)}***: (not sent — no SMS provider configured)');
}

class OtpResult {
  const OtpResult({required this.phone, this.devCode});
  final String phone;
  final String? devCode;
}

class AuthSession {
  const AuthSession({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
}

/// One-time-password sign-in. Codes are stored hashed, expire after 5
/// minutes, allow 5 attempts and can be re-sent after 60 seconds.
class OtpService {
  OtpService({required this.db, required this.config, required this.sms, required this.jwt, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Database db;
  final Config config;
  final SmsSender sms;
  final Jwt jwt;
  final DateTime Function() _now;
  final Random _random = Random.secure();

  DocCollection get _otps => db.collection('otps');
  DocCollection get _users => db.collection('users');

  String _hash(String phone, String code) => sha256.convert(utf8.encode('${config.jwtSecret}|$phone|$code')).toString();

  Future<OtpResult> request(String rawPhone) async {
    final phone = normalizePkPhone(rawPhone);
    if (phone == null) throw ApiError.badRequest('Enter a valid Pakistani mobile number', code: 'invalid_phone');
    final now = _now();
    final existing = await _otps.findOne({'id': phone});
    if (existing != null) {
      final sent = DateTime.parse(existing['sentAt'] as String);
      if (now.difference(sent) < config.otpResendAfter) {
        throw ApiError.tooMany('Please wait a minute before requesting another code');
      }
    }
    final code = (_random.nextInt(900000) + 100000).toString();
    await _otps.put({
      'id': phone,
      'hash': _hash(phone, code),
      'sentAt': now.toIso8601String(),
      'expiresAt': now.add(config.otpTtl).toIso8601String(),
      'attempts': 0,
    });
    await sms.send(phone, 'Fasal code: $code. It expires in 5 minutes. Do not share it.');
    return OtpResult(phone: phone, devCode: config.echoOtp ? code : null);
  }

  Future<AuthSession> verify(String rawPhone, String code) async {
    final phone = normalizePkPhone(rawPhone);
    if (phone == null) throw ApiError.badRequest('Enter a valid Pakistani mobile number', code: 'invalid_phone');
    final otp = await _otps.findOne({'id': phone});
    if (otp == null || _now().isAfter(DateTime.parse(otp['expiresAt'] as String))) {
      throw ApiError.badRequest('The code has expired. Request a new one.', code: 'otp_expired');
    }
    final attempts = (otp['attempts'] as num).toInt();
    if (attempts >= config.otpMaxAttempts) {
      throw ApiError.tooMany('Too many wrong codes. Request a new one.');
    }
    if (!constantTimeStringEquals(_hash(phone, code.trim()), otp['hash'] as String)) {
      await _otps.put({...otp, 'attempts': attempts + 1});
      throw ApiError.badRequest('That code is not correct', code: 'otp_invalid');
    }
    await _otps.delete({'id': phone});

    var user = await _users.findOne({'phone': phone});
    if (user == null) {
      user = {
        'id': 'u_${_now().microsecondsSinceEpoch}_${_random.nextInt(1 << 20)}',
        'phone': phone,
        'createdAt': _now().toIso8601String(),
      };
      await _users.put(user);
    }
    final token = jwt.sign({'sub': user['id'], 'phone': phone}, ttl: config.tokenTtl, now: _now());
    return AuthSession(token: token, user: user);
  }
}

/// Simple fixed-window rate limiter (per key, e.g. client IP).
class RateLimiter {
  RateLimiter({required this.limit, required this.window, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final int limit;
  final Duration window;
  final DateTime Function() _now;
  final Map<String, (DateTime, int)> _hits = {};

  bool allow(String key) {
    final now = _now();
    final entry = _hits[key];
    if (entry == null || now.difference(entry.$1) >= window) {
      _hits[key] = (now, 1);
      if (_hits.length > 10000) _hits.removeWhere((_, v) => now.difference(v.$1) >= window);
      return true;
    }
    if (entry.$2 >= limit) return false;
    _hits[key] = (entry.$1, entry.$2 + 1);
    return true;
  }
}
