import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/locale/locale_support.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/current_delivery_screen.dart';
import 'package:speedygo_driver_app/features/settings/presentation/language_settings_screen.dart';

DriverCurrentDelivery atPickup() => const DriverCurrentDelivery(
  assignmentId: 'asg-1',
  assignmentVersion: 1,
  deliveryId: 'del-1',
  orderId: 'ord-1',
  deliveryStatus: 'AT_PICKUP',
  orderStatus: 'ACTIVE',
  fulfillmentStatus: 'READY',
  assignmentStatus: 'ACCEPTED',
  allowedActions: ['confirm-pickup'],
  pickedUpAt: null,
  arrivedCustomerAt: null,
  deliveredAt: null,
);

Widget _app({
  required String locale,
  required Widget home,
  MemoryLocaleStore? localeStore,
  List overrides = const [],
  double textScale = 1.0,
}) {
  AppStrings.bind(locale);
  final store = localeStore ?? MemoryLocaleStore(locale: locale);
  return ProviderScope(
    overrides: [
      localeStoreProvider.overrideWithValue(store),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      ...overrides,
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [Locale('fr'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: locale == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        ),
        home: home,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ARB FR/AR key sets match', () {
    final fr = jsonDecode(
      File('lib/l10n/app_fr.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final ar = jsonDecode(
      File('lib/l10n/app_ar.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final frKeys = fr.keys.where((k) => !k.startsWith('@')).toSet();
    final arKeys = ar.keys.where((k) => !k.startsWith('@')).toSet();
    expect(frKeys, arKeys);
  });

  test('resolveInitialLanguageCode prefers stored then supported system', () {
    expect(resolveInitialLanguageCode(stored: 'ar'), 'ar');
    expect(resolveInitialLanguageCode(stored: 'fr'), 'fr');
    expect(
      resolveInitialLanguageCode(
        stored: null,
        platform: const Locale('ar', 'DZ'),
      ),
      'ar',
    );
    expect(
      resolveInitialLanguageCode(
        stored: null,
        platform: const Locale('en', 'US'),
      ),
      'fr',
    );
  });

  test('error and status strings differ by locale without leaking codes', () {
    AppStrings.bind('fr');
    expect(AppStrings.errorForCode('PICKUP_HANDOFF_CODE_INVALID'), contains('incorrect'));
    expect(AppStrings.deliveryStatusLabel('AT_PICKUP'), contains('commerçant'));
    AppStrings.bind('ar');
    expect(AppStrings.errorForCode('PICKUP_HANDOFF_CODE_INVALID'), isNot(contains('incorrect')));
    expect(RegExp(r'[\u0600-\u06FF]').hasMatch(AppStrings.deliveryTitle), isTrue);
    expect(AppStrings.errorForCode('PICKUP_HANDOFF_CODE_INVALID'), isNot(contains('PICKUP_')));
  });

  testWidgets('language settings switches locale and persists', (tester) async {
    final store = MemoryLocaleStore(locale: 'fr');
    await tester.pumpWidget(
      _app(
        locale: 'fr',
        localeStore: store,
        home: const LanguageSettingsScreen(),
      ),
    );
    expect(find.byKey(const Key('language-option-fr')), findsOneWidget);
    expect(find.byKey(const Key('language-option-ar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('language-option-ar')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('language-apply')));
    await tester.pumpAndSettle();
    expect(await store.read(), 'ar');
    expect(AppStrings.languageCode, 'ar');
  });

  testWidgets('AT_PICKUP FR/AR at 390x844 and scale 1.3 without overflow', (
    tester,
  ) async {
    final fake = FakeDeliveryClient(current: atPickup());
    for (final locale in ['fr', 'ar']) {
      for (final scale in [1.0, 1.3]) {
        await tester.pumpWidget(
          _app(
            locale: locale,
            textScale: scale,
            overrides: [deliveryClientProvider.overrideWithValue(fake)],
            home: const CurrentDeliveryScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('pickup_code_field')), findsOneWidget);
        expect(find.byKey(const Key('confirm_pickup_button')), findsOneWidget);
        final button = tester.getSize(find.byKey(const Key('confirm_pickup_button')));
        expect(button.height, greaterThanOrEqualTo(48));
        expect(find.byType(OverflowBar), findsNothing);
      }
    }
  });

  testWidgets('RTL Directionality is active for Arabic delivery screen', (
    tester,
  ) async {
    final fake = FakeDeliveryClient(current: atPickup());
    await tester.pumpWidget(
      _app(
        locale: 'ar',
        overrides: [deliveryClientProvider.overrideWithValue(fake)],
        home: const CurrentDeliveryScreen(),
      ),
    );
    await tester.pumpAndSettle();
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('pickup draft survives recoverable invalid-code failure', (
    tester,
  ) async {
    final fake = FakeDeliveryClient(
      current: atPickup(),
      confirmHandler: (_) async {
        throw ApiException(
          AppStrings.codeInvalid,
          code: 'PICKUP_HANDOFF_CODE_INVALID',
        );
      },
    );
    await tester.pumpWidget(
      _app(
        locale: 'fr',
        overrides: [deliveryClientProvider.overrideWithValue(fake)],
        home: const CurrentDeliveryScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pickup_code_field')), '1234');
    await tester.tap(find.byKey(const Key('confirm_pickup_button')));
    await tester.pumpAndSettle();
    expect(find.text('1234'), findsOneWidget);
    expect(find.text(AppStrings.codeInvalid), findsOneWidget);
  });
}
