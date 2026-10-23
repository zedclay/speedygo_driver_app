import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';

/// Live navigation smoke against isolated API :3100.
///
/// Phases: `a` no-session | `b` approved home | `d` active delivery | `f` logout
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const isolatedApi = 'http://127.0.0.1:3100/api/v1';
  const otpFilePath = String.fromEnvironment('FX_OTP_FILE');
  const evidenceDir = String.fromEnvironment('FX_EVIDENCE_DIR');
  const prefix = String.fromEnvironment('PARITY_PREFIX', defaultValue: 'fxnav');
  const phase = String.fromEnvironment('LIVE_NAV_PHASE', defaultValue: 'a');
  const secretsPath = String.fromEnvironment('FX_SECRETS_PATH');
  const shotMarker = '/tmp/parity_fx_nav_smoke_shot.txt';
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

  Future<void> marker(WidgetTester tester, String tag) async {
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
    await pumpFrames(tester, const Duration(seconds: 8));
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
  }

  testWidgets('live navigation smoke phase $phase', (tester) async {
    expect(AppConstants.apiBaseUrl, isolatedApi);
    expect(evidenceDir.isNotEmpty, isTrue);

    switch (phase) {
      case 'a':
        await pumpApp(tester);
        // Splash first (may already have resolved); land on phone.
        await waitFor(
          tester,
          find.byKey(const Key('phone_continue')),
          timeout: const Duration(seconds: 40),
        );
        expect(find.byKey(const Key('splash_screen')), findsNothing);
        expect(find.byKey(const Key('nav_orders')), findsNothing);
        expect(find.byKey(const Key('nav_history')), findsNothing);
        expect(find.byKey(const Key('availability_card')), findsNothing);
        await shot(tester, 'a_phone_after_splash');
        // Attempt deep navigation — redirect must keep auth.
        final ctx = tester.element(find.byKey(const Key('phone_continue')));
        GoRouter.of(ctx).go(AppRoutes.home);
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('phone_continue')), findsOneWidget);
        expect(find.byKey(const Key('availability_card')), findsNothing);
        await shot(tester, 'a_blocked_home_redirect');
        // Back must not resurrect Splash.
        GoRouter.of(ctx).go(AppRoutes.splash);
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('splash_screen')), findsNothing);
        expect(find.byKey(const Key('phone_continue')), findsOneWidget);
        break;

      case 'b':
        expect(otpFilePath.isNotEmpty, isTrue);
        await pumpApp(tester);
        await login(tester);
        await waitFor(
          tester,
          find.byKey(const Key('availability_card')),
          timeout: const Duration(seconds: 60),
        );
        expect(find.byKey(const Key('nav_orders')), findsOneWidget);
        expect(find.byKey(const Key('nav_history')), findsOneWidget);
        expect(find.byKey(const Key('nav_earnings')), findsOneWidget);
        expect(find.byKey(const Key('nav_profile')), findsOneWidget);
        expect(find.byKey(const Key('open_current_delivery')), findsNothing);
        expect(find.textContaining('onboarding'), findsNothing);
        await shot(tester, 'b_home_approved');

        await tester.tap(find.byKey(const Key('nav_history')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await tester.tap(find.byKey(const Key('nav_earnings')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await tester.tap(find.byKey(const Key('nav_orders')));
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('availability_card')), findsOneWidget);
        await shot(tester, 'b_tabs_stable');

        await tester.tap(find.byKey(const Key('shell_profile_button')));
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('profile_name')), findsOneWidget);
        expect(find.byKey(const Key('logout_confirm')), findsNothing);
        await shot(tester, 'b_profile_from_avatar');

        await tester.tap(find.byKey(const Key('profile_vehicle')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await shot(tester, 'b_nested_vehicle');
        final back = find.byType(BackButton);
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back);
        } else {
          await tester.pageBack();
        }
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('profile_name')), findsOneWidget);

        await tester.tap(find.byKey(const Key('shell_notifications')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await shot(tester, 'b_notifications');
        if (find.byType(BackButton).evaluate().isNotEmpty) {
          await tester.tap(find.byType(BackButton));
        } else {
          await tester.pageBack();
        }
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('profile_name')), findsOneWidget);

        // FR→AR via Settings; preserve Profile lane then return to Home.
        await tester.tap(find.byKey(const Key('nav_profile')));
        await pumpFrames(tester, const Duration(seconds: 1));
        await tester.tap(find.byKey(const Key('profile_settings')));
        await pumpFrames(tester, const Duration(seconds: 1));
        await waitFor(tester, find.byKey(const Key('settings_language')));
        await tester.tap(find.byKey(const Key('settings_language')));
        await waitFor(tester, find.byKey(const Key('language-option-ar')));
        await tester.tap(find.byKey(const Key('language-option-ar')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const Key('language-apply')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await shot(tester, 'b_ar_after_language');
        // Language + settings are pushed outside the shell — pop back.
        for (var i = 0; i < 3; i++) {
          if (find.byKey(const Key('nav_orders')).evaluate().isNotEmpty) {
            break;
          }
          if (find.byType(BackButton).evaluate().isNotEmpty) {
            await tester.tap(find.byType(BackButton));
            await pumpFrames(tester, const Duration(seconds: 1));
          } else {
            await tester.pageBack();
            await pumpFrames(tester, const Duration(seconds: 1));
          }
        }
        await waitFor(tester, find.byKey(const Key('nav_orders')));
        await tester.tap(find.byKey(const Key('nav_orders')));
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('availability_card')), findsOneWidget);
        await shot(tester, 'b_home_after_locale');
        break;

      case 'd':
        expect(otpFilePath.isNotEmpty, isTrue);
        expect(secretsPath.isNotEmpty, isTrue);
        final secrets = jsonDecode(
          File(secretsPath).readAsStringSync(),
        ) as Map<String, dynamic>;
        expect(secrets['hasActiveDelivery'], isTrue);

        await pumpApp(tester);
        await login(tester);
        await waitFor(
          tester,
          find.byKey(const Key('delivery_status_card')),
          timeout: const Duration(seconds: 60),
        );
        expect(
          find.text(AppStrings.deliveryStatusLabel('DRIVER_ASSIGNED')),
          findsWidgets,
        );
        expect(find.byKey(const Key('availability_card')), findsNothing);
        expect(find.byKey(const Key('offer_card')), findsNothing);
        await shot(tester, 'd_cold_start_current_delivery');

        // Back to Home must preserve resume CTA.
        await tester.tap(find.byKey(const Key('delivery_back_home')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await waitFor(tester, find.byKey(const Key('open_current_delivery')));
        await shot(tester, 'd_home_with_active_banner');
        await tester.tap(find.byKey(const Key('open_current_delivery')));
        await waitFor(tester, find.byKey(const Key('delivery_status_card')));
        expect(
          find.text(AppStrings.deliveryStatusLabel('DRIVER_ASSIGNED')),
          findsWidgets,
        );
        await shot(tester, 'd_resume_same_stage');

        // Relaunch restores delivery (re-auth with MemorySessionStore).
        await pumpApp(tester);
        await login(tester);
        await waitFor(
          tester,
          find.byKey(const Key('delivery_status_card')),
          timeout: const Duration(seconds: 60),
        );
        expect(
          find.text(AppStrings.deliveryStatusLabel('DRIVER_ASSIGNED')),
          findsWidgets,
        );
        await shot(tester, 'd_relaunch_current_delivery');
        break;

      case 'f':
        expect(otpFilePath.isNotEmpty, isTrue);
        await pumpApp(tester);
        await login(tester);
        await waitFor(
          tester,
          find.byKey(const Key('availability_card')),
          timeout: const Duration(seconds: 60),
        );
        await tester.tap(find.byKey(const Key('nav_profile')));
        await pumpFrames(tester, const Duration(seconds: 2));
        await tester.ensureVisible(find.byKey(const Key('logout')));
        await tester.tap(find.byKey(const Key('logout')));
        await pumpFrames(tester, const Duration(seconds: 1));
        await waitFor(tester, find.byKey(const Key('logout_confirm')));
        await shot(tester, 'f_logout_confirm');
        await tester.tap(find.byKey(const Key('confirmation_cancel')));
        await pumpFrames(tester, const Duration(seconds: 1));
        expect(find.byKey(const Key('profile_name')), findsOneWidget);
        expect(find.byKey(const Key('logout_confirm')), findsNothing);
        await shot(tester, 'f_logout_cancelled');

        await tester.ensureVisible(find.byKey(const Key('logout')));
        await tester.tap(find.byKey(const Key('logout')));
        await waitFor(tester, find.byKey(const Key('logout_confirm')));
        await tester.tap(find.byKey(const Key('logout_confirm')));
        await pumpFrames(tester, const Duration(seconds: 3));
        await waitFor(tester, find.byKey(const Key('phone_continue')));
        expect(find.byKey(const Key('availability_card')), findsNothing);
        expect(find.byKey(const Key('nav_profile')), findsNothing);
        await shot(tester, 'f_logged_out_phone');
        final ctx = tester.element(find.byKey(const Key('phone_continue')));
        GoRouter.of(ctx).go(AppRoutes.home);
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('phone_continue')), findsOneWidget);
        GoRouter.of(ctx).go(AppRoutes.profile);
        await pumpFrames(tester, const Duration(seconds: 2));
        expect(find.byKey(const Key('phone_continue')), findsOneWidget);
        await shot(tester, 'f_back_blocked');
        break;

      default:
        throw TestFailure('unknown LIVE_NAV_PHASE=$phase');
    }

    File(shotMarker).writeAsStringSync('${prefix}_99_done\n');
    await pumpFrames(tester, const Duration(seconds: 2));
  }, timeout: const Timeout(Duration(minutes: 12)));
}
