class AppConstants {
  AppConstants._();

  static const String appName = 'SpeedyGo Driver';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api/v1',
  );

  /// Design reference viewport (Android-first).
  static const double designWidth = 390;
  static const double designHeight = 844;
}

class ApiEndpoints {
  ApiEndpoints._();

  static const otpRequestPath = '/auth/otp/request';
  static const otpVerifyPath = '/auth/otp/verify';
  static const refreshPath = '/auth/refresh';
  static const logoutPath = '/auth/logout';
  static const mePath = '/auth/me';
  static const driverMePath = '/driver/me';
  static const driverGoOnlinePath = '/driver/availability/go-online';
  static const driverGoOfflinePath = '/driver/availability/go-offline';
  static const driverLocationPath = '/driver/location';
  static const driverCurrentOfferPath = '/driver/assignments/current-offer';
  static String driverAcceptOfferPath(String assignmentId) =>
      '/driver/assignments/$assignmentId/accept';
  static String driverRejectOfferPath(String assignmentId) =>
      '/driver/assignments/$assignmentId/reject';
  static const currentDeliveryPath = '/driver/deliveries/current';
  static const confirmPickupPath = '/driver/deliveries/current/confirm-pickup';
}

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const home = '/home';
  static const currentDelivery = '/delivery/current';
  static const languageSettings = '/settings/language';
}
