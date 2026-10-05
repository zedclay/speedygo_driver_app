import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/app/providers/app_providers.dart';
import 'package:speedygo_driver_app/app/router/app_router.dart';
import 'package:speedygo_driver_app/app/theme/app_theme.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';

class SpeedyGoApp extends ConsumerWidget {
  const SpeedyGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final title = ref.watch(appNameProvider);
    final localeCode = ref.watch(localeControllerProvider);
    final locale = Locale(localeCode == 'ar' ? 'ar' : 'fr');
    AppStrings.bind(locale.languageCode);

    return MaterialApp.router(
      title: title,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
