import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';

class DriverNotificationDestination {
  const DriverNotificationDestination._(this.location);

  const DriverNotificationDestination.none() : location = null;

  final String? location;

  bool get canOpen => location != null && location!.isNotEmpty;
}

/// Inbox tap destinations only. Opening the list never navigates and never
/// mutates availability, assignment, delivery, or location.
DriverNotificationDestination resolveDriverNotificationDestination(
  AppNotification item,
) {
  switch (item.type) {
    case 'MATCH_OFFER':
      return const DriverNotificationDestination._(AppRoutes.home);
    case 'DRIVER_EARNING_CREATED':
      return const DriverNotificationDestination._(AppRoutes.earnings);
    default:
      return const DriverNotificationDestination.none();
  }
}
