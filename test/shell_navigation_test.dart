import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/app/router/app_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_api.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';
import 'package:speedygo_driver_app/features/history/data/history_api.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

class _SignedInSession extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.signedIn);

  @override
  Future<void> restore() async {}
}

DriverMe _me() => const DriverMe(
  driverProfileExists: true,
  profileComplete: true,
  identityDocumentComplete: true,
  drivingLicenseComplete: true,
  vehicleComplete: true,
  verificationSubmitted: true,
  verificationApproved: true,
  operationalReady: true,
  matchingEligible: false,
  profileFullName: 'Amine Driver',
  verificationStatus: 'APPROVED',
  availability: DriverAvailabilityInfo(
    status: 'OFFLINE',
    offlineAfterCurrentDelivery: false,
    updatedAt: 't',
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

AssignmentOffer _offer() => AssignmentOffer(
  assignmentId: 'asg-offer',
  deliveryId: 'del-1',
  orderPublicReference: 'SG-42',
  status: 'OFFERED',
  offeredAt: '2099-01-01T00:00:00.000Z',
  expiresAt: '2099-01-01T00:00:30.000Z',
  driverRemunerationMinor: '300',
  pickupName: 'Café Atlas',
  pickupDistanceMeters: 350,
  deliveryDistanceMeters: 1200,
);

DriverCurrentDelivery _atPickup({bool confirmPickup = false}) =>
    DriverCurrentDelivery(
      assignmentId: 'asg-1',
      assignmentVersion: 1,
      deliveryId: 'del-1',
      orderId: 'ord-1',
      deliveryStatus: 'AT_PICKUP',
      orderStatus: 'IN_DELIVERY',
      fulfillmentStatus: confirmPickup ? 'READY' : 'PREPARING',
      assignmentStatus: 'ACCEPTED',
      allowedActions: [
        if (confirmPickup) DeliveryActions.confirmPickup,
      ],
      pickedUpAt: null,
      arrivedCustomerAt: null,
      deliveredAt: null,
    );

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  String locale = 'fr',
  FakeAvailabilityClient? availability,
  FakeDeliveryClient? delivery,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      splashMinDurationProvider.overrideWithValue(Duration.zero),
      firstLaunchIntroStoreProvider.overrideWithValue(
        MemoryFirstLaunchIntroStore(completed: true),
      ),
      sessionControllerProvider.overrideWith(_SignedInSession.new),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
      availabilityClientProvider.overrideWithValue(
        availability ?? FakeAvailabilityClient(me: _me()),
      ),
      deliveryClientProvider.overrideWithValue(
        delivery ?? FakeDeliveryClient(current: null),
      ),
      deviceLocationSourceProvider.overrideWithValue(
        FakeDeviceLocationSource(),
      ),
      historyClientProvider.overrideWithValue(FakeHistoryClient()),
      earningsClientProvider.overrideWithValue(FakeEarningsClient()),
      notificationsClientProvider.overrideWithValue(
        FakeNotificationsClient(
          items: const [
            AppNotification(
              id: 'n1',
              type: 'ORDER',
              title: 'Titre',
              body: 'Corps',
              read: false,
              createdAt: '2026-10-09T10:00:00.000Z',
            ),
          ],
        ),
      ),
      driverProfileClientProvider.overrideWithValue(
        FakeDriverProfileClient(me: _me()),
      ),
    ],
  );
  var disposed = false;
  addTearDown(() {
    if (!disposed) {
      disposed = true;
      container.dispose();
    }
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SpeedyGoApp()),
  );
  await _settle(tester);
  if (locale == 'ar') {
    await container.read(localeControllerProvider.notifier).setLocale('ar');
    await _settle(tester);
  }
  return container;
}

void main() {
  group('driver redirect rules', () {
    test('unknown session goes to splash', () {
      expect(
        driverRedirect(status: SessionStatus.unknown, loc: AppRoutes.home),
        AppRoutes.splash,
      );
    });

    test('signed out is limited to auth + language routes', () {
      expect(
        driverRedirect(status: SessionStatus.signedOut, loc: AppRoutes.history),
        AppRoutes.phone,
      );
      expect(
        driverRedirect(
          status: SessionStatus.signedOut,
          loc: AppRoutes.currentDelivery,
        ),
        AppRoutes.phone,
      );
      expect(
        driverRedirect(status: SessionStatus.signedOut, loc: AppRoutes.otp),
        isNull,
      );
      expect(
        driverRedirect(
          status: SessionStatus.signedOut,
          loc: AppRoutes.languageSettingsAuth,
        ),
        isNull,
      );
      expect(
        driverRedirect(
          status: SessionStatus.signedOut,
          loc: AppRoutes.languageSettings,
        ),
        isNull,
      );
    });

    test('signed in skips auth routes and keeps shell/pushed routes', () {
      const approvedMe = DriverMe(
        driverProfileExists: true,
        profileComplete: true,
        identityDocumentComplete: true,
        drivingLicenseComplete: true,
        vehicleComplete: true,
        verificationSubmitted: true,
        verificationApproved: true,
        operationalReady: true,
        matchingEligible: true,
        availability: DriverAvailabilityInfo(
          status: 'OFFLINE',
          offlineAfterCurrentDelivery: false,
          updatedAt: '',
        ),
        verificationStatus: 'APPROVED',
      );
      const approved = DriverNavSnapshot(
        sessionStatus: SessionStatus.signedIn,
        accountStatus: 'ACTIVE',
        resolved: true,
        driverMe: approvedMe,
      );
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.phone,
          snapshot: approved,
        ),
        AppRoutes.home,
      );
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
            snapshot: approved,
          ),
          isNull,
        );
      }
      // Editable onboarding is closed after approval.
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.onboardingReview,
          snapshot: approved,
        ),
        AppRoutes.home,
      );
    });

    test('account without profile is confined to onboarding', () {
      expect(
        driverRedirect(
          status: SessionStatus.needsDriverProfile,
          loc: AppRoutes.home,
        ),
        AppRoutes.onboardingProfile,
      );
      expect(
        driverRedirect(
          status: SessionStatus.needsDriverProfile,
          loc: AppRoutes.onboardingVehicle,
        ),
        isNull,
      );
    });
  });

  group('driver shell', () {
    testWidgets('shows white header, bottom tabs, menu, drawer nav', (
      tester,
    ) async {
      await _pumpApp(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(const Key('shell_bottom_nav')), findsOneWidget);
      expect(find.byKey(const Key('tab_orders')), findsOneWidget);
      expect(find.byKey(const Key('shell_title')), findsOneWidget);
      expect(find.byKey(const Key('shell_menu_button')), findsOneWidget);
      expect(find.byKey(const Key('shell_notifications')), findsOneWidget);
      expect(find.byKey(const Key('availability_card')), findsOneWidget);
      expect(find.byKey(const Key('go_online_button')), findsOneWidget);
      expect(find.byKey(const Key('home_logout')), findsNothing);
      expect(find.byKey(const Key('logout')), findsNothing);

      await tester.tap(find.byKey(const Key('shell_menu_button')));
      await _settle(tester);
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byKey(const Key('nav_orders')), findsOneWidget);
      expect(find.byKey(const Key('nav_history')), findsOneWidget);
      expect(find.byKey(const Key('nav_earnings')), findsOneWidget);
      expect(find.byKey(const Key('nav_profile')), findsOneWidget);
      expect(find.byKey(const Key('nav_vehicle')), findsOneWidget);
      expect(find.byKey(const Key('nav_support')), findsOneWidget);
      expect(find.text('Commandes'), findsWidgets);
      expect(find.text('Historique'), findsWidgets);
      expect(find.text('Gains'), findsWidgets);
      expect(find.text('Profil'), findsWidgets);
    });

    testWidgets('drawer switches branches and touch targets are >= 48', (
      tester,
    ) async {
      await _pumpApp(tester);
      await tester.tap(find.byKey(const Key('shell_menu_button')));
      await _settle(tester);
      for (final key in ['nav_history', 'nav_earnings', 'nav_profile']) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
      await tester.tap(find.byKey(const Key('nav_history')));
      await _settle(tester);
      expect(find.text(AppStrings.historyEmpty), findsOneWidget);

      await tester.tap(find.byKey(const Key('shell_menu_button')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('nav_earnings')));
      await _settle(tester);
      expect(find.byKey(const Key('earnings_summary_card')), findsOneWidget);

      await tester.tap(find.byKey(const Key('shell_menu_button')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('nav_profile')));
      await _settle(tester);
      expect(find.byKey(const Key('profile_name')), findsOneWidget);
      expect(find.text('Amine Driver'), findsOneWidget);
      expect(find.byKey(const Key('logout')), findsOneWidget);

      await tester.tap(find.byKey(const Key('shell_menu_button')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('nav_orders')));
      await _settle(tester);
      expect(find.byKey(const Key('availability_card')), findsOneWidget);
    });

    testWidgets('shell profile affordance opens the profile tab', (
      tester,
    ) async {
      final container = await _pumpApp(tester);
      await tester.tap(find.byKey(const Key('shell_profile_button')));
      await _settle(tester);
      expect(find.byKey(const Key('profile_header')), findsOneWidget);
      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.signedIn,
      );
      expect(find.byKey(const Key('logout_confirm')), findsNothing);
    });

    testWidgets('notifications button pushes inbox and lists items', (
      tester,
    ) async {
      await _pumpApp(tester);
      expect(find.byType(Badge), findsWidgets);
      await tester.tap(find.byKey(const Key('shell_notifications')));
      await _settle(tester);
      expect(find.text(AppStrings.notificationsTitle), findsOneWidget);
      expect(find.byKey(const Key('notification_n1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('notification_n1')));
      await _settle(tester);
      expect(find.text(AppStrings.notificationsUnread), findsNothing);
    });

    testWidgets('Arabic labels are used for drawer items', (tester) async {
      await _pumpApp(tester, locale: 'ar');
      await tester.tap(find.byKey(const Key('shell_menu_button')));
      await _settle(tester);
      expect(find.text('الطلبات'), findsWidgets);
      expect(find.text('السجل'), findsWidgets);
      expect(find.text('الأرباح'), findsWidgets);
      expect(find.text('الملف'), findsWidgets);
    });

    testWidgets('logout opens full-screen confirmation; cancel keeps session', (
      tester,
    ) async {
      final container = await _pumpApp(tester);
      await tester.tap(find.byKey(const Key('shell_menu_button')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('nav_profile')));
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const Key('logout')));
      await tester.tap(find.byKey(const Key('logout')));
      await _settle(tester);
      expect(find.text(AppStrings.logoutScreenTitle), findsWidgets);
      expect(find.byKey(const Key('logout_confirm')), findsOneWidget);
      final cancel = find.byKey(const Key('confirmation_cancel'));
      expect(cancel, findsOneWidget);
      await tester.ensureVisible(cancel);
      await tester.tap(cancel, warnIfMissed: true);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('logout_confirm')), findsNothing);
      expect(
        container.read(sessionControllerProvider).status,
        SessionStatus.signedIn,
      );
    });

    testWidgets('nested profile vehicle keeps bottom tabs and Back', (
      tester,
    ) async {
      final container = await _pumpApp(tester);
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.vehicle);
      await _settle(tester);
      expect(find.byKey(const Key('shell_bottom_nav')), findsOneWidget);
      expect(find.byKey(const Key('shell_menu_button')), findsNothing);
      expect(find.text(AppStrings.vehicleTitle), findsWidgets);
    });

    testWidgets('live offer hides bottom tabs and shows focused app bar', (
      tester,
    ) async {
      final availability = FakeAvailabilityClient(
        me: const DriverMe(
          driverProfileExists: true,
          profileComplete: true,
          identityDocumentComplete: true,
          drivingLicenseComplete: true,
          vehicleComplete: true,
          verificationSubmitted: true,
          verificationApproved: true,
          operationalReady: true,
          matchingEligible: true,
          profileFullName: 'Amine Driver',
          verificationStatus: 'APPROVED',
          availability: DriverAvailabilityInfo(
            status: 'ONLINE',
            offlineAfterCurrentDelivery: false,
            updatedAt: 't',
          ),
        ),
        offer: _offer(),
      );
      final container = await _pumpApp(tester, availability: availability);
      await _settle(tester);
      expect(find.byKey(const Key('offer_card')), findsOneWidget);
      expect(find.byKey(const Key('offer_focused_app_bar')), findsOneWidget);
      expect(find.byKey(const Key('shell_bottom_nav')), findsNothing);
      expect(find.byKey(const Key('go_online_button')), findsNothing);
      expect(find.byKey(const Key('offer_accept_button')), findsOneWidget);
      // Clear offer + go offline so home controller cancels polling timers.
      availability.offer = null;
      availability.me = _me();
      await container.read(driverHomeControllerProvider.notifier).refresh(
        full: true,
      );
      await _settle(tester);
    });

    testWidgets('AT_PICKUP without confirm keeps Commandes tabs', (
      tester,
    ) async {
      final container = await _pumpApp(
        tester,
        delivery: FakeDeliveryClient(current: _atPickup()),
      );
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.currentDelivery);
      await _settle(tester);
      expect(find.byKey(const Key('shell_bottom_nav')), findsOneWidget);
      expect(find.byKey(const Key('shell_menu_button')), findsNothing);
    });

    testWidgets('AT_PICKUP confirm-pickup hides bottom tabs', (tester) async {
      final container = await _pumpApp(
        tester,
        delivery: FakeDeliveryClient(
          current: _atPickup(confirmPickup: true),
        ),
      );
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.currentDelivery);
      await _settle(tester);
      expect(find.byKey(const Key('shell_bottom_nav')), findsNothing);
      expect(find.byKey(const Key('pickup_code_card')), findsOneWidget);
    });
  });

  test('onboarding provider default is isolated per container', () {
    final container = ProviderContainer(
      overrides: [sessionStoreProvider.overrideWithValue(MemorySessionStore())],
    );
    addTearDown(container.dispose);
    expect(container.read(onboardingControllerProvider).me, isNull);
  });
}
