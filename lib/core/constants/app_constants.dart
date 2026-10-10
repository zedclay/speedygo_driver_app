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

  // --- Driver profile / onboarding (backend DriverController) ---
  static const driverProfilePath = '/driver/profile';
  static String driverDocumentsContentPath(String type) =>
      '/driver/documents/$type/content';
  static String driverDocumentsPath(String type) => '/driver/documents/$type';
  static const driverVehiclesPath = '/driver/vehicles';
  static String driverVehiclePath(String id) => '/driver/vehicles/$id';
  static const driverVerificationSubmitPath = '/driver/verification/submit';

  // --- Delivery lifecycle actions ---
  static const driverStartToPickupPath =
      '/driver/deliveries/current/start-to-pickup';
  static const driverArrivePickupPath =
      '/driver/deliveries/current/arrive-pickup';
  static const driverStartDeliveryPath =
      '/driver/deliveries/current/start-delivery';
  static const driverArriveCustomerPath =
      '/driver/deliveries/current/arrive-customer';
  static const driverCompleteDeliveryPath =
      '/driver/deliveries/current/complete-delivery';
  static const driverCollectCodPath = '/driver/deliveries/current/collect-cod';

  // --- History / earnings / COD / ratings ---
  static const driverHistoryPath = '/driver/deliveries/history';
  static String driverHistoryDetailPath(String id) =>
      '/driver/deliveries/history/$id';
  static const driverEarningsSummaryPath = '/driver/earnings/summary';
  static const driverEarningsPath = '/driver/earnings';
  static const driverCodSummaryPath = '/driver/cod/summary';
  static const driverCodRemittancesPath = '/driver/cod/remittances';
  static const driverRatingsSummaryPath = '/driver/ratings/summary';

  // --- Support ---
  static const driverSupportPath = '/driver/support';
  static String driverSupportDetailPath(String id) => '/driver/support/$id';
  static String driverSupportMessagesPath(String id) =>
      '/driver/support/$id/messages';

  // --- Notifications (account-scoped inbox) ---
  static const notificationsPath = '/notifications';
  static const notificationsUnreadCountPath = '/notifications/unread-count';
  static String notificationReadPath(String id) => '/notifications/$id/read';
  static const notificationsReadAllPath = '/notifications/read-all';

  static const driverCurrentAssignmentPath = '/driver/assignments/current';
}

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcomeIntro = '/welcome-intro';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const home = '/home';
  static const currentDelivery = '/delivery/current';
  static const languageSettings = '/settings/language';

  // Shell branches
  static const history = '/history';
  static const earnings = '/earnings';
  static const profile = '/profile';

  // Pushed routes (outside shell)
  static const historyDetail = '/history/detail';
  static const vehicle = '/profile/vehicle';
  static const vehicleEdit = '/profile/vehicle/edit';
  static const documents = '/profile/documents';
  static const ratings = '/profile/ratings';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const support = '/support';
  static const supportDetail = '/support/detail';
  static const blockedUnavailable = '/blocked';

  // Onboarding
  static const onboardingProfile = '/onboarding/profile';
  static const onboardingIdentity = '/onboarding/identity';
  static const onboardingLicense = '/onboarding/license';
  static const onboardingVehicle = '/onboarding/vehicle';
  static const onboardingReview = '/onboarding/review';
  static const onboardingPending = '/onboarding/pending';
  static const onboardingApproved = '/onboarding/approved';
  static const onboardingCorrections = '/onboarding/corrections';

  static const shellBranches = <String>[home, history, earnings, profile];

  static String blockedFor(String kind) => '$blockedUnavailable/$kind';
  static String historyDetailFor(String id) => '$historyDetail/$id';
  static String supportDetailFor(String id) => '$supportDetail/$id';
}

/// Kinds of honest "not available" screens (see BlockedUnavailableScreen).
class BlockedKind {
  BlockedKind._();

  static const contact = 'contact';
  static const failureReport = 'failure-report';
  static const deliveryPin = 'delivery-pin';
  static const maps = 'maps';
  static const notificationPrefs = 'notification-prefs';
}
