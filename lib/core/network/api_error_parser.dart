import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';

AppException mapDioError(Object error) {
  if (error is AppException) return error;
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(AppStrings.networkError, code: 'NETWORK');
    }
    final data = error.response?.data;
    String? code;
    String? message;
    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        code = err['code']?.toString();
        message = err['message']?.toString();
      }
    }
    final mapped = AppStrings.errorForCode(code);
    return ApiException(
      message != null && message.isNotEmpty && code == null ? message : mapped,
      code: code,
      statusCode: error.response?.statusCode,
    );
  }
  return UnexpectedException(error.toString());
}
