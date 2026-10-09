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

/// Live Driver availability/offers UI against isolated API :3100.
///
/// Phases via `--dart-define=LIVE_OFFERS_PHASE=...`:
/// offline | waiting | accept | reject | expire | arabic
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment(
    'PARITY_PREFIX',
    defaultValue: 'fxoffers',
  );
  const phase = String.fromEnvironment(
    'LIVE_OFFERS_PHASE',
    defaultValue: 'offline',
  );
  const shotMarker = '/tmp/parity_fx_offers_shot.txt';
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
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pumpFrames(tester, const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder (phase=$phase)');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    await pumpFrames(tester, const Duration(milliseconds: 800));
    File(shotMarker).writeAsStringSync('${prefix}_$tag\n');
    await pumpFrames(tester, const Duration(seconds: 3));
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
      overrides: [sessionStoreProvider.overrideWithValue(MemorySessionStore())],
    );
    await container.read(localeControllerProvider.notifier).restore();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeedyGoApp(),
      ),
    );
    await pumpFrames(tester, const Duration(seconds: 5));
  }

  Future<void> login(WidgetTester tester) async {
    await waitFor(tester, find.byKey(const Key('phone_continue')));
    File(shotMarker).writeAsStringSync('${prefix}_clear_otp\n');
    await pumpFrames(tester, const Duration(milliseconds: 900));
    await tester.enterText(find.byKey(const Key('phone_field')), driverPhone);
    await tester.pump(const Duration(milliseconds: 300));
    final otpBefore = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('phone_continue')));
    await waitFor(tester, find.byKey(const Key('otp_field')));
    final otp = await waitForFreshOtp(otpBefore);
    await tester.enterText(find.byKey(const Key('otp_field')), otp);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const Key('otp_verify')));
    await waitFor(
      tester,
      find.byKey(const Key('availability_card')),
      timeout: const Duration(seconds: 55),
    );
  }

  testWidgets('live driver availability offers phase=$phase', (tester) async {
    expect(AppConstants.apiBaseUrl, isolatedApi);
    expect(otpFilePath.isNotEmpty, isTrue);
    expect(evidenceDir.isNotEmpty, isTrue);

    await pumpApp(tester);
    await login(tester);

    switch (phase) {
      case 'offline':
        expect(find.byKey(const Key('go_online_button')), findsOneWidget);
        await shot(tester, '01_offline');
        break;

      case 'waiting':
        if (find.byKey(const Key('go_online_button')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('go_online_button')));
          await waitFor(
            tester,
            find.byKey(const Key('waiting_for_offer')),
            timeout: const Duration(seconds: 40),
          );
        } else {
          await waitFor(tester, find.byKey(const Key('waiting_for_offer')));
        }
        await shot(tester, '02_online_waiting');
        break;

      case 'accept':
        if (find.byKey(const Key('go_online_button')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('go_online_button')));
          await pumpFrames(tester, const Duration(seconds: 2));
        }
        // Arm a fresh OFFERED row after login (30s server timeout).
        File(shotMarker).writeAsStringSync('${prefix}_arm_offer\n');
        await pumpFrames(tester, const Duration(seconds: 3));
        await tester.tap(find.byKey(const Key('home_refresh')));
        await waitFor(
          tester,
          find.byKey(const Key('offer_card')),
          timeout: const Duration(seconds: 40),
        );
        await shot(tester, '03_active_offer');
        final accept = find.byKey(const Key('offer_accept_button'));
        expect(tester.widget<FilledButton>(accept).onPressed, isNotNull);
        await tester.tap(accept);
        await pumpFrames(tester, const Duration(milliseconds: 600));
        await shot(tester, '04_accept_loading');
        // Second tap must be ignored while busy / after navigation.
        if (accept.evaluate().isNotEmpty) {
          await tester.tap(accept, warnIfMissed: false);
        }
        await waitFor(
          tester,
          find.text(AppStrings.deliveryTitle),
          timeout: const Duration(seconds: 50),
        );
        await shot(tester, '05_accepted_current_delivery');
        break;

      case 'reject':
        if (find.byKey(const Key('go_online_button')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('go_online_button')));
          await pumpFrames(tester, const Duration(seconds: 2));
        }
        File(shotMarker).writeAsStringSync('${prefix}_arm_offer\n');
        await pumpFrames(tester, const Duration(seconds: 3));
        await tester.tap(find.byKey(const Key('home_refresh')));
        await waitFor(tester, find.byKey(const Key('offer_card')));
        await tester.tap(find.byKey(const Key('offer_reject_button')));
        await waitFor(
          tester,
          find.byKey(const Key('waiting_for_offer')),
          timeout: const Duration(seconds: 40),
        );
        await shot(tester, '06_reject_waiting');
        break;

      case 'expire':
        if (find.byKey(const Key('go_online_button')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('go_online_button')));
          await pumpFrames(tester, const Duration(seconds: 2));
        }
        File(shotMarker).writeAsStringSync('${prefix}_arm_offer\n');
        await pumpFrames(tester, const Duration(seconds: 3));
        await tester.tap(find.byKey(const Key('home_refresh')));
        await waitFor(tester, find.byKey(const Key('offer_card')));
        await shot(tester, '07_offer_before_expire');
        // Wait past server expiresAt (~8s remaining + buffer).
        await pumpFrames(tester, const Duration(seconds: 14));
        final acceptBtn = find.byKey(const Key('offer_accept_button'));
        if (acceptBtn.evaluate().isNotEmpty) {
          final button = tester.widget<FilledButton>(acceptBtn);
          expect(button.onPressed, isNull);
        }
        await shot(tester, '08_expired_offer');
        break;

      case 'arabic':
        await tester.tap(find.byKey(const Key('home_language')));
        await waitFor(tester, find.byKey(const Key('language-option-ar')));
        await tester.tap(find.byKey(const Key('language-option-ar')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const Key('language-apply')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await waitFor(
          tester,
          find.byKey(const Key('availability_card')),
          timeout: const Duration(seconds: 20),
        );
        if (find.byKey(const Key('go_online_button')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('go_online_button')));
          await pumpFrames(tester, const Duration(seconds: 2));
        }
        File(shotMarker).writeAsStringSync('${prefix}_arm_offer\n');
        await pumpFrames(tester, const Duration(seconds: 3));
        await tester.tap(find.byKey(const Key('home_refresh')));
        await waitFor(
          tester,
          find.byKey(const Key('offer_card')),
          timeout: const Duration(seconds: 40),
        );
        expect(find.text('قبول'), findsOneWidget);
        await shot(tester, '09_arabic_rtl_offer');
        break;

      default:
        throw TestFailure('Unknown LIVE_OFFERS_PHASE=$phase');
    }

    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    await pumpFrames(tester, const Duration(seconds: 1));
  });
}
