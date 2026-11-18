import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'app_exception.dart';

/// Thin wrapper around Dio for the future REST backend (Phase 2).
///
/// - Attaches the auth token from secure storage.
/// - Maps Dio errors to [AppException] so the UI stays transport-agnostic.
/// Not used for live calls in Phase 1 (mock repositories are active).
class ApiClient {
  ApiClient({required SecureStorage secureStorage, Dio? dio})
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
      ),
    );
  }

  final Dio _dio;
  final SecureStorage _secure;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _guard(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) => _guard(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> put(String path, {Object? body}) => _guard(() => _dio.put<dynamic>(path, data: body));

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
        if (code == 401) return const UnauthorizedException();
        if (code == 404) return const NotFoundException();
        if (code == 422 || code == 400) return ValidationException(_messageFrom(e) ?? 'Invalid request');
        return ServerException(_messageFrom(e) ?? 'Server error', statusCode: code);
      default:
        return ServerException(e.message ?? 'Unexpected error');
    }
  }

  String? _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return null;
  }
}
