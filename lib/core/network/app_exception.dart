/// Error types the UI understands. Repositories translate transport errors
/// (Dio, parsing, ...) into these so widgets never depend on Dio.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});
  final int? statusCode;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// The farmer has not set a district yet (weather needs a location).
class MissingLocationException extends AppException {
  const MissingLocationException([super.message = 'Location not set']);
}
