import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';
import 'package:speedygo_driver_app/features/availability/presentation/driver_home_screen.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/current_delivery_screen.dart';

DriverMe _me({String availability = 'OFFLINE', bool matching = false}) {
  return DriverMe(
    driverProfileExists: true,
    profileComplete: true,
    identityDocumentComplete: true,
    drivingLicenseComplete: true,
    vehicleComplete: true,
    verificationSubmitted: true,
    verificationApproved: true,
    operationalReady: true,
    matchingEligible: matching,
    profileFullName: 'Amine',
    verificationStatus: 'APPROVED',
    availability: DriverAvailabilityInfo(
      status: availability,
      offlineAfterCurrentDelivery: false,
      updatedAt: 't',
    ),
  );
}

AssignmentOffer _offer({String expiresAt = '2099-01-01T00:00:30.000Z'}) {
  return AssignmentOffer(
    assignmentId: 'asg-offer',
    deliveryId: 'del-1',
    orderPublicReference: 'SG-42',
    status: 'OFFERED',
    offeredAt: '2099-01-01T00:00:00.000Z',
    expiresAt: expiresAt,
    driverRemunerationMinor: '300',
    pickupName: 'Café Atlas',
    pickupDistanceMeters: 350,
    deliveryDistanceMeters: 1200,
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  // Avoid pumpAndSettle — waiting CircularProgressIndicator never settles.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Widget _screenHarness({
  required FakeAvailabilityClient availability,
  FakeDeliveryClient? delivery,
  FakeDeviceLocationSource? location,
  String locale = 'fr',
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: [
      availabilityClientProvider.overrideWithValue(availability),
      deliveryClientProvider.overrideWithValue(
        delivery ?? FakeDeliveryClient(current: null),
      ),
      deviceLocationSourceProvider.overrideWithValue(
        location ??
            FakeDeviceLocationSource(
              position: const DevicePosition(latitude: 36.75, longitude: 3.06),
            ),
      ),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
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
          textDirection: locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
        home: const DriverHomeScreen(),
      ),
    ),
  );
}

Future<void> _bindLocale(WidgetTester tester, String locale) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(DriverHomeScreen)),
  );
  await container.read(localeControllerProvider.notifier).setLocale(locale);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty online waiting state at 390x844', (tester) async {
    final availability = FakeAvailabilityClient(
      me: _me(availability: 'ONLINE', matching: true),
    );
    await tester.pumpWidget(_screenHarness(availability: availability));
    await _pumpFrames(tester);
    await _bindLocale(tester, 'fr');
    await _pumpFrames(tester);
    expect(find.byKey(const Key('waiting_for_offer')), findsOneWidget);
    expect(find.text(AppStrings.waitingForOffer), findsOneWidget);
    expect(find.byKey(const Key('offer_card')), findsNothing);
  });

  testWidgets('offer rendering shows authorized fields', (tester) async {
    final availability = FakeAvailabilityClient(
      me: _me(availability: 'ONLINE', matching: true),
      offer: _offer(),
    );
    await tester.pumpWidget(_screenHarness(availability: availability));
    await _pumpFrames(tester);
    await _bindLocale(tester, 'fr');
    await _pumpFrames(tester);
    expect(find.byKey(const Key('offer_card')), findsOneWidget);
    expect(find.text('Café Atlas'), findsOneWidget);
    expect(find.text('SG-42'), findsOneWidget);
    expect(find.byKey(const Key('offer_countdown')), findsOneWidget);
    expect(find.byKey(const Key('offer_accept_button')), findsOneWidget);
    expect(find.byKey(const Key('offer_reject_button')), findsOneWidget);
  });

  testWidgets('French rendering of availability actions', (tester) async {
    final availability = FakeAvailabilityClient(me: _me());
    await tester.pumpWidget(
      _screenHarness(availability: availability, locale: 'fr'),
    );
    await _pumpFrames(tester);
    await _bindLocale(tester, 'fr');
    await _pumpFrames(tester);
    expect(find.text('Hors ligne'), findsOneWidget);
    expect(find.text('Passer en ligne'), findsOneWidget);
  });

  testWidgets('Arabic/RTL rendering of availability actions', (tester) async {
    final availability = FakeAvailabilityClient(me: _me());
    await tester.pumpWidget(
      _screenHarness(availability: availability, locale: 'ar'),
    );
    await _pumpFrames(tester);
    await _bindLocale(tester, 'ar');
    await _pumpFrames(tester);
    expect(find.text('غير متصل'), findsOneWidget);
    expect(find.text('الاتصال'), findsOneWidget);
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('server-based countdown visible', (tester) async {
    final expires = DateTime.now().toUtc().add(const Duration(seconds: 25));
    final availability = FakeAvailabilityClient(
      me: _me(availability: 'ONLINE', matching: true),
      offer: _offer(expiresAt: expires.toIso8601String()),
    );
    await tester.pumpWidget(_screenHarness(availability: availability));
    await _pumpFrames(tester);
    final text = tester.widget<Text>(find.byKey(const Key('offer_countdown')));
    expect(text.data, isNot(AppStrings.offerExpired));
    expect(text.data, matches(RegExp(r'^\d{2}:\d{2}$')));
  });

  testWidgets('expiration while screen open disables actions', (tester) async {
    final availability = FakeAvailabilityClient(
      me: _me(availability: 'ONLINE', matching: true),
      offer: _offer(
        expiresAt: DateTime.now()
            .toUtc()
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
      ),
    );
    await tester.pumpWidget(_screenHarness(availability: availability));
    await _pumpFrames(tester);
    // Advance countdown timer tick (1s periodic).
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final accept = tester.widget<FilledButton>(
      find.byKey(const Key('offer_accept_button')),
    );
    expect(accept.onPressed, isNull);
  });

  testWidgets('expiration while app backgrounded recalculates on resume', (
    tester,
  ) async {
    final availability = FakeAvailabilityClient(
      me: _me(availability: 'ONLINE', matching: true),
      offer: _offer(
        expiresAt: DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 30))
            .toIso8601String(),
      ),
    );
    await tester.pumpWidget(_screenHarness(availability: availability));
    await _pumpFrames(tester);
    availability.offer = _offer(
      expiresAt: DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 2))
          .toIso8601String(),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DriverHomeScreen)),
    );
    await container.read(driverHomeControllerProvider.notifier).onAppResumed();
    await _pumpFrames(tester);
    final accept = tester.widget<FilledButton>(
      find.byKey(const Key('offer_accept_button')),
    );
    expect(accept.onPressed, isNull);
    expect(find.textContaining('expir'), findsWidgets);
  });

  testWidgets('layout at 390x844 with text scale 1.35', (tester) async {
    final availability = FakeAvailabilityClient(
      me: _me(availability: 'ONLINE', matching: true),
      offer: _offer(),
    );
    await tester.pumpWidget(
      _screenHarness(availability: availability, textScale: 1.35),
    );
    await _pumpFrames(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('offer_accept_button')), findsOneWidget);
    expect(find.byKey(const Key('offer_reject_button')), findsOneWidget);
  });

  testWidgets('accepted offer routes to current delivery', (tester) async {
    final delivery = FakeDeliveryClient(current: null);
    final availability = FakeAvailabilityClient(
      me: _me(availability: 'ONLINE', matching: true),
      offer: _offer(),
      acceptHandler: (_) async {
        delivery.current = const DriverCurrentDelivery(
          assignmentId: 'asg-offer',
          assignmentVersion: 1,
          deliveryId: 'del-1',
          orderId: 'ord-1',
          deliveryStatus: 'DRIVER_ASSIGNED',
          orderStatus: 'ACTIVE',
          fulfillmentStatus: 'READY',
          assignmentStatus: 'ACCEPTED',
          allowedActions: ['start-to-pickup'],
          pickedUpAt: null,
          arrivedCustomerAt: null,
          deliveredAt: null,
        );
      },
    );
    final location = FakeDeviceLocationSource(
      position: const DevicePosition(latitude: 36.75, longitude: 3.06),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const DriverHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.currentDelivery,
          builder: (_, _) => const CurrentDeliveryScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityClientProvider.overrideWithValue(availability),
          deliveryClientProvider.overrideWithValue(delivery),
          deviceLocationSourceProvider.overrideWithValue(location),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          localeStoreProvider.overrideWithValue(
            MemoryLocaleStore(locale: 'fr'),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('offer_accept_button')));
    await _pumpFrames(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(AppStrings.deliveryTitle), findsOneWidget);
  });

  testWidgets('permission denied message after go online', (tester) async {
    final availability = FakeAvailabilityClient(
      me: _me(),
      goOnlineHandler: () async => _me(availability: 'ONLINE', matching: true),
    );
    final location = FakeDeviceLocationSource(
      permission: LocationPermission.denied,
      failure: DeviceLocationFailure.permissionDenied,
    );
    await tester.pumpWidget(
      _screenHarness(availability: availability, location: location),
    );
    await _pumpFrames(tester);
    await _bindLocale(tester, 'fr');
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('go_online_button')));
    await _pumpFrames(tester);
    expect(find.text(AppStrings.locationPermissionDenied), findsOneWidget);
  });
}
