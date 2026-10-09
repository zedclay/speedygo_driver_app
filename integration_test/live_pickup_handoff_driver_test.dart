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

/// Live Driver confirm-pickup UI against isolated API :3100.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment(
    'PARITY_PREFIX',
    defaultValue: 'fxlive',
  );
  const secretsPath = String.fromEnvironment('FX_SECRETS_PATH');
  const shotMarker = '/tmp/parity_fx_isolated_shot.txt';
  const driverPhone = '+213550009131';

  Future<void> pumpFrames(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 40),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 1200));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
  }

  Future<String> waitForFreshOtp(DateTime after) async {
    final file = File(otpFilePath);
    for (var i = 0; i < 80; i++) {
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

  testWidgets('live driver confirm pickup', (tester) async {
    expect(AppConstants.apiBaseUrl, isolatedApi);
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(secretsPath.isNotEmpty, isTrue);
    expect(evidenceDir.isNotEmpty, isTrue);

    final secrets =
        jsonDecode(File(secretsPath).readAsStringSync()) as Map<String, dynamic>;
    final code = (secrets['pickupCode'] ?? '').toString();
    expect(code.length, 4);

    await pumpApp(tester);
    await waitFor(tester, find.byKey(const Key('phone_continue')));

    File(shotMarker).writeAsStringSync('${prefix}_clear_otp\n');
    await pumpFrames(tester, const Duration(milliseconds: 800));

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
      find.byKey(const Key('pickup_code_field')),
      timeout: const Duration(seconds: 50),
    );
    await shot(tester, 'driver_code_entry');

    await tester.enterText(find.byKey(const Key('pickup_code_field')), code);
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, find.byKey(const Key('confirm_pickup_button')));
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('confirm_pickup_button')),
    );
    expect(confirm.onPressed, isNotNull);
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
    await shot(tester, 'driver_picked_up');

    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    await pumpFrames(tester, const Duration(seconds: 2));
  });
}
