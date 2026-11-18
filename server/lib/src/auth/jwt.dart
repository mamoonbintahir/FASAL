import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Minimal HS256 JSON Web Tokens (sign + verify). Kept small and dependency-
/// free so it is easy to audit; only the HS256 algorithm is accepted.
class Jwt {
  Jwt(String secret) : _key = utf8.encode(secret);

  final List<int> _key;

  static const _header = {'alg': 'HS256', 'typ': 'JWT'};

  String sign(Map<String, dynamic> claims, {required Duration ttl, DateTime? now}) {
    final issued = (now ?? DateTime.now()).toUtc();
    final payload = {
      ...claims,
      'iat': issued.millisecondsSinceEpoch ~/ 1000,
      'exp': issued.add(ttl).millisecondsSinceEpoch ~/ 1000,
    };
    final head = _b64(utf8.encode(jsonEncode(_header)));
    final body = _b64(utf8.encode(jsonEncode(payload)));
    return '$head.$body.${_b64(_mac('$head.$body'))}';
  }

  /// Returns the claims, or null if the token is malformed, forged or expired.
  Map<String, dynamic>? verify(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final header = jsonDecode(utf8.decode(_unb64(parts[0])));
      if (header is! Map || header['alg'] != 'HS256') return null;
      if (!_constantTimeEquals(_unb64(parts[2]), _mac('${parts[0]}.${parts[1]}'))) return null;
      final claims = jsonDecode(utf8.decode(_unb64(parts[1])));
      if (claims is! Map<String, dynamic>) return null;
      final exp = claims['exp'];
      final nowSec = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000;
      if (exp is! int || exp <= nowSec) return null;
      return claims;
    } catch (_) {
      return null;
    }
  }

  List<int> _mac(String input) => Hmac(sha256, _key).convert(utf8.encode(input)).bytes;

  static String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  static List<int> _unb64(String s) => base64Url.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

bool constantTimeStringEquals(String a, String b) => _constantTimeEquals(utf8.encode(a), utf8.encode(b));
