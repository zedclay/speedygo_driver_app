class AppConstants {
  AppConstants._();

  static const String appName = 'SpeedyGo Driver';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
}
