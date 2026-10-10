import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/app/router/driver_navigation_resolver.dart';
import 'package:speedygo_driver_app/app/router/driver_shell.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/presentation/otp_screen.dart';
import 'package:speedygo_driver_app/features/auth/presentation/phone_screen.dart';
import 'package:speedygo_driver_app/features/auth/presentation/splash_screen.dart';
import 'package:speedygo_driver_app/features/availability/presentation/driver_home_screen.dart';
import 'package:speedygo_driver_app/features/blocked/presentation/honest_unavailable_screen.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/current_delivery_screen.dart';
import 'package:speedygo_driver_app/features/earnings/presentation/earnings_screen.dart';
import 'package:speedygo_driver_app/features/history/presentation/history_detail_screen.dart';
import 'package:speedygo_driver_app/features/history/presentation/history_screen.dart';
import 'package:speedygo_driver_app/features/notifications/presentation/notifications_screen.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_document_screen.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_profile_screen.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_review_screen.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_status_screen.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_vehicle_screen.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';
import 'package:speedygo_driver_app/features/profile/presentation/documents_screen.dart';
import 'package:speedygo_driver_app/features/profile/presentation/profile_screen.dart';
import 'package:speedygo_driver_app/features/profile/presentation/ratings_screen.dart';
import 'package:speedygo_driver_app/features/profile/presentation/settings_hub_screen.dart';
import 'package:speedygo_driver_app/features/profile/presentation/vehicle_screen.dart';
import 'package:speedygo_driver_app/features/settings/presentation/language_settings_screen.dart';
import 'package:speedygo_driver_app/features/support/presentation/support_detail_screen.dart';
import 'package:speedygo_driver_app/features/support/presentation/support_screen.dart';

export 'package:speedygo_driver_app/app/router/driver_navigation_resolver.dart'
    show driverRedirect, resolveColdStartDestination, DriverNavSnapshot;

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<SessionState>(sessionControllerProvider, (_, _) {
    refresh.value++;
  });
  ref.listen<DriverNavSnapshot>(driverNavSnapshotProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final snapshot = ref.read(driverNavSnapshotProvider);
      return driverRedirect(
        status: session.status,
        loc: state.matchedLocation,
        snapshot: snapshot,
      );
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DriverShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DriverHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.earnings,
                builder: (context, state) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.currentDelivery,
        builder: (context, state) => const CurrentDeliveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.languageSettings,
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.vehicle,
        builder: (context, state) => const VehicleScreen(),
      ),
      GoRoute(
        path: AppRoutes.vehicleEdit,
        builder: (context, state) => const VehicleScreen(),
      ),
      GoRoute(
        path: AppRoutes.documents,
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.ratings,
        builder: (context, state) => const RatingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.supportDetail}/:id',
        builder: (context, state) =>
            SupportDetailScreen(ticketId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.historyDetail}/:id',
        builder: (context, state) =>
            HistoryDetailScreen(deliveryId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.blockedUnavailable}/:kind',
        builder: (context, state) =>
            HonestUnavailableScreen(kind: state.pathParameters['kind'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.onboardingProfile,
        builder: (context, state) => const OnboardingProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingIdentity,
        builder: (context, state) =>
            const OnboardingDocumentScreen(type: DriverDocumentTypes.identity),
      ),
      GoRoute(
        path: AppRoutes.onboardingLicense,
        builder: (context, state) => const OnboardingDocumentScreen(
          type: DriverDocumentTypes.drivingLicense,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingVehicle,
        builder: (context, state) => const OnboardingVehicleScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingReview,
        builder: (context, state) => const OnboardingReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPending,
        builder: (context, state) =>
            const OnboardingStatusScreen(outcome: OnboardingOutcome.pending),
      ),
      GoRoute(
        path: AppRoutes.onboardingApproved,
        builder: (context, state) =>
            const OnboardingStatusScreen(outcome: OnboardingOutcome.approved),
      ),
      GoRoute(
        path: AppRoutes.onboardingCorrections,
        builder: (context, state) => const OnboardingStatusScreen(
          outcome: OnboardingOutcome.corrections,
        ),
      ),
    ],
  );
});
