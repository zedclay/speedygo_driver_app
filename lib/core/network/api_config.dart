import 'package:speedygo_driver_app/core/constants/app_constants.dart';

class ApiConfig {
  const ApiConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  factory ApiConfig.fromEnvironment() {
    return const ApiConfig(apiBaseUrl: AppConstants.apiBaseUrl);
  }
}
