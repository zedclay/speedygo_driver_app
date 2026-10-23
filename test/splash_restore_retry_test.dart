import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required SessionStore store,
  required FakeAuthClient auth,
  String locale = 'fr',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        firstLaunchIntroStoreProvider.overrideWithValue(
          MemoryFirstLaunchIntroStore(completed: true),
        ),
        sessionStoreProvider.overrideWithValue(store),
        localeStoreProvider.overrideWithValue(MemoryLocaleStore(locale: locale)),
        authApiProvider.overrideWithValue(auth),
        availabilityClientProvider.overrideWithValue(
          FakeAvailabilityClient(
            me: const DriverMe(
              driverProfileExists: true,
              profileComplete: true,
              identityDocumentComplete: true,
              drivingLicenseComplete: true,
              vehicleComplete: true,
              verificationSubmitted: true,
              verificationApproved: true,
              operationalReady: true,
              matchingEligible: false,
              verificationStatus: 'APPROVED',
              availability: DriverAvailabilityInfo(
                status: 'OFFLINE',
                offlineAfterCurrentDelivery: false,
                updatedAt: 't',
              ),
            ),
          ),
        ),
        deliveryClientProvider.overrideWithValue(
          FakeDeliveryClient(current: null),
        ),
        deviceLocationSourceProvider.overrideWithValue(
          FakeDeviceLocationSource(),
        ),
      ],
      child: const SpeedyGoApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pair = TokenPair(
    accessToken: 'access-1',
    refreshToken: 'refresh-1-token-value',
    expiresIn: 900,
    tokenType: 'Bearer',
  );

  testWidgets('transient restore failure shows French retry and keeps splash', (
    tester,
  ) async {
    AppStrings.bind('fr');
    final store = MemorySessionStore()..value = pair;
    final auth = FakeAuthClient()
      ..meError = const NetworkException('offline', code: 'NETWORK');
    await _pumpApp(tester, store: store, auth: auth, locale: 'fr');
    expect(find.byKey(const Key('splash_restore_retry')), findsOneWidget);
    expect(find.text(AppStrings.restoreRetry), findsOneWidget);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
    expect(store.value, isNotNull);
  });

  testWidgets('transient restore failure shows Arabic retry under RTL', (
    tester,
  ) async {
    AppStrings.bind('ar');
    final store = MemorySessionStore()..value = pair;
    final auth = FakeAuthClient()
      ..meError = const NetworkException('offline', code: 'NETWORK');
    await _pumpApp(tester, store: store, auth: auth, locale: 'ar');
    expect(find.byKey(const Key('splash_restore_retry')), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    final direction = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(direction.textDirection, TextDirection.rtl);
    expect(store.value, isNotNull);
  });

  testWidgets('retry after restore failure reaches home path', (tester) async {
    AppStrings.bind('fr');
    final store = MemorySessionStore()..value = pair;
    final auth = FakeAuthClient()
      ..meError = const NetworkException('offline', code: 'NETWORK');
    await _pumpApp(tester, store: store, auth: auth);
    expect(find.byKey(const Key('splash_restore_retry')), findsOneWidget);
    auth.meError = null;
    await tester.tap(find.byKey(const Key('splash_restore_retry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('splash_restore_retry')), findsNothing);
    expect(find.text(AppStrings.phoneTitle), findsNothing);
  });
}
