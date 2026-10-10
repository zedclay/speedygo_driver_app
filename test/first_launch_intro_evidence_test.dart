import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/app/theme/app_theme.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/constants/driver_assets.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/presentation/first_launch_intro_screen.dart';

/// Widget/mocked screenshots. Evidence class: `mocked_widget_ui`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final out = Directory(
    'docs/evidence/first_launch_intro_v1_2026-10-10/screenshots',
  );

  Future<void> capturePage(
    WidgetTester tester, {
    required String locale,
    required String name,
    required int pageIndex,
  }) async {
    out.createSync(recursive: true);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    AppStrings.bind(locale);

    final container = ProviderContainer(
      overrides: [
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        firstLaunchIntroStoreProvider.overrideWithValue(
          MemoryFirstLaunchIntroStore(completed: false),
        ),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        localeStoreProvider.overrideWithValue(
          MemoryLocaleStore(locale: locale),
        ),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        availabilityClientProvider.overrideWithValue(FakeAvailabilityClient()),
        deliveryClientProvider.overrideWithValue(FakeDeliveryClient()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: Locale(locale),
          home: Directionality(
            textDirection: locale == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: const RepaintBoundary(
              key: Key('intro_capture_root'),
              child: FirstLaunchIntroScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(FirstLaunchIntroScreen));
      await Future.wait([
        precacheImage(const AssetImage(DriverAssets.firstLaunchIntro1), ctx),
        precacheImage(const AssetImage(DriverAssets.firstLaunchIntro2), ctx),
        precacheImage(const AssetImage(DriverAssets.firstLaunchIntro3), ctx),
      ]);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < pageIndex; i++) {
      await tester.tap(find.byKey(const Key('first_launch_intro_primary')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    final boundary = tester.renderObject(
      find.byKey(const Key('intro_capture_root')),
    ) as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      File('${out.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });

    await tester.pumpWidget(const SizedBox.shrink());
  }

  for (final locale in ['fr', 'ar']) {
    group('first-launch intro evidence $locale', () {
      testWidgets('page1', (tester) async {
        await capturePage(
          tester,
          locale: locale,
          name: 'mocked_${locale}_intro_page1',
          pageIndex: 0,
        );
      });
      testWidgets('page2', (tester) async {
        await capturePage(
          tester,
          locale: locale,
          name: 'mocked_${locale}_intro_page2',
          pageIndex: 1,
        );
      });
      testWidgets('page3', (tester) async {
        await capturePage(
          tester,
          locale: locale,
          name: 'mocked_${locale}_intro_page3',
          pageIndex: 2,
        );
      });
    });
  }
}
