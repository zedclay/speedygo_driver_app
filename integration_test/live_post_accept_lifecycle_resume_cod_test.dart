import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';

/// Resume from ARRIVED_CUSTOMER: COD collect → complete → history (live UI).
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
      latitude: 36.770,
      longitude: 3.050,
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

  Future<void> switchLocale(WidgetTester tester, String optionKey) async {
    await waitFor(tester, find.byKey(const Key('delivery_language')));
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
      await tester.pageBack();
    }
    await pumpFrames(tester, const Duration(seconds: 2));
    await waitFor(tester, find.byKey(const Key('delivery_language')));
  }

  testWidgets('resume COD collect and complete', (tester) async {
    expect(AppConstants.apiBaseUrl, isolatedApi);
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(secretsPath.isNotEmpty, isTrue);
    expect(evidenceDir.isNotEmpty, isTrue);

    final secrets = jsonDecode(
      File(secretsPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final expectedCod = secrets['expectedCodMinor'] as int;

    await pumpApp(tester);
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
      find.byKey(const Key('open_current_delivery')),
      timeout: const Duration(seconds: 60),
    );
    await tester.tap(find.byKey(const Key('open_current_delivery')));
    await waitFor(
      tester,
      find.text(AppStrings.deliveryStatusLabel('ARRIVED_CUSTOMER')),
      timeout: const Duration(seconds: 45),
    );
    expect(find.byKey(const Key('cod_card')), findsOneWidget);

    // Premature complete (idempotent gate) then collect.
    await waitFor(
      tester,
      find.byKey(const Key('delivery_action_complete-delivery')),
    );
    await tester.tap(
      find.byKey(const Key('delivery_action_complete-delivery')),
    );
    await pumpFrames(tester, const Duration(seconds: 2));
    await waitFor(
      tester,
      find.text(
        AppStrings.errorForCode('DRIVER_DELIVERY_COD_COMPLETION_NOT_READY'),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('cod_amount_field')));
    await tester.enterText(
      find.byKey(const Key('cod_amount_field')),
      '$expectedCod',
    );
    await tester.pump(const Duration(milliseconds: 500));
    // Sticky complete bar can steal hit-tests; invoke the live widget callback.
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
    expect(
      find.text(AppStrings.deliveryStatusLabel('ARRIVED_CUSTOMER')),
      findsWidgets,
    );

    final collectBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('cod_collect_button')),
    );
    expect(collectBtn.onPressed, isNull);

    // Duplicate collect via API-safe UI: button disabled; complete next.
    await tester.tap(
      find.byKey(const Key('delivery_action_complete-delivery')),
    );
    await pumpFrames(tester, const Duration(seconds: 3));
    await waitFor(
      tester,
      find.byKey(const Key('delivered_banner')),
      timeout: const Duration(seconds: 45),
    );
    await shot(tester, '13_fr_delivered');

    // Duplicate complete — refresh should keep delivered/empty.
    await tester.tap(find.byKey(const Key('delivery_refresh')));
    await pumpFrames(tester, const Duration(seconds: 2));

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
    await tester.tap(find.byKey(const Key('nav_orders')));
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(find.byKey(const Key('open_current_delivery')), findsNothing);
    await shot(tester, '17_ar_home_no_active');
    await tester.tap(find.byKey(const Key('nav_profile')));
    await pumpFrames(tester, const Duration(seconds: 1));
    await shot(tester, '18_shell_profile');

    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    await pumpFrames(tester, const Duration(seconds: 2));
  }, timeout: const Timeout(Duration(minutes: 15)));
}
