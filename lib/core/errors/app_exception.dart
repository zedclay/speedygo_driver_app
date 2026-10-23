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

  /// Confirmed authentication rejection. HTTP 401 alone is not enough —
  /// a transient refresh failure forwards the original 401.
  bool get isAuthFailure =>
      code == 'AUTH_INVALID_TOKEN' ||
      code == 'AUTH_SESSION_REVOKED' ||
      code == 'AUTH_SESSION_EXPIRED' ||
      code == 'AUTH_UNAUTHORIZED' ||
      code == 'AUTH_AUDIENCE_MISMATCH' ||
      code == 'AUTH_AUDIENCE_LEGACY_REJECTED' ||
      code == 'AUTH_APP_AUDIENCE_REQUIRED';

  bool get isPermissionDenied =>
      !isAuthFailure &&
      (statusCode == 403 ||
          code == 'AUTH_FORBIDDEN' ||
          code == 'AUTH_ACCOUNT_SUSPENDED' ||
          code == 'AUTH_ACCOUNT_DISABLED');
}

class RefreshAmbiguousException extends AppException {
  const RefreshAmbiguousException()
    : super('Session ambiguë après actualisation.', code: 'AUTH_STALE_REFRESH');
}

class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.code});
}
