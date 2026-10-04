import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/app/providers/app_providers.dart';
import 'package:speedygo_driver_app/app/router/app_router.dart';
import 'package:speedygo_driver_app/app/theme/app_theme.dart';

class SpeedyGoApp extends ConsumerWidget {
  const SpeedyGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final title = ref.watch(appNameProvider);

    return MaterialApp.router(
      title: title,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
