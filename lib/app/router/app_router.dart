import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/presentation/otp_screen.dart';
import 'package:speedygo_driver_app/features/auth/presentation/phone_screen.dart';
import 'package:speedygo_driver_app/features/auth/presentation/splash_screen.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/current_delivery_screen.dart';
import 'package:speedygo_driver_app/features/settings/presentation/language_settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<SessionState>(sessionControllerProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final loc = state.matchedLocation;
      final authed = session.status == SessionStatus.signedIn;
      final authRoute =
          loc == AppRoutes.phone ||
          loc == AppRoutes.otp ||
          loc == AppRoutes.splash;
      final languageRoute = loc == AppRoutes.languageSettings;

      if (session.status == SessionStatus.unknown &&
          loc != AppRoutes.splash &&
          !languageRoute) {
        return AppRoutes.splash;
      }
      if (!authed && loc == AppRoutes.currentDelivery) {
        return AppRoutes.phone;
      }
      if (authed && authRoute) {
        return AppRoutes.currentDelivery;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.phone,
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.currentDelivery,
        builder: (context, state) => const CurrentDeliveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.languageSettings,
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
    ],
  );
});
