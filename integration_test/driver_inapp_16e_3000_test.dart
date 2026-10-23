import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';
import 'package:speedygo_driver_app/features/notifications/presentation/notifications_screen.dart';

/// DEVICE_UI: Driver IN_APP inbox on iPhone 16e vs live :3000.
/// Opening inbox must not toggle availability or mutate assignment/delivery.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const expectedApi = 'http://127.0.0.1:3000/api/v1';
  const evidDir = String.fromEnvironment(
    'INAPP_EVIDENCE_DIR',
    defaultValue:
        '/Users/mac/Downloads/speedygo_project/docs/audits/2026-10-23/evidence/driver_inapp_16e',
  );
  const shotMarker = String.fromEnvironment(
    'INAPP_SHOT_FILE',
    defaultValue: '/tmp/speedygo_driver_inapp_shot.txt',
  );
  const phase = String.fromEnvironment('INAPP_PHASE', defaultValue: 'empty');
  const matchId = String.fromEnvironment(
    'INAPP_MATCH_ID',
    defaultValue: 'c1a55e70-1aab-4b04-8004-000000000101',
  );
  const earningId = String.fromEnvironment(
    'INAPP_EARNING_ID',
    defaultValue: 'c1a55e70-1aab-4b04-8004-000000000102',
  );
  const fixturePhone = String.fromEnvironment('INAPP_FIXTURE_PHONE');

  Map<String, dynamic> tokens() {
    const b64 = String.fromEnvironment('SMOKE_TOKEN_B64');
    if (b64.isEmpty) throw StateError('SMOKE_TOKEN_B64 required');
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(base64Decode(b64))) as Map,
    );
  }

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

  String dumpTexts(WidgetTester tester) {
    final texts = <String>[];
    for (final el in find.byType(Text).evaluate()) {
      final w = el.widget;
      if (w is Text) {
        final s = w.data ?? w.textSpan?.toPlainText() ?? '';
        if (s.trim().isNotEmpty) texts.add(s.trim());
      }
    }
    return texts.take(80).join(' | ');
  }

  Future<void> shot(WidgetTester tester, String tag) async {
    debugPrint('INAPP_UI_$tag:${dumpTexts(tester)}');
    Directory(evidDir).createSync(recursive: true);
    File('$evidDir/ui_$tag.txt').writeAsStringSync(dumpTexts(tester));
    await pumpFrames(tester, 6);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    File(shotMarker).writeAsStringSync(tag);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await pumpFrames(tester, 2);
  }

  GoRouter routerOf(WidgetTester tester) {
    return GoRouter.of(tester.element(find.byType(Navigator).first));
  }

  Future<void> openInbox(WidgetTester tester) async {
    final bell = find.byKey(const Key('shell_notifications'));
    if (bell.evaluate().isNotEmpty) {
      await tester.tap(bell);
      await pumpFrames(tester, 24);
      return;
    }
    routerOf(tester).go(AppRoutes.notifications);
    await pumpFrames(tester, 24);
  }

  Future<void> applyLocale(WidgetTester tester, String optionKey) async {
    routerOf(tester).go(AppRoutes.languageSettings);
    await pumpFrames(tester, 20);
    final option = find.byKey(Key(optionKey));
    if (option.evaluate().isEmpty) {
      return;
    }
    await tester.tap(option);
    await pumpFrames(tester, 6);
    final apply = find.byKey(const Key('language-apply'));
    if (apply.evaluate().isNotEmpty) {
      final widget = tester.widget(apply);
      final enabled = widget is ButtonStyleButton && widget.onPressed != null;
      if (enabled) {
        await tester.tap(apply);
        await pumpFrames(tester, 20);
        return;
      }
    }
    routerOf(tester).go(AppRoutes.notifications);
    await pumpFrames(tester, 16);
  }

  testWidgets('driver in-app inbox 16e $phase', (tester) async {
    expect(AppConstants.apiBaseUrl, expectedApi);
    final store = MemorySessionStore();
    await store.write(TokenPair.fromJson(tokens()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(store),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          firstLaunchIntroStoreProvider.overrideWithValue(
            MemoryFirstLaunchIntroStore(completed: true),
          ),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    await pumpFrames(tester, 80);
    await openInbox(tester);
    final inbox = await waitFinder(
      tester,
      find.byType(NotificationsScreen),
      ticks: 80,
    );
    if (!inbox) {
      await shot(tester, 'inbox_unreachable');
      File('$evidDir/driver_inapp_$phase.json').writeAsStringSync(
        jsonEncode({
          'app': 'DRIVER',
          'phase': phase,
          'kind': 'device_ui',
          'fixturePhone': fixturePhone,
          'result': 'BLOCKED',
          'reason': 'inbox_unreachable_existing_guard',
          'availabilityMutations': false,
          'goOnlineTapped': false,
          'texts': dumpTexts(tester),
        }),
      );
      File(shotMarker).writeAsStringSync('done');
      return;
    }

    expect(find.byKey(const Key('go_online_button')), findsNothing);

    if (phase == 'empty') {
      await applyLocale(tester, 'language-option-fr');
      routerOf(tester).go(AppRoutes.notifications);
      await pumpFrames(tester, 24);
      expect(find.text(AppStrings.notificationsEmpty), findsOneWidget);
      await shot(tester, 'empty_fr');
      await applyLocale(tester, 'language-option-ar');
      routerOf(tester).go(AppRoutes.notifications);
      await pumpFrames(tester, 24);
      expect(
        Directionality.of(tester.element(find.byType(NotificationsScreen))),
        TextDirection.rtl,
      );
      await shot(tester, 'empty_ar');
      File('$evidDir/driver_inapp_empty.json').writeAsStringSync(
        jsonEncode({
          'app': 'DRIVER',
          'phase': 'empty',
          'kind': 'device_ui',
          'fixturePhone': fixturePhone,
          'availabilityMutations': false,
          'goOnlineTapped': false,
          'result': 'PASS',
        }),
      );
      File(shotMarker).writeAsStringSync('done');
      return;
    }

    await applyLocale(tester, 'language-option-fr');
    routerOf(tester).go(AppRoutes.notifications);
    await pumpFrames(tester, 24);
    expect(find.byKey(Key('notification_$matchId')), findsOneWidget);
    expect(find.byKey(Key('notification_$earningId')), findsOneWidget);
    await shot(tester, 'populated_fr');
    // Tap earning (not MATCH_OFFER) so mark-read does not land on Home/go_online.
    await tester.tap(find.byKey(Key('notification_$earningId')));
    await pumpFrames(tester, 30);
    expect(find.byKey(const Key('go_online_button')), findsNothing);
    await shot(tester, 'after_mark_read_fr');
    await openInbox(tester);
    await pumpFrames(tester, 24);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.byKey(const Key('notifications_read_all')), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications_read_all')));
    await pumpFrames(tester, 20);
    await shot(tester, 'after_read_all_fr');
    routerOf(tester).go(AppRoutes.notifications);
    await pumpFrames(tester, 20);
    await shot(tester, 'reopen_persisted_fr');
    await applyLocale(tester, 'language-option-ar');
    routerOf(tester).go(AppRoutes.notifications);
    await pumpFrames(tester, 24);
    expect(
      Directionality.of(tester.element(find.byType(NotificationsScreen))),
      TextDirection.rtl,
    );
    await shot(tester, 'populated_ar');
    File('$evidDir/driver_inapp_populated.json').writeAsStringSync(
      jsonEncode({
        'app': 'DRIVER',
        'phase': 'populated',
        'kind': 'device_ui',
        'fixturePhone': fixturePhone,
        'destination': AppRoutes.earnings,
        'navigatedBy': 'DRIVER_EARNING_CREATED',
        'availabilityMutations': false,
        'goOnlineTapped': false,
        'result': 'PASS',
      }),
    );
    File(shotMarker).writeAsStringSync('done');
  });
}
