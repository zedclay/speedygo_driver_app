import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/app/router/app_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_api.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';
import 'package:speedygo_driver_app/features/history/data/history_api.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

/// Shell-chrome captures (tabs / focused) — fixture-backed, not live Backend.
/// Output: docs/evidence/driver_modern_white_2026-10-15/nav_chrome/{fr,ar}/

const _outRoot =
    'docs/evidence/driver_modern_white_2026-10-15/nav_chrome';

class _SignedInSession extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.signedIn);

  @override
  Future<void> restore() async {}
}

DriverMe _me({String availability = 'OFFLINE', bool matching = false}) =>
    DriverMe(
      driverProfileExists: true,
      profileComplete: true,
      identityDocumentComplete: true,
      drivingLicenseComplete: true,
      vehicleComplete: true,
      verificationSubmitted: true,
      verificationApproved: true,
      operationalReady: true,
      matchingEligible: matching,
      profileFullName: 'Amine Driver',
      verificationStatus: 'APPROVED',
      availability: DriverAvailabilityInfo(
        status: availability,
        offlineAfterCurrentDelivery: false,
        updatedAt: 't',
      ),
      vehicles: const [
        DriverVehicleInfo(
          id: 'v1',
          type: 'MOTORCYCLE',
          plateNumber: 'SG-123',
          model: 'NMAX',
          status: 'ACTIVE',
          color: 'White',
        ),
      ],
    );

AssignmentOffer _offer() => AssignmentOffer(
  assignmentId: 'asg-offer',
  deliveryId: 'del-1',
  orderPublicReference: 'SG-42',
  status: 'OFFERED',
  offeredAt: '2099-01-01T00:00:00.000Z',
  expiresAt: '2099-01-01T00:00:30.000Z',
  driverRemunerationMinor: '300',
  pickupName: 'Café Atlas',
  pickupDistanceMeters: 350,
  deliveryDistanceMeters: 1200,
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
      deliveredAt: null,
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _captureShell(
  WidgetTester tester,
  String locale,
  String name, {
  required FakeAvailabilityClient availability,
  FakeDeliveryClient? delivery,
  Future<void> Function(ProviderContainer container)? navigate,
  List<Finder> expectPresent = const [],
  List<Finder> expectAbsent = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  AppStrings.bind(locale);

  var disposed = false;
  final container = ProviderContainer(
    overrides: [
      splashMinDurationProvider.overrideWithValue(Duration.zero),
      firstLaunchIntroStoreProvider.overrideWithValue(
        MemoryFirstLaunchIntroStore(completed: true),
      ),
      sessionControllerProvider.overrideWith(_SignedInSession.new),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
      availabilityClientProvider.overrideWithValue(availability),
      deliveryClientProvider.overrideWithValue(
        delivery ?? FakeDeliveryClient(current: null),
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
    ],
  );
  addTearDown(() {
    if (!disposed) {
      disposed = true;
      container.dispose();
    }
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RepaintBoundary(
        key: Key('nav_chrome_capture_root'),
        child: SpeedyGoApp(),
      ),
    ),
  );
  await _settle(tester);
  if (navigate != null) {
    await navigate(container);
    await _settle(tester);
  }

  for (final f in expectPresent) {
    expect(f, findsOneWidget);
  }
  for (final f in expectAbsent) {
    expect(f, findsNothing);
  }

  final rb =
      tester.renderObject(find.byKey(const Key('nav_chrome_capture_root')))
          as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await rb.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory('$_outRoot/$locale');
    dir.createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });

  // Stop offer polling timers before Flutter pending-timer check.
  availability.offer = null;
  availability.me = _me();
  try {
    await container
        .read(driverHomeControllerProvider.notifier)
        .refresh(full: true);
  } catch (_) {}
  await tester.pumpWidget(const SizedBox.shrink());
  if (!disposed) {
    disposed = true;
    container.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in ['fr', 'ar']) {
    group('nav chrome $locale', () {
      testWidgets('01_home_tabs', (tester) async {
        await _captureShell(
          tester,
          locale,
          '01_home_tabs',
          availability: FakeAvailabilityClient(me: _me()),
          expectPresent: [find.byKey(const Key('shell_bottom_nav'))],
        );
      });

      testWidgets('03_offer_focused', (tester) async {
        await _captureShell(
          tester,
          locale,
          '03_offer_focused',
          availability: FakeAvailabilityClient(
            me: _me(availability: 'ONLINE', matching: true),
            offer: _offer(),
          ),
          expectPresent: [
            find.byKey(const Key('offer_card')),
            find.byKey(const Key('offer_focused_app_bar')),
          ],
          expectAbsent: [find.byKey(const Key('shell_bottom_nav'))],
        );
      });

      testWidgets('05_at_pickup_tabs', (tester) async {
        await _captureShell(
          tester,
          locale,
          '05_at_pickup_tabs',
          availability: FakeAvailabilityClient(me: _me()),
          delivery: FakeDeliveryClient(
            current: _delivery('AT_PICKUP', const []),
          ),
          navigate: (c) async {
            c.read(appRouterProvider).go(AppRoutes.currentDelivery);
          },
          expectPresent: [find.byKey(const Key('shell_bottom_nav'))],
          expectAbsent: [find.byKey(const Key('shell_menu_button'))],
        );
      });

      testWidgets('07_pickup_code_focused', (tester) async {
        await _captureShell(
          tester,
          locale,
          '07_pickup_code_focused',
          availability: FakeAvailabilityClient(me: _me()),
          delivery: FakeDeliveryClient(
            current: _delivery('AT_PICKUP', ['confirm-pickup']),
          ),
          navigate: (c) async {
            c.read(appRouterProvider).go(AppRoutes.currentDelivery);
          },
          expectPresent: [find.byKey(const Key('pickup_code_card'))],
          expectAbsent: [find.byKey(const Key('shell_bottom_nav'))],
        );
      });

      testWidgets('21_vehicle_tabs', (tester) async {
        await _captureShell(
          tester,
          locale,
          '21_vehicle_tabs',
          availability: FakeAvailabilityClient(me: _me()),
          navigate: (c) async {
            c.read(appRouterProvider).go(AppRoutes.vehicle);
          },
          expectPresent: [find.byKey(const Key('shell_bottom_nav'))],
          expectAbsent: [find.byKey(const Key('shell_menu_button'))],
        );
      });
    });
  }
}
