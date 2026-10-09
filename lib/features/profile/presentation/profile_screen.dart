import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/confirmation_sheet.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';

StatusTone verificationTone(String? status) => switch (status) {
  'APPROVED' => StatusTone.success,
  'PENDING_REVIEW' => StatusTone.warning,
  'REJECTED' || 'SUSPENDED' => StatusTone.danger,
  _ => StatusTone.neutral,
};

/// Confirms, then logs out. Logout lives on Profile (not on Home).
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showConfirmationSheet(
    context,
    title: AppStrings.logoutConfirmTitle,
    body: AppStrings.logoutConfirmBody,
    confirmLabel: AppStrings.logoutConfirmAction,
    destructive: true,
    confirmKey: const Key('logout_confirm'),
  );
  if (confirmed && context.mounted) {
    await ref.read(sessionControllerProvider.notifier).logout();
  }
}

/// Profile tab (shell branch 3), built from `GET /driver/me`.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier).load();
    });
  }

  Widget _tile(
    IconData icon,
    String label,
    String route, {
    Key? key,
    String? subtitle,
  }) {
    return ListTile(
      key: key,
      minTileHeight: DriverTokens.touchTarget,
      leading: Icon(icon, color: DriverTokens.primary),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(onboardingControllerProvider);
    final me = state.me;
    final theme = Theme.of(context);
    final status = me?.verificationStatus;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: ref.read(onboardingControllerProvider.notifier).load,
        child: ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            if (state.loadStatus == OnboardingLoadStatus.loading && me == null)
              LoadingView(message: AppStrings.loading),
            if (state.loadStatus == OnboardingLoadStatus.error && me == null)
              ErrorRetryView(
                message: state.errorMessage ?? AppStrings.unexpectedError,
                onRetry: ref.read(onboardingControllerProvider.notifier).load,
                retryKey: const Key('profile_retry'),
              ),
            if (me != null) ...[
              OperationalCard(
                key: const Key('profile_header'),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: DriverTokens.primaryContainer,
                      child: Icon(Icons.person, color: DriverTokens.primary),
                    ),
                    const SizedBox(width: DriverTokens.spaceLg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me.profileFullName ?? AppStrings.profileNoName,
                            key: const Key('profile_name'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: DriverTokens.spaceSm),
                          StatusBadge(
                            label: AppStrings.verificationStatusLabel(status),
                            tone: verificationTone(status),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (status != 'APPROVED') ...[
                const SizedBox(height: DriverTokens.spaceMd),
                SizedBox(
                  height: DriverTokens.touchTarget,
                  child: FilledButton.tonal(
                    key: const Key('profile_onboarding_cta'),
                    onPressed: () => context.push(onboardingRouteFor(me)),
                    child: Text(AppStrings.profileMenuOnboarding),
                  ),
                ),
              ],
            ],
            const SizedBox(height: DriverTokens.spaceMd),
            OperationalCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _tile(
                    Icons.two_wheeler,
                    AppStrings.profileMenuVehicle,
                    AppRoutes.vehicle,
                    key: const Key('profile_vehicle'),
                  ),
                  _tile(
                    Icons.description_outlined,
                    AppStrings.profileMenuDocuments,
                    AppRoutes.documents,
                    key: const Key('profile_documents'),
                  ),
                  _tile(
                    Icons.star_outline,
                    AppStrings.profileMenuRatings,
                    AppRoutes.ratings,
                    key: const Key('profile_ratings'),
                  ),
                  _tile(
                    Icons.support_agent,
                    AppStrings.profileMenuSupport,
                    AppRoutes.support,
                    key: const Key('profile_support'),
                  ),
                  _tile(
                    Icons.settings_outlined,
                    AppStrings.profileMenuSettings,
                    AppRoutes.settings,
                    key: const Key('profile_settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DriverTokens.spaceLg),
            SizedBox(
              height: DriverTokens.actionHeight,
              child: OutlinedButton.icon(
                key: const Key('logout'),
                onPressed: () => confirmLogout(context, ref),
                icon: const Icon(Icons.logout),
                label: Text(AppStrings.logout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
