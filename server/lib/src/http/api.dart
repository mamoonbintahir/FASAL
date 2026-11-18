import 'dart:convert';

import 'package:shelf/shelf.dart';

/// An error the API reports to clients as `{"error": {"code", "message"}}`.
class ApiError implements Exception {
  const ApiError(this.status, this.code, this.message);

  final int status;
  final String code;
  final String message;

  factory ApiError.badRequest(String message, {String code = 'bad_request'}) => ApiError(400, code, message);
  factory ApiError.unauthorized([String message = 'Sign in required']) => ApiError(401, 'unauthorized', message);
  factory ApiError.notFound([String message = 'Not found']) => ApiError(404, 'not_found', message);
  factory ApiError.tooMany(String message) => ApiError(429, 'too_many_requests', message);

  @override
  String toString() => 'ApiError($status, $code, $message)';
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonResponse(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

Response errorResponse(ApiError e) => jsonResponse({
  'error': {'code': e.code, 'message': e.message},
}, status: e.status);

const int maxBodyBytes = 64 * 1024;

/// Reads a JSON object body (max 64 KB).
Future<Map<String, dynamic>> readJson(Request request) async {
  final length = request.contentLength;
  if (length != null && length > maxBodyBytes) {
    throw const ApiError(413, 'payload_too_large', 'Request body is too large');
  }
  final raw = await request.readAsString();
  if (raw.length > maxBodyBytes) throw const ApiError(413, 'payload_too_large', 'Request body is too large');
  if (raw.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    // fall through
  }
  throw ApiError.badRequest('Body must be a JSON object', code: 'invalid_json');
}

/// Typed field access with clear validation errors.
extension JsonFields on Map<String, dynamic> {
  String reqString(String key, {int max = 200}) {
    final v = this[key];
    if (v is! String || v.trim().isEmpty) throw ApiError.badRequest('"$key" is required', code: 'validation');
    if (v.length > max) throw ApiError.badRequest('"$key" is too long', code: 'validation');
    return v.trim();
  }

  String optString(String key, {int max = 200}) {
    final v = this[key];
    if (v == null) return '';
    if (v is! String) throw ApiError.badRequest('"$key" must be text', code: 'validation');
    if (v.length > max) throw ApiError.badRequest('"$key" is too long', code: 'validation');
    return v.trim();
  }

  double reqNumber(String key, {double min = 0, double max = double.infinity, bool exclusiveMin = true}) {
    final v = this[key];
    if (v is! num) throw ApiError.badRequest('"$key" must be a number', code: 'validation');
    final d = v.toDouble();
    if ((exclusiveMin ? d <= min : d < min) || d > max) {
      throw ApiError.badRequest('"$key" is out of range', code: 'validation');
    }
    return d;
  }

  DateTime reqDate(String key) {
    final v = this[key];
    final d = v is String ? DateTime.tryParse(v) : null;
    if (d == null) throw ApiError.badRequest('"$key" must be an ISO date', code: 'validation');
    return d;
  }

  Map<String, dynamic> reqObject(String key) {
    final v = this[key];
    if (v is! Map<String, dynamic>) throw ApiError.badRequest('"$key" must be an object', code: 'validation');
    return v;
  }
}
