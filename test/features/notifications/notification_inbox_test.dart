import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/notifications/application/notification_copy.dart';
import 'package:speedygo_driver_app/features/notifications/application/notification_navigation.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';
import 'package:speedygo_driver_app/features/notifications/presentation/notifications_screen.dart';

AppNotification item({
  String id = 'n1',
  String type = 'MATCH_OFFER',
  String title = 'Title',
  String body = 'Body',
  bool read = false,
  String createdAt = '2026-10-23T10:00:00.000Z',
  String sourceId = '11111111-1111-4111-8111-111111111111',
}) {
  return AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    read: read,
    createdAt: createdAt,
    sourceId: sourceId,
  );
}

ProviderContainer inboxContainer(FakeNotificationsClient client) {
  return ProviderContainer(
    overrides: [notificationsClientProvider.overrideWithValue(client)],
  );
}

Future<void> settleInbox(ProviderContainer container) async {
  container.listen(notificationsControllerProvider, (_, _) {});
  container.listen(unreadNotificationsProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FixedLocale extends LocaleController {
  _FixedLocale(this.code);
  final String code;
  @override
  String build() {
    AppStrings.bind(code);
    return code;
  }
}

Widget inboxApp({
  required FakeNotificationsClient client,
  String locale = 'fr',
}) {
  AppStrings.bind(locale);
  final rtl = locale == 'ar';
  return ProviderScope(
    overrides: [
      notificationsClientProvider.overrideWithValue(client),
      localeControllerProvider.overrideWith(() => _FixedLocale(locale)),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      home: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: const NotificationsScreen(),
      ),
    ),
  );
}

void main() {
  setUp(() => AppStrings.bind('fr'));
  tearDown(() => AppStrings.bind('fr'));

  test('match offer goes home; earning goes to earnings; others stay', () {
    expect(
      resolveDriverNotificationDestination(item(type: 'MATCH_OFFER')).location,
      AppRoutes.home,
    );
    expect(
      resolveDriverNotificationDestination(
        item(type: 'DRIVER_EARNING_CREATED'),
      ).location,
      AppRoutes.earnings,
    );
    expect(
      resolveDriverNotificationDestination(item(type: 'ORDER_ACCEPTED')).canOpen,
      isFalse,
    );
  });

  test('system copy localizes match offer without rewriting stored english', () {
    AppStrings.bind('fr');
    final fr = resolveSystemNotificationCopy(
      type: 'MATCH_OFFER',
      storedTitle: 'New offer',
      storedBody: 'You have a new offer',
    );
    expect(fr.title, 'Nouvelle course proposée');
    expect(fr.body, isNot(contains('You have')));
    AppStrings.bind('ar');
    final ar = resolveSystemNotificationCopy(
      type: 'MATCH_OFFER',
      storedTitle: 'New offer',
      storedBody: 'You have a new offer',
    );
    expect(ar.title, 'عرض توصيل جديد');
  });

  test('pagination slices and dedups overlapping pages', () async {
    final client = FakeNotificationsClient(
      items: [for (var i = 0; i < 35; i++) item(id: 'n$i')],
    )..overlapOnLoadMore = true;
    final container = inboxContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    var state = container.read(notificationsControllerProvider);
    expect(state.items.length, 30);
    await container.read(notificationsControllerProvider.notifier).loadMore();
    state = container.read(notificationsControllerProvider);
    expect(state.items.map((e) => e.id).toSet().length, state.items.length);
  });

  test('certain mark-read failure rolls back', () async {
    final client = FakeNotificationsClient(items: [item(id: 'n1')])
      ..markReadError = const ApiException(
        'not found',
        code: 'NOTIFICATION_NOT_FOUND',
        statusCode: 404,
      );
    final container = inboxContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container
        .read(notificationsControllerProvider.notifier)
        .markRead(item(id: 'n1'));
    expect(
      container.read(notificationsControllerProvider).items.first.read,
      isFalse,
    );
    expect(container.read(unreadNotificationsProvider), 1);
  });

  test('unread failure keeps last count', () async {
    final client = FakeNotificationsClient(
      items: [item(id: 'n1'), item(id: 'n2')],
    );
    final container = inboxContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    expect(container.read(unreadNotificationsProvider), 2);
    client.unreadError = const NetworkException('down', code: 'NETWORK');
    await container.read(unreadNotificationsProvider.notifier).refresh();
    expect(container.read(unreadNotificationsProvider), 2);
  });

  test('session epoch rejects a stale list', () async {
    final client = FakeNotificationsClient(items: [item(id: 'old')])
      ..listDelayForCall = (call) =>
          call == 1
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 5);
    final container = inboxContainer(client);
    addTearDown(container.dispose);
    container.listen(notificationsControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    container.read(sessionEpochProvider.notifier).bump();
    client.items = [item(id: 'new')];
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final ids = container
        .read(notificationsControllerProvider)
        .items
        .map((e) => e.id);
    expect(ids, isNot(contains('old')));
  });

  testWidgets('empty inbox FR', (tester) async {
    await tester.pumpWidget(
      inboxApp(client: FakeNotificationsClient(), locale: 'fr'),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.notificationsEmpty), findsOneWidget);
  });

  testWidgets('populated inbox AR keeps mixed Latin', (tester) async {
    await tester.pumpWidget(
      inboxApp(
        client: FakeNotificationsClient(
          items: [
            item(id: 'n1', type: 'MATCH_OFFER', read: false),
            item(
              id: 'n2',
              type: 'ADMIN_SUPPORT_TICKET',
              title: 'Ticket Dar El Bahja',
              body: 'Ada — 650,00 DZD',
              read: true,
            ),
          ],
        ),
        locale: 'ar',
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification_n1')), findsOneWidget);
    expect(find.text(AppStrings.notifTitleMatchOffer), findsWidgets);
    expect(find.textContaining('Dar El Bahja'), findsOneWidget);
    expect(find.textContaining('650,00 DZD'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(NotificationsScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('opening inbox does not require availability clients', (
    tester,
  ) async {
    final client = FakeNotificationsClient(items: [item(id: 'n1')]);
    await tester.pumpWidget(inboxApp(client: client));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification_n1')), findsOneWidget);
    expect(client.listCalls, greaterThan(0));
  });
}
