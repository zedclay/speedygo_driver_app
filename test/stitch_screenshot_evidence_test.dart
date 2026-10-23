import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/theme/app_theme.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/presentation/otp_screen.dart';
import 'package:speedygo_driver_app/features/auth/presentation/phone_screen.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/presentation/driver_home_screen.dart';
import 'package:speedygo_driver_app/features/blocked/presentation/honest_unavailable_screen.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/current_delivery_screen.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_api.dart';
import 'package:speedygo_driver_app/features/earnings/presentation/earnings_screen.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';
import 'package:speedygo_driver_app/features/history/data/history_api.dart';
import 'package:speedygo_driver_app/features/history/presentation/history_screen.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';
import 'package:speedygo_driver_app/features/notifications/presentation/notifications_screen.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';
import 'package:speedygo_driver_app/features/profile/presentation/profile_screen.dart';
import 'package:speedygo_driver_app/features/support/application/support_controller.dart';
import 'package:speedygo_driver_app/features/support/data/support_api.dart';
import 'package:speedygo_driver_app/features/support/presentation/support_screen.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';

/// Widget-level Flutter captures (not Stitch HTML). Label: mocked_widget_ui.
/// Secrets are never rendered into these fixtures.

DriverMe _me({String availability = 'ONLINE'}) => DriverMe(
  driverProfileExists: true,
  profileComplete: true,
  identityDocumentComplete: true,
  drivingLicenseComplete: true,
  vehicleComplete: true,
  verificationSubmitted: true,
  verificationApproved: true,
  operationalReady: true,
  matchingEligible: availability == 'ONLINE',
  profileFullName: 'Driver Fixture',
  verificationStatus: 'APPROVED',
  availability: DriverAvailabilityInfo(
    status: availability,
    offlineAfterCurrentDelivery: false,
    updatedAt: 't',
  ),
);

DriverCurrentDelivery _delivery(String status, List<String> actions) =>
    DriverCurrentDelivery(
      assignmentId: 'asg-fixture',
      assignmentVersion: 1,
      deliveryId: 'del-fixture',
      orderId: 'ord-fixture',
      deliveryStatus: status,
      orderStatus: 'ACTIVE',
      fulfillmentStatus: 'READY',
      assignmentStatus: 'ACCEPTED',
      allowedActions: actions,
      pickedUpAt: null,
      arrivedCustomerAt: null,
      deliveredAt: status == 'DELIVERED' ? '2026-10-09T12:00:00.000Z' : null,
    );

class _SignedIn extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.signedIn);

  @override
  Future<void> restore() async {}
}

Future<void> _capture(
  WidgetTester tester,
  String locale,
  String name,
  Widget child, {
  FakeAvailabilityClient? availability,
  FakeDeliveryClient? delivery,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  AppStrings.bind(locale);
  final container = ProviderContainer(
    overrides: [
      sessionControllerProvider.overrideWith(_SignedIn.new),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
      availabilityClientProvider.overrideWithValue(
        availability ?? FakeAvailabilityClient(me: _me()),
      ),
      deliveryClientProvider.overrideWithValue(
        delivery ?? FakeDeliveryClient(),
      ),
      deviceLocationSourceProvider.overrideWithValue(
        FakeDeviceLocationSource(
          position: const DevicePosition(latitude: 36.75, longitude: 3.06),
        ),
      ),
      historyClientProvider.overrideWithValue(FakeHistoryClient()),
      earningsClientProvider.overrideWithValue(FakeEarningsClient()),
      notificationsClientProvider.overrideWithValue(FakeNotificationsClient()),
      driverProfileClientProvider.overrideWithValue(
        FakeDriverProfileClient(me: _me()),
      ),
      supportClientProvider.overrideWithValue(FakeSupportClient()),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: Locale(locale),
        home: Directionality(
          textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: RepaintBoundary(
            key: const Key('stitch_capture_root'),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  final boundary = tester.renderObject(
    find.byKey(const Key('stitch_capture_root')),
  ) as RenderRepaintBoundary;
  // toImage must leave the fake async zone.
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory('docs/evidence/stitch_full_ui_2026-10-09/$locale');
    dir.createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  // Cancel availability poll/location timers before the binding asserts.
  container.dispose();
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in ['fr', 'ar']) {
    group('stitch evidence $locale', () {
      testWidgets('phone', (tester) async {
        await _capture(tester, locale, '01_phone', const PhoneScreen());
      });
      testWidgets('otp', (tester) async {
        await _capture(tester, locale, '02_otp', const OtpScreen());
      });
      testWidgets('home_online', (tester) async {
        await _capture(
          tester,
          locale,
          '03_home_online',
          const DriverHomeScreen(),
          availability: FakeAvailabilityClient(me: _me()),
        );
      });
      testWidgets('home_offline', (tester) async {
        await _capture(
          tester,
          locale,
          '04_home_offline',
          const DriverHomeScreen(),
          availability: FakeAvailabilityClient(
            me: _me(availability: 'OFFLINE'),
          ),
        );
      });
      testWidgets('delivery_to_pickup', (tester) async {
        await _capture(
          tester,
          locale,
          '05_delivery_to_pickup',
          const CurrentDeliveryScreen(),
          delivery: FakeDeliveryClient(
            current: _delivery('TO_PICKUP', ['arrive-pickup']),
          ),
        );
      });
      testWidgets('delivery_at_pickup', (tester) async {
        await _capture(
          tester,
          locale,
          '06_delivery_at_pickup',
          const CurrentDeliveryScreen(),
          delivery: FakeDeliveryClient(
            current: _delivery('AT_PICKUP', ['confirm-pickup']),
          ),
        );
      });
      testWidgets('delivery_arrived_customer', (tester) async {
        await _capture(
          tester,
          locale,
          '07_delivery_arrived_customer',
          const CurrentDeliveryScreen(),
          delivery: FakeDeliveryClient(
            current: _delivery('ARRIVED_CUSTOMER', ['complete-delivery']),
          ),
        );
      });
      testWidgets('delivery_delivered', (tester) async {
        await _capture(
          tester,
          locale,
          '08_delivery_delivered',
          const CurrentDeliveryScreen(),
          delivery: FakeDeliveryClient(
            current: _delivery('DELIVERED', const []),
          ),
        );
      });
      testWidgets('history', (tester) async {
        await _capture(tester, locale, '09_history', const HistoryScreen());
      });
      testWidgets('earnings', (tester) async {
        await _capture(tester, locale, '10_earnings', const EarningsScreen());
      });
      testWidgets('profile', (tester) async {
        await _capture(tester, locale, '11_profile', const ProfileScreen());
      });
      testWidgets('notifications', (tester) async {
        await _capture(
          tester,
          locale,
          '12_notifications',
          const NotificationsScreen(),
        );
      });
      testWidgets('support', (tester) async {
        await _capture(tester, locale, '13_support', const SupportScreen());
      });
      testWidgets('blocked_contact', (tester) async {
        await _capture(
          tester,
          locale,
          '14_blocked_contact',
          const HonestUnavailableScreen(kind: BlockedKind.contact),
        );
      });
      testWidgets('blocked_delivery_pin', (tester) async {
        await _capture(
          tester,
          locale,
          '15_blocked_delivery_pin',
          const HonestUnavailableScreen(kind: BlockedKind.deliveryPin),
        );
      });
      testWidgets('blocked_failure', (tester) async {
        await _capture(
          tester,
          locale,
          '16_blocked_failure',
          const HonestUnavailableScreen(kind: BlockedKind.failureReport),
        );
      });
    });
  }

  test('writes manifest', () {
    final root = Directory('docs/evidence/stitch_full_ui_2026-10-09');
    expect(root.existsSync(), isTrue);
    final fr = Directory('${root.path}/fr').listSync().whereType<File>().length;
    final ar = Directory('${root.path}/ar').listSync().whereType<File>().length;
    final manifest = StringBuffer()
      ..writeln('# Stitch full UI evidence manifest')
      ..writeln()
      ..writeln('generated_at: 2026-10-09')
      ..writeln('kind: **mocked_widget_ui**')
      ..writeln('not: live_authenticated_ui')
      ..writeln('not: stitch_html_capture')
      ..writeln('not: live_ui_verified')
      ..writeln('baseline_head: be7cedd')
      ..writeln('fr_captures: $fr')
      ..writeln('ar_captures: $ar')
      ..writeln('secrets: none')
      ..writeln()
      ..writeln(
        'note: Widget pump captures with Fake* clients. Do not treat as live verification.',
      )
      ..writeln()
      ..writeln(
        'Folder → capture mapping: docs/DRIVER_STITCH_SCREEN_COVERAGE.json → mocked_widget_captures.',
      );
    File('${root.path}/MANIFEST.md').writeAsStringSync(manifest.toString());
  });
}
