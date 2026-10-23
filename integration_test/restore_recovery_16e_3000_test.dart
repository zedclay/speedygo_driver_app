import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';

/// Client-side restore fault. Does not stop Backend or change auth rules.
/// Login and successful retry still use the wrapped live AuthApi.
class InjectedRestoreFaultClient implements AuthClient {
  InjectedRestoreFaultClient(
    this.inner, {
    required this.failMe,
    required this.delay,
  });

  final AuthClient inner;
  final bool failMe;
  final Duration delay;
  int meStarts = 0;
  int meInFlight = 0;
  int meMaxInFlight = 0;

  @override
  Future<void> requestOtp(String identifier) => inner.requestOtp(identifier);

  @override
  Future<TokenPair> verifyOtp(OtpVerifyBody body) => inner.verifyOtp(body);

  @override
  Future<TokenPair> refresh(String refreshToken) => inner.refresh(refreshToken);

  @override
  Future<void> logout() => inner.logout();

  @override
  Future<AuthMe> me() async {
    meStarts += 1;
    meInFlight += 1;
    if (meInFlight > meMaxInFlight) meMaxInFlight = meInFlight;
    try {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (failMe) {
        throw const NetworkException(
          'injected restore fault',
          code: 'NETWORK',
        );
      }
      return await inner.me();
    } finally {
      meInFlight -= 1;
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const expectedApi = String.fromEnvironment(
    'EXPECTED_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api/v1',
  );
  const phase = String.fromEnvironment(
    'RESTORE_PHASE',
    defaultValue: 'login',
  );
  const phone = String.fromEnvironment('RESTORE_PHONE');
  const otpPath = String.fromEnvironment('SPEEDYGO_DEV_OTP_FILE');
  const evidDir = String.fromEnvironment('RESTORE_EVIDENCE_DIR');
  const shotMarker = String.fromEnvironment(
    'RESTORE_SHOT_FILE',
    defaultValue: '/tmp/speedygo_driver_restore_16e_shot.txt',
  );

  InjectedRestoreFaultClient? fault;

  Future<void> pumpFrames(WidgetTester tester, int ticks) async {
    for (var i = 0; i < ticks; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> waitFinder(
    WidgetTester tester,
    Finder finder, {
    int ticks = 80,
  }) async {
    for (var i = 0; i < ticks; i++) {
      if (finder.evaluate().isNotEmpty) return true;
      await tester.pump(const Duration(milliseconds: 100));
    }
    return false;
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    if (evidDir.isEmpty) return;
    Directory(evidDir).createSync(recursive: true);
    File(shotMarker).writeAsStringSync('driver_restore_$tag');
    await pumpFrames(tester, 8);
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  Future<void> writeResult(Map<String, Object?> body) async {
    if (evidDir.isEmpty) return;
    Directory(evidDir).createSync(recursive: true);
    File('$evidDir/driver_restore_$phase.json').writeAsStringSync(
      '${jsonEncode(body)}\n',
    );
  }

  Future<String> waitOtp() async {
    final file = File(otpPath);
    for (var i = 0; i < 40; i++) {
      if (file.existsSync()) {
        final code = file.readAsStringSync().trim();
        if (RegExp(r'^\d{6}$').hasMatch(code)) return code;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    throw StateError('OTP capture missing');
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          if (phase == 'fail')
            authApiProvider.overrideWith((ref) {
              final inner = AuthApi(
                dio: ref.watch(apiClientProvider),
                refreshDio: ref.watch(refreshDioProvider),
              );
              fault = InjectedRestoreFaultClient(
                inner,
                failMe: true,
                delay: const Duration(milliseconds: 900),
              );
              return fault!;
            }),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    await pumpFrames(tester, 30);
  }

  Future<void> skipIntro(WidgetTester tester) async {
    if (await waitFinder(
      tester,
      find.byKey(const Key('first_launch_intro_skip')),
      ticks: 40,
    )) {
      await tester.tap(find.byKey(const Key('first_launch_intro_skip')));
      await pumpFrames(tester, 20);
    }
  }

  Future<void> loginUi(WidgetTester tester) async {
    expect(phone.isNotEmpty, isTrue);
    await skipIntro(tester);
    expect(
      await waitFinder(
        tester,
        find.byKey(const Key('phone_continue')),
        ticks: 120,
      ),
      isTrue,
    );
    await tester.enterText(find.byKey(const Key('phone_field')), phone);
    await tester.pump();
    await tester.tap(find.byKey(const Key('phone_continue')));
    expect(
      await waitFinder(tester, find.byKey(const Key('otp_field')), ticks: 80),
      isTrue,
    );
    final code = await waitOtp();
    await tester.enterText(find.byKey(const Key('otp_field')), code);
    await tester.pump();
    await tester.tap(find.byKey(const Key('otp_verify')));
    await pumpFrames(tester, 40);
    await skipIntro(tester);
  }

  Future<void> expectGuardedRoute(WidgetTester tester) async {
    for (var i = 0; i < 400; i++) {
      final authed =
          find.byKey(const Key('onboarding_logout')).evaluate().isNotEmpty ||
          find.byKey(const Key('onboarding_progress')).evaluate().isNotEmpty ||
          find.byKey(const Key('availability_card')).evaluate().isNotEmpty ||
          find.byKey(const Key('shell_bottom_nav')).evaluate().isNotEmpty ||
          find.byKey(const Key('onboarding_status_cta')).evaluate().isNotEmpty ||
          find.byKey(const Key('status_account_menu')).evaluate().isNotEmpty;
      final recoveryGone =
          find.byKey(const Key('splash_restore_retry')).evaluate().isEmpty;
      final phoneGone =
          find.byKey(const Key('phone_continue')).evaluate().isEmpty;
      if (authed && recoveryGone && phoneGone) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('expected guarded driver route after restore');
  }

  testWidgets('driver restore recovery 16e $phase', (tester) async {
    expect(AppConstants.apiBaseUrl, expectedApi);
    expect(AppConstants.speedyGoAppAudience, 'DRIVER');
    final store = SecureSessionStore();
    if (phase == 'login') {
      await store.clear();
    }

    await pumpApp(tester);

    if (phase == 'login') {
      await loginUi(tester);
      await expectGuardedRoute(tester);
      await shot(tester, 'login_signed_in');
      expect(await store.read(), isNotNull);
      expect(find.byKey(const Key('phone_continue')), findsNothing);
      await writeResult({
        'app': 'DRIVER',
        'phase': phase,
        'kind': 'device_live_login',
        'api': AppConstants.apiBaseUrl,
        'fixture': phone,
        'sessionPresent': true,
        'otpUsed': true,
        'result': 'PASS',
      });
      return;
    }

    if (phase == 'fail') {
      expect(
        await waitFinder(
          tester,
          find.byKey(const Key('splash_restore_retry')),
          ticks: 80,
        ),
        isTrue,
      );
      expect(await store.read(), isNotNull);
      expect(find.byKey(const Key('phone_continue')), findsNothing);
      expect(find.byKey(const Key('availability_card')), findsNothing);
      expect(find.byKey(const Key('go_online_button')), findsNothing);

      Future<void> applyLocale(String optionKey) async {
        await tester.tap(find.byKey(const Key('splash_restore_language')));
        expect(
          await waitFinder(
            tester,
            find.byKey(Key(optionKey)),
            ticks: 40,
          ),
          isTrue,
        );
        await tester.tap(find.byKey(Key(optionKey)));
        await tester.pump();
        final apply = find.byKey(const Key('language-apply'));
        final button = tester.widget<FilledButton>(apply);
        if (button.onPressed != null) {
          await tester.tap(apply);
        } else {
          await tester.pageBack();
        }
        for (var i = 0; i < 40; i++) {
          if (find.byKey(const Key('language-settings-screen')).evaluate().isEmpty) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          find.byKey(const Key('language-settings-screen')),
          findsNothing,
        );
        expect(
          await waitFinder(
            tester,
            find.byKey(const Key('splash_restore_retry')),
            ticks: 40,
          ),
          isTrue,
        );
      }

      await applyLocale('language-option-fr');
      expect(find.text('Réessayer'), findsOneWidget);
      expect(
        find.text(
          'Impossible de rétablir la session. Vérifiez la connexion puis réessayez.',
        ),
        findsOneWidget,
      );
      await shot(tester, 'fail_fr');

      await applyLocale('language-option-ar');
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(
        find.text('تعذّر استعادة الجلسة. تحقق من الاتصال ثم أعد المحاولة.'),
        findsOneWidget,
      );
      final direction = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(direction.textDirection, TextDirection.rtl);
      expect(await store.read(), isNotNull);
      await shot(tester, 'fail_ar_rtl');

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );
      final startsBefore = fault?.meStarts ?? 0;
      final first = container
          .read(sessionControllerProvider.notifier)
          .retryRestore();
      final second = container
          .read(sessionControllerProvider.notifier)
          .retryRestore();
      expect(identical(first, second), isTrue);
      await first;
      await pumpFrames(tester, 8);
      final maxInFlight = fault?.meMaxInFlight ?? 0;
      final startsAfter = fault?.meStarts ?? 0;
      expect(maxInFlight, 1);
      expect(startsAfter - startsBefore, 1);
      expect(find.byKey(const Key('splash_restore_retry')), findsOneWidget);
      expect(await store.read(), isNotNull);
      expect(find.byKey(const Key('phone_continue')), findsNothing);

      await writeResult({
        'app': 'DRIVER',
        'phase': phase,
        'kind': 'device_injected_client_fault',
        'injection': 'AuthClient.me NetworkException delay 900ms',
        'api': AppConstants.apiBaseUrl,
        'fixture': phone,
        'sessionPresent': true,
        'otpUsed': false,
        'rtl': true,
        'meStartsDelta': startsAfter - startsBefore,
        'meMaxInFlight': maxInFlight,
        'result': 'PASS',
      });
      return;
    }

    if (phase == 'retry') {
      await expectGuardedRoute(tester);
      expect(find.byKey(const Key('splash_restore_retry')), findsNothing);
      expect(find.byKey(const Key('phone_continue')), findsNothing);
      expect(await store.read(), isNotNull);
      await shot(tester, 'retry_guarded_route');
      await writeResult({
        'app': 'DRIVER',
        'phase': phase,
        'kind': 'device_live_retry',
        'api': AppConstants.apiBaseUrl,
        'fixture': phone,
        'sessionPresent': true,
        'otpUsed': false,
        'result': 'PASS',
      });
      return;
    }

    fail('unknown RESTORE_PHASE=$phase');
  });
}
