sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class ApiException extends AppException {
  const ApiException(
    super.message, {
    super.code,
    this.statusCode,
    this.retryAfterSeconds,
  });

  final int? statusCode;
  final int? retryAfterSeconds;

  bool get isAuthFailure =>
      statusCode == 401 ||
      code == 'AUTH_INVALID_TOKEN' ||
      code == 'AUTH_STALE_REFRESH' ||
      code == 'AUTH_UNAUTHORIZED';
}

class RefreshAmbiguousException extends AppException {
  const RefreshAmbiguousException()
    : super('Session ambiguë après actualisation.', code: 'AUTH_STALE_REFRESH');
}

class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.code});
}
