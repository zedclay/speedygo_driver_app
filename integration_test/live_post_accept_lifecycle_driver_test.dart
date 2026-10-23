import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:geolocator/geolocator.dart';

/// Live post-accept Driver COD lifecycle against isolated API :3100.
///
/// Shell watcher handles: OTP clear, sim location, handoff fetch, screenshots.
/// GPS uses a file-backed fake because iOS Simulator Geolocator frequently
/// returns Cupertino defaults; UI still publishes to live `/driver/location`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment(
    'PARITY_PREFIX',
    defaultValue: 'fxlife',
  );
  const secretsPath = String.fromEnvironment('FX_SECRETS_PATH');
  const shotMarker = '/tmp/parity_fx_lifecycle_shot.txt';
  const driverPhone = '+213550009131';

  final fakeLocation = FakeDeviceLocationSource(
    permission: LocationPermission.whileInUse,
    position: const DevicePosition(
      latitude: 36.785,
      longitude: 3.060,
      accuracyMeters: 10,
    ),
  );

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 50),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 900));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  Future<void> marker(WidgetTester tester, String tag) async {
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 4));
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 100; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('isolated OTP not found');
  }

  Future<Map<String, dynamic>> readSecrets() async {
    final file = File(secretsPath);
    for (var i = 0; i < 40; i++) {
      if (file.existsSync()) {
        final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        return map;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw StateError('secrets missing');
  }

  Future<String> waitForPickupCode() async {
    final file = File(secretsPath);
    for (var i = 0; i < 120; i++) {
      if (file.existsSync()) {
        final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final code = (map['pickupCode'] ?? '').toString();
        if (RegExp(r'^\d{4}$').hasMatch(code)) return code;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw StateError('pickup code not available');
  }

  Future<void> login(WidgetTester tester) async {
    await waitFor(tester, find.byKey(const Key('phone_continue')));
    await marker(tester, 'clear_otp');
    await tester.enterText(find.byKey(const Key('phone_field')), driverPhone);
    await tester.pump(const Duration(milliseconds: 400));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('phone_continue')));
    await waitFor(tester, find.byKey(const Key('otp_field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('otp_field')), otp);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('otp_verify')));
    await waitFor(
      tester,
      find.byKey(const Key('availability_card')),
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> openCurrentDelivery(WidgetTester tester) async {
    await waitFor(
      tester,
      find.byKey(const Key('open_current_delivery')),
      timeout: const Duration(seconds: 45),
    );
    await tester.tap(find.byKey(const Key('open_current_delivery')));
    await waitFor(
      tester,
      find.byKey(const Key('delivery_status_card')),
      timeout: const Duration(seconds: 45),
    );
  }

  Future<void> tapAction(WidgetTester tester, String action) async {
    final key = Key('delivery_action_$action');
    await waitFor(
      tester,
      find.byKey(key),
      timeout: const Duration(seconds: 40),
    );
    // Sticky bottom actions are outside the scroll view — do not ensureVisible.
    await tester.tap(find.byKey(key));
    await pumpFrames(tester, const Duration(seconds: 4));
  }

  void setFixtureLocation(String phase, Map<String, dynamic> secrets) {
    final latKey = phase == 'customer' ? 'customerLat' : 'branchLat';
    final lngKey = phase == 'customer' ? 'customerLng' : 'branchLng';
    final lat =
        (secrets[latKey] as num?)?.toDouble() ??
        (phase == 'customer' ? 36.770 : 36.785);
    final lng =
        (secrets[lngKey] as num?)?.toDouble() ??
        (phase == 'customer' ? 3.050 : 3.060);
    fakeLocation.position = DevicePosition(
      latitude: lat,
      longitude: lng,
      accuracyMeters: 10,
    );
  }

  Future<void> arriveWithLocationRetries(
    WidgetTester tester, {
    required String locMarker,
    required String expectedStatus,
    required Map<String, dynamic> secrets,
  }) async {
    final phase = locMarker.contains('customer') ? 'customer' : 'branch';
    for (var attempt = 0; attempt < 3; attempt++) {
      setFixtureLocation(phase, secrets);
      await marker(tester, locMarker);
      await pumpFrames(tester, const Duration(seconds: 2));
      await tapAction(
        tester,
        expectedStatus == 'AT_PICKUP' ? 'arrive-pickup' : 'arrive-customer',
      );
      final end = DateTime.now().add(const Duration(seconds: 25));
      while (DateTime.now().isBefore(end)) {
        await pumpFrames(tester, const Duration(milliseconds: 300));
        if (find
            .text(AppStrings.deliveryStatusLabel(expectedStatus))
            .evaluate()
            .isNotEmpty) {
          return;
        }
      }
      if (find.byKey(const Key('delivery_refresh')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('delivery_refresh')));
        await pumpFrames(tester, const Duration(seconds: 2));
      }
    }
    throw TestFailure('arrive failed for $expectedStatus after retries');
  }

  Future<void> switchLocale(WidgetTester tester, String optionKey) async {
    await waitFor(
      tester,
      find.byKey(const Key('delivery_language')),
      timeout: const Duration(seconds: 20),
    );
    await tester.ensureVisible(find.byKey(const Key('delivery_language')));
    await tester.tap(find.byKey(const Key('delivery_language')));
    await waitFor(tester, find.byKey(Key(optionKey)));
    await tester.tap(find.byKey(Key(optionKey)));
    await tester.pump(const Duration(milliseconds: 300));
    await waitFor(tester, find.byKey(const Key('language-apply')));
    final apply = tester.widget<FilledButton>(
      find.byKey(const Key('language-apply')),
    );
    if (apply.onPressed != null) {
      await tester.tap(find.byKey(const Key('language-apply')));
    } else {
      // Already selected — pop back.
      final back = find.byType(BackButton);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
      } else {
        await tester.pageBack();
      }
    }
    await pumpFrames(tester, const Duration(seconds: 2));
    await waitFor(
      tester,
      find.byKey(const Key('delivery_language')),
      timeout: const Duration(seconds: 20),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFrames(tester, const Duration(milliseconds: 400));
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        deviceLocationSourceProvider.overrideWithValue(fakeLocation),
      ],
    );
    await container.read(localeControllerProvider.notifier).restore();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeedyGoApp(),
      ),
    );
    await pumpFrames(tester, const Duration(seconds: 6));
  }

  testWidgets('live post-accept COD lifecycle', (tester) async {
    expect(AppConstants.apiBaseUrl, isolatedApi);
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(secretsPath.isNotEmpty, isTrue);
    expect(evidenceDir.isNotEmpty, isTrue);

    final secrets = await readSecrets();
    final expectedCod = secrets['expectedCodMinor'];
    expect(expectedCod, isA<int>());

    await pumpApp(tester);
    await login(tester);
    expect(find.byKey(const Key('nav_orders')), findsOneWidget);
    expect(find.byKey(const Key('nav_history')), findsOneWidget);
    expect(find.byKey(const Key('nav_earnings')), findsOneWidget);
    expect(find.byKey(const Key('nav_profile')), findsOneWidget);

    await openCurrentDelivery(tester);
    expect(
      find.text(AppStrings.deliveryStatusLabel('DRIVER_ASSIGNED')),
      findsWidgets,
    );
    await shot(tester, '01_fr_accepted_current');
    await switchLocale(tester, 'language-option-ar');
    await shot(tester, '01b_ar_accepted_current');
    await switchLocale(tester, 'language-option-fr');

    // Start toward merchant.
    await tapAction(tester, 'start-to-pickup');
    await waitFor(
      tester,
      find.text(AppStrings.deliveryStatusLabel('TO_PICKUP')),
      timeout: const Duration(seconds: 40),
    );
    await shot(tester, '02_fr_to_pickup');
    await switchLocale(tester, 'language-option-ar');
    await shot(tester, '02b_ar_to_pickup');
    await switchLocale(tester, 'language-option-fr');

    // Ensure simulator GPS near merchant, then arrive.
    await arriveWithLocationRetries(
      tester,
      locMarker: 'loc_branch',
      expectedStatus: 'AT_PICKUP',
      secrets: secrets,
    );
    await shot(tester, '03_fr_at_pickup');
    expect(find.byKey(const Key('pickup_code_field')), findsOneWidget);
    // Empty pickup field only — never screenshot an entered live code.
    await shot(tester, '04_fr_pickup_entry_empty');
    await switchLocale(tester, 'language-option-ar');
    await shot(tester, '04b_ar_pickup_entry_empty');
    await switchLocale(tester, 'language-option-fr');

    // Fetch handoff via merchant API (shell), then enter code (no shot while visible).
    await marker(tester, 'fetch_handoff');
    final code = await waitForPickupCode();
    await tester.enterText(find.byKey(const Key('pickup_code_field')), code);
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, find.byKey(const Key('confirm_pickup_button')));
    await tester.tap(find.byKey(const Key('confirm_pickup_button')));
    await pumpFrames(tester, const Duration(seconds: 2));
    await waitFor(
      tester,
      find.text(AppStrings.pickedUpSuccess),
      timeout: const Duration(seconds: 40),
    );
    expect(
      find.text(AppStrings.deliveryStatusLabel('PICKED_UP')),
      findsWidgets,
    );
    expect(find.byKey(const Key('pickup_code_field')), findsNothing);
    await shot(tester, '06_fr_picked_up');

    // Mid-flow relaunch: re-auth restores server current delivery.
    await tester.tap(find.byKey(const Key('delivery_back_home')));
    await pumpFrames(tester, const Duration(seconds: 1));
    await marker(tester, 'relaunch_prep');
    await pumpApp(tester);
    await login(tester);
    await openCurrentDelivery(tester);
    expect(
      find.text(AppStrings.deliveryStatusLabel('PICKED_UP')),
      findsWidgets,
    );
    await shot(tester, '07_fr_relaunch_picked_up');

    await tapAction(tester, 'start-delivery');
    await waitFor(
      tester,
      find.text(AppStrings.deliveryStatusLabel('IN_TRANSIT')),
      timeout: const Duration(seconds: 40),
    );
    await shot(tester, '08_fr_in_transit');
    await switchLocale(tester, 'language-option-ar');
    await shot(tester, '08b_ar_in_transit');
    await switchLocale(tester, 'language-option-fr');

    await arriveWithLocationRetries(
      tester,
      locMarker: 'loc_customer',
      expectedStatus: 'ARRIVED_CUSTOMER',
      secrets: secrets,
    );
    await shot(tester, '09_fr_arrived_customer');
    expect(find.byKey(const Key('cod_card')), findsOneWidget);
    expect(find.byKey(const Key('cod_amount_field')), findsOneWidget);
    // No customer PIN field invented.
    expect(find.textContaining('PIN'), findsNothing);
    expect(find.textContaining('pin'), findsNothing);
    await switchLocale(tester, 'language-option-ar');
    await shot(tester, '09b_ar_arrived_customer_cod');
    await switchLocale(tester, 'language-option-fr');

    // Premature completion before COD.
    await tapAction(tester, 'complete-delivery');
    await waitFor(
      tester,
      find.text(
        AppStrings.errorForCode('DRIVER_DELIVERY_COD_COMPLETION_NOT_READY'),
      ),
      timeout: const Duration(seconds: 40),
    );
    expect(
      find.text(AppStrings.deliveryStatusLabel('ARRIVED_CUSTOMER')),
      findsWidgets,
    );
    await shot(tester, '10_fr_complete_blocked_before_cod');

    await shot(tester, '11_fr_cod_ready');
    await tester.ensureVisible(find.byKey(const Key('cod_amount_field')));
    await tester.enterText(
      find.byKey(const Key('cod_amount_field')),
      '$expectedCod',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, find.byKey(const Key('cod_collect_button')));
    final collectFinder = find.byKey(const Key('cod_collect_button'));
    for (var i = 0; i < 5; i++) {
      final btn = tester.widget<OutlinedButton>(collectFinder);
      if (btn.onPressed != null) {
        btn.onPressed!();
        await pumpFrames(tester, const Duration(seconds: 3));
        break;
      }
      await tester.enterText(
        find.byKey(const Key('cod_amount_field')),
        '$expectedCod',
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
    await waitFor(
      tester,
      find.text(AppStrings.codCollectedSuccess),
      timeout: const Duration(seconds: 40),
    );
    await shot(tester, '12_fr_cod_collected');
    await switchLocale(tester, 'language-option-ar');
    await shot(tester, '12b_ar_cod_collected');
    await switchLocale(tester, 'language-option-fr');
    // Still arrived — COD does not auto-complete.
    expect(
      find.text(AppStrings.deliveryStatusLabel('ARRIVED_CUSTOMER')),
      findsWidgets,
    );

    // Duplicate COD collect (safe replay) — button disabled when collected.
    final collectBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('cod_collect_button')),
    );
    expect(collectBtn.onPressed, isNull);

    await tapAction(tester, 'complete-delivery');
    await waitFor(
      tester,
      find.byKey(const Key('delivered_banner')),
      timeout: const Duration(seconds: 45),
    );
    await shot(tester, '13_fr_delivered');

    // Arabic/RTL evidence at completed checkpoint + history.
    await switchLocale(tester, 'language-option-ar');
    await shot(tester, '14_ar_delivered_rtl');
    await tester.tap(find.byKey(const Key('delivery_done_back')));
    await pumpFrames(tester, const Duration(seconds: 2));
    await waitFor(tester, find.byKey(const Key('nav_history')));
    await tester.tap(find.byKey(const Key('nav_history')));
    await pumpFrames(tester, const Duration(seconds: 3));
    await shot(tester, '15_ar_history');
    await tester.tap(find.byKey(const Key('nav_earnings')));
    await pumpFrames(tester, const Duration(seconds: 3));
    await shot(tester, '16_ar_earnings_cod');

    // Refresh current — no active delivery.
    await tester.tap(find.byKey(const Key('nav_orders')));
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(find.byKey(const Key('open_current_delivery')), findsNothing);
    await shot(tester, '17_ar_home_no_active');

    await tester.tap(find.byKey(const Key('nav_profile')));
    await pumpFrames(tester, const Duration(seconds: 1));
    await shot(tester, '18_shell_profile');

    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    await pumpFrames(tester, const Duration(seconds: 2));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
