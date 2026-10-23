import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';

/// Pure routing decision for the onboarding funnel, derived only from the
/// server's `/driver/me` flags (no local state, no invented statuses).
String onboardingRouteFor(DriverMe? me) {
  if (me == null || !me.driverProfileExists || !me.profileComplete) {
    return AppRoutes.onboardingProfile;
  }
  switch (me.verificationStatus) {
    case 'APPROVED':
      return AppRoutes.onboardingApproved;
    case 'PENDING_REVIEW':
      return AppRoutes.onboardingPending;
    case 'REJECTED':
      return AppRoutes.onboardingCorrections;
  }
  return nextIncompleteStepRoute(me);
}

/// First incomplete editable step (license is always required by the backend).
String nextIncompleteStepRoute(DriverMe me) {
  if (!me.identityDocumentComplete) return AppRoutes.onboardingIdentity;
  if (!me.drivingLicenseComplete) return AppRoutes.onboardingLicense;
  if (!me.vehicleComplete) return AppRoutes.onboardingVehicle;
  return AppRoutes.onboardingReview;
}

bool canSubmitVerification(DriverMe me) =>
    me.driverProfileExists &&
    me.profileComplete &&
    me.identityDocumentComplete &&
    me.drivingLicenseComplete &&
    me.vehicleComplete &&
    me.isOnboardingEditable;

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// True for a well-formed YYYY-MM-DD that is today or later (server re-checks).
bool isFutureIsoDate(String value, {DateTime? now}) {
  if (!_isoDate.hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return false;
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  return !parsed.isBefore(today);
}
