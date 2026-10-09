import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_api.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_models.dart';
import 'package:speedygo_driver_app/features/earnings/presentation/earnings_screen.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';
import 'package:speedygo_driver_app/features/history/data/history_api.dart';
import 'package:speedygo_driver_app/features/history/data/history_models.dart';
import 'package:speedygo_driver_app/features/history/presentation/history_detail_screen.dart';
import 'package:speedygo_driver_app/features/history/presentation/history_screen.dart';

HistoryItem _item(int n, {String earning = '45000'}) => HistoryItem(
  deliveryId: 'd$n',
  orderPublicReference: 'SG-$n',
  deliveryStatus: 'DELIVERED',
  deliveredAt: '2026-10-09T10:30:00.000Z',
  merchantName: 'Pizza $n',
  branchName: 'Alger Centre',
  paymentMethod: 'COD',
  earningAmountMinor: earning,
  currency: 'DZD',
);

Widget _app(String locale, Widget home, List<Override> overrides) {
  AppStrings.bind(locale);
  return ProviderScope(
    overrides: [
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      ...overrides,
    ],
    child: MaterialApp(
      locale: Locale(locale),
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  tearDown(() => AppStrings.bind('fr'));

  group('money formatting (integer minor units)', () {
    test('formats without float math, FR and AR', () {
      AppStrings.bind('fr');
      expect(AppStrings.formatMinorUnits('0'), '0 DA');
      expect(AppStrings.formatMinorUnits('45000'), '450 DA');
      expect(AppStrings.formatMinorUnits('45050'), '450.50 DA');
      expect(AppStrings.formatMinorUnits('5'), '0.05 DA');
      expect(
        AppStrings.formatMinorUnits('-250'),
        '-2.5'.replaceAll('.5', '.50') + ' DA',
      );
      expect(AppStrings.formatMinorUnits('garbage'), '0 DA');
      AppStrings.bind('ar');
      expect(AppStrings.formatMinorUnits('45000'), '450 د.ج');
    });

    test('new Stitch strings exist in both languages', () {
      final fr = <String>[];
      final ar = <String>[];
      for (final code in ['fr', 'ar']) {
        AppStrings.bind(code);
        (code == 'fr' ? fr : ar).addAll([
          AppStrings.historyTitle,
          AppStrings.historyEmpty,
          AppStrings.earningsTitle,
          AppStrings.codRemitTitle,
          AppStrings.codRemitSubmit,
          AppStrings.codOutstanding,
          AppStrings.notificationsTitle,
          AppStrings.logoutConfirmTitle,
          AppStrings.deliveredSuccess,
          AppStrings.navUnavailable,
        ]);
      }
      for (var i = 0; i < fr.length; i++) {
        expect(fr[i], isNotEmpty);
        expect(ar[i], isNotEmpty);
        expect(fr[i], isNot(ar[i]));
      }
    });
  });

  group('history', () {
    test('controller paginates by offset and keeps order', () async {
      final client = FakeHistoryClient(
        items: List.generate(35, (i) => _item(i)),
      );
      final container = ProviderContainer(
        overrides: [historyClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);
      final controller = container.read(historyControllerProvider.notifier);
      await controller.load();
      expect(container.read(historyControllerProvider).items.length, 30);
      expect(container.read(historyControllerProvider).hasMore, isTrue);
      await controller.loadMore();
      final state = container.read(historyControllerProvider);
      expect(state.items.length, 35);
      expect(state.hasMore, isFalse);
      expect(state.items.last.deliveryId, 'd34');
    });

    for (final locale in ['fr', 'ar']) {
      testWidgets('empty state ($locale)', (tester) async {
        _phone(tester);
        await tester.pumpWidget(
          _app(locale, const HistoryScreen(), [
            historyClientProvider.overrideWithValue(FakeHistoryClient()),
          ]),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.historyEmpty), findsOneWidget);
      });

      testWidgets('list shows reference, merchant and earning ($locale)', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(
          _app(locale, const HistoryScreen(), [
            historyClientProvider.overrideWithValue(
              FakeHistoryClient(
                items: [
                  _item(1),
                  _item(2, earning: '12050'),
                ],
              ),
            ),
          ]),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('history_item_d1')), findsOneWidget);
        expect(find.textContaining('SG-1'), findsWidgets);
        expect(find.textContaining('Pizza 1'), findsWidgets);
        expect(
          find.textContaining(AppStrings.formatMinorUnits('45000')),
          findsWidgets,
        );
        expect(
          find.textContaining(AppStrings.formatMinorUnits('12050')),
          findsWidgets,
        );
      });
    }

    testWidgets('detail shows recognized earning, not COD', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app('fr', const HistoryDetailScreen(deliveryId: 'd1'), [
          historyClientProvider.overrideWithValue(
            FakeHistoryClient(items: [_item(1)]),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history_detail_earning')), findsOneWidget);
      expect(find.text('450 DA'), findsWidgets);
      expect(find.text(AppStrings.historyEarningNote), findsOneWidget);
    });
  });

  group('earnings + COD', () {
    EarningItem earning(int n) => EarningItem(
      earningId: 'e$n',
      deliveryId: 'd$n',
      orderId: 'o$n',
      amountMinor: '30000',
      currency: 'DZD',
      earnedAt: '2026-10-09T09:00:00.000Z',
    );

    FakeEarningsClient client({
      String outstanding = '150000',
      int open = 0,
      Future<void> Function(int)? remit,
    }) => FakeEarningsClient(
      summaryValue: const EarningsSummary(
        totalEarnedMinor: '90000',
        unpaidEarnedMinor: '60000',
        earningCount: 3,
        currency: 'DZD',
      ),
      items: [earning(1), earning(2), earning(3)],
      cod: CodSummary(
        outstandingCustodyMinor: outstanding,
        collectedAmountMinor: '200000',
        confirmedAllocatedMinor: '50000',
        openDeclaredCount: open,
      ),
      remittanceHandler: remit,
    );

    for (final locale in ['fr', 'ar']) {
      testWidgets('earnings and COD are separate cards ($locale)', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(
          _app(locale, const EarningsScreen(), [
            earningsClientProvider.overrideWithValue(client()),
          ]),
        );
        await tester.pumpAndSettle();
        final total = tester.widget<Text>(
          find.byKey(const Key('earnings_total')),
        );
        expect(total.data, AppStrings.formatMinorUnits('90000'));
        final unpaid = tester.widget<Text>(
          find.byKey(const Key('earnings_unpaid')),
        );
        expect(unpaid.data, AppStrings.formatMinorUnits('60000'));
        await tester.scrollUntilVisible(
          find.byKey(const Key('cod_outstanding')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final outstanding = tester.widget<Text>(
          find.byKey(const Key('cod_outstanding')),
        );
        expect(outstanding.data, AppStrings.formatMinorUnits('150000'));
        // Earnings total must never equal COD custody display by construction.
        expect(total.data, isNot(outstanding.data));
      });
    }

    testWidgets('remittance requires outstanding custody and no open one', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        _app('fr', const EarningsScreen(), [
          earningsClientProvider.overrideWithValue(client(open: 1)),
        ]),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('cod_summary_card')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('remit_amount_field')), findsNothing);
    });

    testWidgets('remittance submits integer minor units and clears field', (
      tester,
    ) async {
      _phone(tester);
      final api = client();
      int? sent;
      api.remittanceHandler = (amount) async => sent = amount;
      await tester.pumpWidget(
        _app('fr', const EarningsScreen(), [
          earningsClientProvider.overrideWithValue(api),
        ]),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('remit_amount_field')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final submit = find.byKey(const Key('remit_submit_button'));
      await tester.ensureVisible(submit);
      expect(tester.widget<OutlinedButton>(submit).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('remit_amount_field')),
        '1x5000',
      );
      await tester.pump();
      expect(tester.widget<OutlinedButton>(submit).onPressed, isNotNull);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(sent, 15000);
      final field = tester.widget<TextField>(
        find.byKey(const Key('remit_amount_field')),
      );
      expect(field.controller?.text ?? '', isEmpty);
    });
  });
}
