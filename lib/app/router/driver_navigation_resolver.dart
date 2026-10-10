import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';

/// Verified Driver verification statuses from Backend `DriverProfile.verificationStatus`.
abstract final class DriverVerificationStatuses {
  static const approved = 'APPROVED';
  static const pendingReview = 'PENDING_REVIEW';
  static const rejected = 'REJECTED';
  static const unverified = 'UNVERIFIED';
  static const suspended = 'SUSPENDED';
}

/// Account statuses from `GET /auth/me` → `account.status`.
abstract final class AccountStatuses {
  static const active = 'ACTIVE';
  static const suspended = 'SUSPENDED';
  static const inactive = 'INACTIVE';
}

/// Snapshot used by GoRouter redirects after session + `/driver/me` resolution.
class DriverNavSnapshot {
  const DriverNavSnapshot({
    required this.sessionStatus,
    this.accountStatus,
    this.driverMe,
    this.hasActiveDelivery = false,
    this.resolved = false,
  });

  final SessionStatus sessionStatus;
  final String? accountStatus;
  final DriverMe? driverMe;
  final bool hasActiveDelivery;

  /// True once cold-start / post-OTP bootstrap finished for the current session.
  final bool resolved;

  bool get isApproved =>
      driverMe?.verificationStatus == DriverVerificationStatuses.approved ||
      driverMe?.verificationApproved == true;

  bool get isPendingReview =>
      driverMe?.verificationStatus == DriverVerificationStatuses.pendingReview;

  bool get isRejected =>
      driverMe?.verificationStatus == DriverVerificationStatuses.rejected;

  bool get isSuspendedDriver =>
      driverMe?.verificationStatus == DriverVerificationStatuses.suspended ||
      driverMe?.availability?.isSuspended == true;

  bool get isBlockedAccount =>
      accountStatus == AccountStatuses.suspended ||
      accountStatus == AccountStatuses.inactive;

  /// Destination after Splash / OTP / session restore (replace navigation).
  String get coldStartDestination => resolveColdStartDestination(
    sessionStatus: sessionStatus,
    accountStatus: accountStatus,
    driverMe: driverMe,
    hasActiveDelivery: hasActiveDelivery,
  );
}

/// Pure cold-start / post-auth destination. Does not invent statuses.
String resolveColdStartDestination({
  required SessionStatus sessionStatus,
  String? accountStatus,
  DriverMe? driverMe,
  bool hasActiveDelivery = false,
}) {
  switch (sessionStatus) {
    case SessionStatus.unknown:
      return AppRoutes.splash;
    case SessionStatus.signedOut:
      return AppRoutes.phone;
    case SessionStatus.needsDriverProfile:
      return AppRoutes.onboardingProfile;
    case SessionStatus.signedIn:
      break;
  }

  if (accountStatus == AccountStatuses.suspended ||
      accountStatus == AccountStatuses.inactive) {
    // Honest support surface — no approved shell.
    return AppRoutes.support;
  }

  final me = driverMe;
  if (me == null) {
    // Still resolving DriverMe — stay on splash until bootstrap completes.
    return AppRoutes.splash;
  }

  final status = me.verificationStatus;
  switch (status) {
    case DriverVerificationStatuses.approved:
      if (hasActiveDelivery) return AppRoutes.currentDelivery;
      return AppRoutes.home;
    case DriverVerificationStatuses.pendingReview:
      return AppRoutes.onboardingPending;
    case DriverVerificationStatuses.rejected:
      return AppRoutes.onboardingCorrections;
    case DriverVerificationStatuses.suspended:
      // Approved shell is wrong; home shows operational blocks via /driver/me.
      return AppRoutes.home;
    case DriverVerificationStatuses.unverified:
    case null:
    default:
      if (!me.driverProfileExists || !me.profileComplete) {
        return AppRoutes.onboardingProfile;
      }
      return nextIncompleteStepRoute(me);
  }
}

bool _isAuthRoute(String loc) =>
    loc == AppRoutes.phone || loc == AppRoutes.otp || loc == AppRoutes.splash;

bool _isWelcomeIntroRoute(String loc) => loc == AppRoutes.welcomeIntro;

bool _isLanguageRoute(String loc) => loc == AppRoutes.languageSettings;

bool _isOnboardingRoute(String loc) => loc.startsWith('/onboarding');

bool _isPendingAllowed(String loc) =>
    loc == AppRoutes.onboardingPending ||
    loc == AppRoutes.onboardingApproved ||
    _isLanguageRoute(loc) ||
    loc == AppRoutes.support ||
    loc.startsWith('${AppRoutes.supportDetail}/');

bool _isRejectedAllowed(String loc) =>
    _isOnboardingRoute(loc) ||
    _isLanguageRoute(loc) ||
    loc == AppRoutes.support ||
    loc.startsWith('${AppRoutes.supportDetail}/');

bool _isEditableOnboarding(String loc) =>
    loc == AppRoutes.onboardingProfile ||
    loc == AppRoutes.onboardingIdentity ||
    loc == AppRoutes.onboardingLicense ||
    loc == AppRoutes.onboardingVehicle ||
    loc == AppRoutes.onboardingReview ||
    loc == AppRoutes.onboardingCorrections;

/// GoRouter redirect. Prefer [snapshot] once bootstrap has resolved DriverMe.
///
/// [introCompleted] gates the first-launch product intro (`/welcome-intro`).
/// Default `true` preserves callers that only exercise business-state lanes.
String? driverRedirect({
  required SessionStatus status,
  required String loc,
  DriverNavSnapshot? snapshot,
  bool introCompleted = true,
}) {
  if (status == SessionStatus.unknown) {
    if (loc != AppRoutes.splash && !_isLanguageRoute(loc)) {
      return AppRoutes.splash;
    }
    return null;
  }

  // Splash owns brand hold + outbound `context.go`. Never yank it away via
  // redirect when session restores mid-hold (that made the splash a flash).
  if (loc == AppRoutes.splash) {
    return null;
  }

  // First-launch intro gate (after Splash local restore; before resolver dest).
  if (!introCompleted) {
    if (_isWelcomeIntroRoute(loc) || _isLanguageRoute(loc)) {
      return null;
    }
    return AppRoutes.welcomeIntro;
  }

  if (_isWelcomeIntroRoute(loc)) {
    // Intro already completed — do not remain on the gate.
    if (snapshot?.resolved == true) {
      final destination = snapshot!.coldStartDestination;
      return destination == AppRoutes.splash ? AppRoutes.phone : destination;
    }
    return AppRoutes.splash;
  }

  if (status == SessionStatus.signedOut) {
    if (_isAuthRoute(loc) || _isLanguageRoute(loc)) {
      return null;
    }
    return AppRoutes.phone;
  }

  if (status == SessionStatus.needsDriverProfile) {
    if (_isOnboardingRoute(loc) || _isLanguageRoute(loc)) return null;
    return AppRoutes.onboardingProfile;
  }

  // signedIn
  final snap = snapshot;
  final resolved = snap?.resolved == true;

  if (loc == AppRoutes.phone || loc == AppRoutes.otp) {
    // OTP/phone submit paths call bootstrap then `context.go`.
    // Once resolved, bounce auth routes to the lane destination.
    if (!resolved) return null;
    return snap!.coldStartDestination;
  }

  // Before bootstrap: do not yank shell/onboarding to splash (widget tests and
  // mid-session). After bootstrap: enforce verification lanes.
  if (!resolved || snap == null) {
    return null;
  }

  final me = snap.driverMe;
  final verification = me?.verificationStatus;

  if (snap.isBlockedAccount) {
    if (loc == AppRoutes.support ||
        loc.startsWith('${AppRoutes.supportDetail}/') ||
        _isLanguageRoute(loc)) {
      return null;
    }
    return AppRoutes.support;
  }

  if (verification == DriverVerificationStatuses.pendingReview) {
    if (_isPendingAllowed(loc)) return null;
    return AppRoutes.onboardingPending;
  }

  if (verification == DriverVerificationStatuses.rejected) {
    if (_isRejectedAllowed(loc)) return null;
    return AppRoutes.onboardingCorrections;
  }

  if (verification == DriverVerificationStatuses.unverified ||
      verification == null) {
    if (_isOnboardingRoute(loc) || _isLanguageRoute(loc)) return null;
    return onboardingRouteFor(me);
  }

  // APPROVED (or suspended operational — shell/home allowed)
  if (snap.isApproved || verification == DriverVerificationStatuses.suspended) {
    // Do not re-enter editable onboarding after approval.
    if (_isEditableOnboarding(loc)) {
      return snap.hasActiveDelivery
          ? AppRoutes.currentDelivery
          : AppRoutes.home;
    }
    // One-shot approved celebration is allowed; pending is not for approved.
    if (loc == AppRoutes.onboardingPending) {
      return AppRoutes.home;
    }
    return null;
  }

  return null;
}

/// Back behavior for active delivery: leave to Home (replace), never prior offer.
String deliveryBackDestination({required bool isDelivered}) {
  return AppRoutes.home;
}

/// Whether a blocked contextual screen may be opened from delivery help.
bool isBlockedContextualRoute(String loc) =>
    loc.startsWith('${AppRoutes.blockedUnavailable}/');
