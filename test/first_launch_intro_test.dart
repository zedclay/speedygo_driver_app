import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/app/router/driver_navigation_resolver.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_api.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_controller.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';
import 'package:speedygo_driver_app/features/history/data/history_api.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

DriverMe _approvedMe() => const DriverMe(
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

class _SignedInSession extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.signedIn);

  @override
  Future<void> restore() async {}
}

Future<void> _pumpFrames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

List<Override> _baseOverrides({
  required FirstLaunchIntroStore introStore,
  String locale = 'fr',
  SessionController Function()? session,
  AvailabilityClient? availability,
  DeliveryClient? delivery,
}) {
  return [
    splashMinDurationProvider.overrideWithValue(Duration.zero),
    firstLaunchIntroStoreProvider.overrideWithValue(introStore),
    sessionStoreProvider.overrideWithValue(MemorySessionStore()),
    localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
    authApiProvider.overrideWithValue(FakeAuthClient()),
    if (session != null) sessionControllerProvider.overrideWith(session),
    availabilityClientProvider.overrideWithValue(
      availability ?? FakeAvailabilityClient(me: _approvedMe()),
    ),
    deliveryClientProvider.overrideWithValue(
      delivery ?? FakeDeliveryClient(current: null),
    ),
    deviceLocationSourceProvider.overrideWithValue(FakeDeviceLocationSource()),
    historyClientProvider.overrideWithValue(FakeHistoryClient()),
    earningsClientProvider.overrideWithValue(FakeEarningsClient()),
    notificationsClientProvider.overrideWithValue(FakeNotificationsClient()),
    driverProfileClientProvider.overrideWithValue(
      FakeDriverProfileClient(me: _approvedMe()),
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('first-launch intro persistence', () {
    test('missing flag is not completed', () async {
      final store = MemoryFirstLaunchIntroStore();
      expect(await store.isCompleted(), isFalse);
    });

    test('markCompleted persists locally', () async {
      final store = MemoryFirstLaunchIntroStore();
      await store.markCompleted();
      expect(await store.isCompleted(), isTrue);
    });

    test('resetForTests clears completion', () async {
      final store = MemoryFirstLaunchIntroStore(completed: true);
      await store.resetForTests();
      expect(await store.isCompleted(), isFalse);
    });

    test(
      'controller complete does not clear on recreate with same store',
      () async {
        final store = MemoryFirstLaunchIntroStore();
        final container = ProviderContainer(
          overrides: [firstLaunchIntroStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        await container
            .read(firstLaunchIntroCompletedProvider.notifier)
            .restore();
        expect(container.read(firstLaunchIntroCompletedProvider), isFalse);
        await container
            .read(firstLaunchIntroCompletedProvider.notifier)
            .complete();
        expect(container.read(firstLaunchIntroCompletedProvider), isTrue);
        expect(await store.isCompleted(), isTrue);
      },
    );
  });

  group('first-launch intro redirect gate', () {
    test('incomplete intro forces welcome-intro over home', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedOut,
          loc: AppRoutes.home,
          introCompleted: false,
        ),
        AppRoutes.welcomeIntro,
      );
    });

    test('incomplete intro allows welcome-intro', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedOut,
          loc: AppRoutes.welcomeIntro,
          introCompleted: false,
        ),
        isNull,
      );
    });

    test('completed intro leaves welcome-intro via resolver destination', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedOut,
          loc: AppRoutes.welcomeIntro,
          introCompleted: true,
          snapshot: const DriverNavSnapshot(
            sessionStatus: SessionStatus.signedOut,
            resolved: true,
          ),
        ),
        AppRoutes.phone,
      );
    });

    test('incomplete intro does not hardcode home for approved signed-in', () {
      expect(
        driverRedirect(
          status: SessionStatus.signedIn,
          loc: AppRoutes.home,
          introCompleted: false,
          snapshot: DriverNavSnapshot(
            sessionStatus: SessionStatus.signedIn,
            driverMe: _approvedMe(),
            resolved: true,
          ),
        ),
        AppRoutes.welcomeIntro,
      );
    });
  });

  group('first-launch intro UI', () {
    testWidgets('missing flag → intro after splash', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      expect(
        find.byKey(const Key('first_launch_intro_screen')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.firstLaunchIntroPage1Title), findsOneWidget);
      expect(find.text(AppStrings.firstLaunchIntroSkip), findsOneWidget);
    });

    testWidgets('completed flag → intro skipped to phone', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      expect(find.byKey(const Key('first_launch_intro_screen')), findsNothing);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
    });

    testWidgets('page 1 next → page 2 → page 3', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await _pumpFrames(tester, 10);
      expect(find.text(AppStrings.firstLaunchIntroPage2Title), findsOneWidget);
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await _pumpFrames(tester, 10);
      expect(find.text(AppStrings.firstLaunchIntroPage3Title), findsOneWidget);
      expect(find.text(AppStrings.firstLaunchIntroStart), findsOneWidget);
      expect(find.byKey(const Key('first_launch_intro_skip')), findsNothing);
    });

    testWidgets('swipe updates indicator', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.fling(
        find.byKey(const Key('first_launch_intro_pager')),
        const Offset(-400, 0),
        1000,
      );
      await _pumpFrames(tester, 20);
      expect(find.text(AppStrings.firstLaunchIntroPage2Title), findsOneWidget);
      final active = tester.getSize(
        find.byKey(const Key('first_launch_intro_dot_1')),
      );
      final inactive = tester.getSize(
        find.byKey(const Key('first_launch_intro_dot_0')),
      );
      expect(active.width, greaterThan(inactive.width));
    });

    testWidgets('skip from page 1 saves completion and resolves to phone', (
      tester,
    ) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.tap(find.byKey(const Key('first_launch_intro_skip')));
      await _pumpFrames(tester, 16);
      expect(await store.isCompleted(), isTrue);
      expect(find.byKey(const Key('first_launch_intro_screen')), findsNothing);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
    });

    testWidgets('skip from page 2 saves completion', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await _pumpFrames(tester, 10);
      await tester.tap(find.byKey(const Key('first_launch_intro_skip')));
      await _pumpFrames(tester, 16);
      expect(await store.isCompleted(), isTrue);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
    });

    testWidgets('commencer saves completion and uses resolver (phone)', (
      tester,
    ) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await _pumpFrames(tester, 8);
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await _pumpFrames(tester, 8);
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await _pumpFrames(tester, 16);
      expect(await store.isCompleted(), isTrue);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
      expect(find.byKey(const Key('nav_home')), findsNothing);
    });

    testWidgets('relaunch after completion skips intro', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      expect(find.byKey(const Key('first_launch_intro_screen')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      expect(find.byKey(const Key('first_launch_intro_screen')), findsNothing);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
    });

    testWidgets('termination before completion shows intro again', (
      tester,
    ) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await _pumpFrames(tester, 8);
      expect(await store.isCompleted(), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      expect(
        find.byKey(const Key('first_launch_intro_screen')),
        findsOneWidget,
      );
    });

    testWidgets('approved + active delivery resolves after intro', (
      tester,
    ) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      final delivery = FakeDeliveryClient(
        current: const DriverCurrentDelivery(
          assignmentId: 'asg-intro',
          assignmentVersion: 1,
          deliveryId: 'del-intro',
          orderId: 'ord-intro',
          deliveryStatus: 'DRIVER_ASSIGNED',
          orderStatus: 'ACTIVE',
          fulfillmentStatus: 'READY',
          assignmentStatus: 'ACCEPTED',
          allowedActions: ['start-to-pickup'],
          pickedUpAt: null,
          arrivedCustomerAt: null,
          deliveredAt: null,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            introStore: store,
            session: _SignedInSession.new,
            delivery: delivery,
          ),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.tap(find.byKey(const Key('first_launch_intro_skip')));
      await _pumpFrames(tester, 20);
      expect(await store.isCompleted(), isTrue);
      expect(find.byKey(const Key('delivery_status_card')), findsOneWidget);
    });

    testWidgets('French copy on page 1', (tester) async {
      AppStrings.bind('fr');
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      expect(find.text('Recevez des courses'), findsOneWidget);
      expect(find.text('Passer'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
    });

    testWidgets('Arabic RTL copy and direction-aware arrow', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store, locale: 'ar'),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 16);
      expect(find.text('استلم طلبات التوصيل'), findsOneWidget);
      expect(find.text('تخطي'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(
        find.byKey(const Key('first_launch_intro_screen')),
        findsOneWidget,
      );
    });

    testWidgets('text scale 1.3 does not overflow', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: SpeedyGoApp(),
          ),
        ),
      );
      await _pumpFrames(tester, 12);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('first_launch_intro_primary')),
        findsOneWidget,
      );
    });

    testWidgets('repeated skip taps do not throw / stay single route', (
      tester,
    ) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.tap(find.byKey(const Key('first_launch_intro_skip')));
      await tester.tap(find.byKey(const Key('first_launch_intro_skip')));
      await _pumpFrames(tester, 16);
      expect(find.byKey(const Key('phone_field')), findsOneWidget);
      expect(find.byKey(const Key('first_launch_intro_screen')), findsNothing);
    });

    testWidgets('system back from page 2 returns to page 1', (tester) async {
      final store = MemoryFirstLaunchIntroStore(completed: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(introStore: store),
          child: const SpeedyGoApp(),
        ),
      );
      await _pumpFrames(tester, 12);
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await _pumpFrames(tester, 10);
      expect(find.text(AppStrings.firstLaunchIntroPage2Title), findsOneWidget);
      final dynamic widgetsBinding = tester.binding;
      widgetsBinding.handlePopRoute();
      await _pumpFrames(tester, 10);
      expect(find.text(AppStrings.firstLaunchIntroPage1Title), findsOneWidget);
    });
  });

  group('logout / session do not reset intro', () {
    test('logout path leaves intro completion intact', () async {
      final store = MemoryFirstLaunchIntroStore(completed: true);
      final container = ProviderContainer(
        overrides: [
          firstLaunchIntroStoreProvider.overrideWithValue(store),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          localeStoreProvider.overrideWithValue(
            MemoryLocaleStore(locale: 'fr'),
          ),
          authApiProvider.overrideWithValue(FakeAuthClient()),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(firstLaunchIntroCompletedProvider.notifier)
          .restore();
      await container.read(sessionControllerProvider.notifier).logout();
      expect(await store.isCompleted(), isTrue);
      expect(container.read(firstLaunchIntroCompletedProvider), isTrue);
    });
  });
}
