import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';

Dio createApiClient() {
  return Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );
}
