import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_api.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';
import 'package:speedygo_driver_app/features/history/data/history_api.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

/// Live iPhone simulator UI for first-launch intro.
/// Classification: `live_driver_ui_verified` for intro chrome + phone destination.
/// Not authenticated_api_verified.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Host absolute path via --dart-define=FX_EVIDENCE_DIR=... (device FS is RO).
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');

  Future<void> settle(WidgetTester tester, [int n = 25]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(String name) async {
    expect(
      evidenceDir.isNotEmpty,
      isTrue,
      reason: 'Pass --dart-define=FX_EVIDENCE_DIR=<host absolute path>',
    );
    await binding.convertFlutterSurfaceToImage();
    final bytes = await binding.takeScreenshot(name);
    final dir = Directory(evidenceDir)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes);
  }

  DriverMe me() => const DriverMe(
    driverProfileExists: true,
    profileComplete: true,
    identityDocumentComplete: true,
    drivingLicenseComplete: true,
    vehicleComplete: true,
    verificationSubmitted: true,
    verificationApproved: true,
    operationalReady: true,
    matchingEligible: false,
    verificationStatus: 'APPROVED',
    availability: DriverAvailabilityInfo(
      status: 'OFFLINE',
      offlineAfterCurrentDelivery: false,
      updatedAt: 't',
    ),
  );

  List<Override> overrides({
    required FirstLaunchIntroStore intro,
    required String locale,
  }) {
    return [
      splashMinDurationProvider.overrideWithValue(
        const Duration(milliseconds: 500),
      ),
      firstLaunchIntroStoreProvider.overrideWithValue(intro),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
      authApiProvider.overrideWithValue(FakeAuthClient()),
      availabilityClientProvider.overrideWithValue(
        FakeAvailabilityClient(me: me()),
      ),
      deliveryClientProvider.overrideWithValue(FakeDeliveryClient()),
      deviceLocationSourceProvider.overrideWithValue(
        FakeDeviceLocationSource(),
      ),
      historyClientProvider.overrideWithValue(FakeHistoryClient()),
      earningsClientProvider.overrideWithValue(FakeEarningsClient()),
      notificationsClientProvider.overrideWithValue(FakeNotificationsClient()),
      driverProfileClientProvider.overrideWithValue(
        FakeDriverProfileClient(me: me()),
      ),
    ];
  }

  testWidgets('live intro FR pages → Commencer → phone → relaunch skips', (
    tester,
  ) async {
    final intro = MemoryFirstLaunchIntroStore(completed: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(intro: intro, locale: 'fr'),
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester, 35);
    expect(find.byKey(const Key('first_launch_intro_screen')), findsOneWidget);
    await shot('live_fr_intro_page1');

    await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
    await settle(tester, 18);
    await shot('live_fr_intro_page2');

    await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
    await settle(tester, 18);
    await shot('live_fr_intro_page3');

    await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
    await settle(tester, 30);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    expect(await intro.isCompleted(), isTrue);
    await shot('live_fr_destination_phone');

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(intro: intro, locale: 'fr'),
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester, 30);
    expect(find.byKey(const Key('first_launch_intro_screen')), findsNothing);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    await shot('live_fr_relaunch_skips_intro');
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('live intro AR pages + Skip path', (tester) async {
    final intro = MemoryFirstLaunchIntroStore(completed: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(intro: intro, locale: 'ar'),
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester, 35);
    expect(find.byKey(const Key('first_launch_intro_screen')), findsOneWidget);
    await shot('live_ar_intro_page1');
    await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
    await settle(tester, 18);
    await shot('live_ar_intro_page2');
    await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
    await settle(tester, 18);
    await shot('live_ar_intro_page3');

    final skipStore = MemoryFirstLaunchIntroStore(completed: false);
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, 5);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(intro: skipStore, locale: 'fr'),
        child: const SpeedyGoApp(),
      ),
    );
    await settle(tester, 35);
    expect(find.byKey(const Key('first_launch_intro_skip')), findsOneWidget);
    await tester.tap(find.byKey(const Key('first_launch_intro_skip')));
    await settle(tester, 25);
    expect(await skipStore.isCompleted(), isTrue);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    await shot('live_fr_skip_to_phone');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
