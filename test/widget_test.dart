import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';

void main() {
  testWidgets('unauthenticated bootstrap reaches phone screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          firstLaunchIntroStoreProvider.overrideWithValue(
            MemoryFirstLaunchIntroStore(completed: true),
          ),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          localeStoreProvider.overrideWithValue(
            MemoryLocaleStore(locale: 'fr'),
          ),
          authApiProvider.overrideWithValue(FakeAuthClient()),
        ],
        child: const SpeedyGoApp(),
      ),
    );
    // Splash shows a Continuous CircularProgressIndicator; settle with bounded pumps.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
  });
}
