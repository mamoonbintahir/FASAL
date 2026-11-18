import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'app_exception.dart';

/// Thin wrapper around Dio for the FASAL Dart server.
///
/// - Attaches the session token from secure storage.
/// - Maps Dio errors to [AppException] so the UI stays transport-agnostic.
/// - Reports expired sessions through [onUnauthorized].
class ApiClient {
  ApiClient({required SecureStorage secureStorage, Dio? dio, this.onUnauthorized})
    : _secure = secureStorage,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: Env.apiTimeout,
              receiveTimeout: Env.apiTimeout,
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secure.readToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) onUnauthorized?.call();
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureStorage _secure;

  /// Called when the server rejects the session (the app returns to sign-in).
  final void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _guard(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) => _guard(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> put(String path, {Object? body}) => _guard(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) => _guard(() => _dio.patch<dynamic>(path, data: body));

  Future<dynamic> delete(String path) => _guard(() => _dio.delete<dynamic>(path));

  Future<dynamic> _guard(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  AppException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final message = _messageFrom(e);
        if (code == 401) return UnauthorizedException(message ?? 'Session expired');
        if (code == 404) return NotFoundException(message ?? 'Not found');
        if (code == 400 || code == 422 || code == 429) return ValidationException(message ?? 'Invalid request');
        return ServerException(message ?? 'Server error', statusCode: code);
      default:
        return ServerException(e.message ?? 'Unexpected error');
    }
  }

  /// Reads `{"error": {"message": ...}}` from FASAL server responses.
  String? _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['message'] is String) return err['message'] as String;
    }
    return null;
  }
}
