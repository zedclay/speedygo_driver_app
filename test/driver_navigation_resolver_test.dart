import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/router/driver_navigation_resolver.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';

DriverMe _me({
  String? verificationStatus = 'APPROVED',
  bool profileComplete = true,
  bool identity = true,
  bool license = true,
  bool vehicle = true,
  bool driverProfileExists = true,
  bool verificationApproved = false,
}) {
  return DriverMe(
    driverProfileExists: driverProfileExists,
    profileComplete: profileComplete,
    identityDocumentComplete: identity,
    drivingLicenseComplete: license,
    vehicleComplete: vehicle,
    verificationSubmitted:
        verificationStatus == 'PENDING_REVIEW' ||
        verificationStatus == 'APPROVED',
    verificationApproved:
        verificationApproved || verificationStatus == 'APPROVED',
    operationalReady: verificationStatus == 'APPROVED',
    matchingEligible: verificationStatus == 'APPROVED',
    availability: const DriverAvailabilityInfo(
      status: 'OFFLINE',
      offlineAfterCurrentDelivery: false,
      updatedAt: '',
    ),
    verificationStatus: verificationStatus,
  );
}

DriverNavSnapshot _snap({
  SessionStatus session = SessionStatus.signedIn,
  DriverMe? me,
  bool hasActiveDelivery = false,
  String? accountStatus = 'ACTIVE',
  bool resolved = true,
}) {
  return DriverNavSnapshot(
    sessionStatus: session,
    accountStatus: accountStatus,
    driverMe: me,
    hasActiveDelivery: hasActiveDelivery,
    resolved: resolved,
  );
}

void main() {
  group('resolveColdStartDestination', () {
    test('no session → phone', () {
      expect(
        resolveColdStartDestination(sessionStatus: SessionStatus.signedOut),
        AppRoutes.phone,
      );
    });

    test('unknown → splash', () {
      expect(
        resolveColdStartDestination(sessionStatus: SessionStatus.unknown),
        AppRoutes.splash,
      );
    });

    test('needs profile → onboarding profile', () {
      expect(
        resolveColdStartDestination(
          sessionStatus: SessionStatus.needsDriverProfile,
        ),
        AppRoutes.onboardingProfile,
      );
    });

    test('approved without delivery → home', () {
      expect(
        resolveColdStartDestination(
          sessionStatus: SessionStatus.signedIn,
          driverMe: _me(),
        ),
        AppRoutes.home,
      );
    });

    test('approved with active delivery → current delivery', () {
      expect(
        resolveColdStartDestination(
          sessionStatus: SessionStatus.signedIn,
          driverMe: _me(),
          hasActiveDelivery: true,
        ),
        AppRoutes.currentDelivery,
      );
    });

    test('pending review → pending', () {
      expect(
        resolveColdStartDestination(
          sessionStatus: SessionStatus.signedIn,
          driverMe: _me(verificationStatus: 'PENDING_REVIEW'),
        ),
        AppRoutes.onboardingPending,
      );
    });

    test('rejected → corrections', () {
      expect(
        resolveColdStartDestination(
          sessionStatus: SessionStatus.signedIn,
          driverMe: _me(verificationStatus: 'REJECTED'),
        ),
        AppRoutes.onboardingCorrections,
      );
    });

    test('incomplete identity → identity step', () {
      expect(
        resolveColdStartDestination(
          sessionStatus: SessionStatus.signedIn,
          driverMe: _me(
            verificationStatus: 'UNVERIFIED',
            identity: false,
            license: false,
            vehicle: false,
          ),
        ),
        AppRoutes.onboardingIdentity,
      );
    });

    test('suspended account → support', () {
      expect(
        resolveColdStartDestination(
          sessionStatus: SessionStatus.signedIn,
          accountStatus: 'SUSPENDED',
          driverMe: _me(),
        ),
        AppRoutes.support,
      );
    });
  });

  group('driverRedirect guards', () {
    test('cold start without session → splash', () {
      expect(
        driverRedirect(status: SessionStatus.unknown, loc: AppRoutes.home),
        AppRoutes.splash,
      );
    });

    test('signed out leaves splash to SplashScreen brand hold', () {
      expect(
        driverRedirect(status: SessionStatus.signedOut, loc: AppRoutes.splash),
        isNull,
      );
    });

    test('signed out blocked from shell', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedOut,
          loc: AppRoutes.currentDelivery,
        ),
        AppRoutes.phone,
      );
    });

    test('approved resolved leaves auth routes for home', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.phone,
          snapshot: _snap(me: _me()),
        ),
        AppRoutes.home,
      );
    });

    test('approved with delivery leaves otp for delivery', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.otp,
          snapshot: _snap(me: _me(), hasActiveDelivery: true),
        ),
        AppRoutes.currentDelivery,
      );
    });

    test('pending cannot enter shell', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.home,
          snapshot: _snap(me: _me(verificationStatus: 'PENDING_REVIEW')),
        ),
        AppRoutes.onboardingPending,
      );
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.earnings,
          snapshot: _snap(me: _me(verificationStatus: 'PENDING_REVIEW')),
        ),
        AppRoutes.onboardingPending,
      );
    });

    test('pending may stay on pending and language', () {
      final snap = _snap(me: _me(verificationStatus: 'PENDING_REVIEW'));
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.onboardingPending,
          snapshot: snap,
        ),
        isNull,
      );
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.languageSettings,
          snapshot: snap,
        ),
        isNull,
      );
    });

    test('rejected cannot enter delivery', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.currentDelivery,
          snapshot: _snap(me: _me(verificationStatus: 'REJECTED')),
        ),
        AppRoutes.onboardingCorrections,
      );
    });

    test('approved cannot reopen editable onboarding', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.onboardingProfile,
          snapshot: _snap(me: _me()),
        ),
        AppRoutes.home,
      );
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.onboardingReview,
          snapshot: _snap(me: _me(), hasActiveDelivery: true),
        ),
        AppRoutes.currentDelivery,
      );
    });

    test('approved may use shell and delivery', () {
      final snap = _snap(me: _me());
      for (final loc in [
        ...AppRoutes.shellBranches,
        AppRoutes.currentDelivery,
        AppRoutes.notifications,
        AppRoutes.support,
      ]) {
        expect(
          driverRedirect(
            status: SessionStatus.signedIn,
            loc: loc,
            snapshot: snap,
          ),
          isNull,
        );
      }
    });

    test('blocked contextual routes stay nested under delivery parent', () {
      expect(
        isBlockedContextualRoute(AppRoutes.blockedFor(BlockedKind.contact)),
        isTrue,
      );
      expect(
        isBlockedContextualRoute(AppRoutes.blockedFor(BlockedKind.deliveryPin)),
        isTrue,
      );
    });

    test('delivery back always returns home', () {
      expect(deliveryBackDestination(isDelivered: false), AppRoutes.home);
      expect(deliveryBackDestination(isDelivered: true), AppRoutes.home);
    });

    test('unresolved signedIn does not flash-redirect shell', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.home,
          snapshot: _snap(me: _me(), resolved: false),
        ),
        isNull,
      );
    });
  });
}
