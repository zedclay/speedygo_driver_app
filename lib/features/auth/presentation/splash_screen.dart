import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(localeControllerProvider.notifier).restore();
      await ref.read(sessionControllerProvider.notifier).restore();
      if (!mounted) return;
      final status = ref.read(sessionControllerProvider).status;
      switch (status) {
        case SessionStatus.signedIn:
          context.go(AppRoutes.home);
        case SessionStatus.needsDriverProfile:
          context.go(AppRoutes.onboardingProfile);
        case SessionStatus.signedOut:
        case SessionStatus.unknown:
          context.go(AppRoutes.phone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
