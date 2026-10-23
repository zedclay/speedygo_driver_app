import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/presentation/driver_home_screen.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_api.dart';

/// Fixture-backed captures for the tap availability control.
/// Kind: **fixture_backed_device_ui** ≠ live Backend.
const _out =
    'docs/evidence/driver_from_home_2026-10-14/fixture_availability_toggle';

DriverMe _me({String availability = 'OFFLINE'}) => DriverMe(
  driverProfileExists: true,
  profileComplete: true,
  identityDocumentComplete: true,
  drivingLicenseComplete: true,
  vehicleComplete: true,
  verificationSubmitted: true,
  verificationApproved: true,
  operationalReady: true,
  matchingEligible: availability == 'ONLINE',
  profileFullName: 'Lamine',
  verificationStatus: 'APPROVED',
  availability: DriverAvailabilityInfo(
    status: availability,
    offlineAfterCurrentDelivery: false,
    updatedAt: 't',
  ),
);

Future<void> _capture(
  WidgetTester tester, {
  required String name,
  required String locale,
  required FakeAvailabilityClient availability,
  Future<void> Function(ProviderContainer container)? afterPump,
}) async {
  final container = ProviderContainer(
    overrides: [
      availabilityClientProvider.overrideWithValue(availability),
      deliveryClientProvider.overrideWithValue(
        FakeDeliveryClient(current: null),
      ),
      deviceLocationSourceProvider.overrideWithValue(
        FakeDeviceLocationSource(
          position: const DevicePosition(latitude: 36.75, longitude: 3.06),
        ),
      ),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
      earningsClientProvider.overrideWithValue(FakeEarningsClient()),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('fr'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => Directionality(
            textDirection:
                locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: const RepaintBoundary(
            key: Key('availability_toggle_capture_root'),
            child: DriverHomeScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  await container.read(localeControllerProvider.notifier).setLocale(locale);
  await tester.pump();
  if (afterPump != null) {
    await afterPump(container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
  final boundary =
      tester.renderObject(find.byKey(const Key('availability_toggle_capture_root')))
          as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final dir = Directory(_out)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
  container.dispose();
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fixture captures offline/online FR AR and pending', (tester) async {
    await _capture(
      tester,
      name: 'fixture_offline_fr',
      locale: 'fr',
      availability: FakeAvailabilityClient(me: _me()),
    );
    await _capture(
      tester,
      name: 'fixture_online_fr',
      locale: 'fr',
      availability: FakeAvailabilityClient(
        me: _me(availability: 'ONLINE'),
      ),
      afterPump: (c) async {
        await c.read(driverHomeControllerProvider.notifier).onAppResumed();
      },
    );
    await _capture(
      tester,
      name: 'fixture_offline_ar',
      locale: 'ar',
      availability: FakeAvailabilityClient(me: _me()),
    );
    await _capture(
      tester,
      name: 'fixture_online_ar',
      locale: 'ar',
      availability: FakeAvailabilityClient(
        me: _me(availability: 'ONLINE'),
      ),
      afterPump: (c) async {
        await c.read(driverHomeControllerProvider.notifier).onAppResumed();
      },
    );

    // Pending UI covered by driver_home_screen_test (tap + goingOnline label).
    final files = Directory(_out)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .length;
    expect(files, greaterThanOrEqualTo(4));
  });
}
