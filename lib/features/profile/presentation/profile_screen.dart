import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';

StatusTone verificationTone(String? status) => switch (status) {
  'APPROVED' => StatusTone.success,
  'PENDING_REVIEW' => StatusTone.warning,
  'REJECTED' || 'SUSPENDED' => StatusTone.danger,
  _ => StatusTone.neutral,
};

/// Opens the full-screen logout confirmation (Modern White déconnexion).
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  await context.push(AppRoutes.logout);
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

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(onboardingControllerProvider);
    final me = state.me;
    final theme = Theme.of(context);
    final status = me?.verificationStatus;
    final vehicle = me?.activeVehicle;

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      body: RefreshIndicator(
        onRefresh: ref.read(onboardingControllerProvider.notifier).load,
        child: ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            Text(
              AppStrings.profileTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: DriverTokens.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppStrings.profileSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: DriverTokens.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceLg),
            if (state.loadStatus == OnboardingLoadStatus.loading && me == null)
              LoadingView(message: AppStrings.loading),
            if (state.loadStatus == OnboardingLoadStatus.error && me == null)
              ErrorRetryView(
                message: state.errorMessage ?? AppStrings.unexpectedError,
                onRetry: ref.read(onboardingControllerProvider.notifier).load,
                retryKey: const Key('profile_retry'),
              ),
            if (me != null) ...[
              Container(
                key: const Key('profile_header'),
                padding: const EdgeInsets.all(DriverTokens.spaceLg),
                decoration: BoxDecoration(
                  color: DriverTokens.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
                  border: Border.all(color: DriverTokens.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: DriverTokens.primaryContainer,
                      child: Text(
                        _initials(me.profileFullName),
                        style: const TextStyle(
                          color: DriverTokens.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: DriverTokens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me.profileFullName ?? AppStrings.profileNoName,
                            key: const Key('profile_name'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: DriverTokens.navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: DriverTokens.spaceXs),
                          StatusBadge(
                            label: status == 'APPROVED'
                                ? AppStrings.accountVerified
                                : AppStrings.verificationStatusLabel(status),
                            tone: verificationTone(status),
                            icon: status == 'APPROVED'
                                ? Icons.verified
                                : null,
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
            const SizedBox(height: DriverTokens.spaceXl),
            Text(
              AppStrings.profileSectionAccount,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: DriverTokens.navy,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceSm),
            Material(
              color: DriverTokens.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
                side: const BorderSide(color: DriverTokens.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _PrefTile(
                    key: const Key('profile_vehicle'),
                    icon: Icons.directions_car_outlined,
                    title: AppStrings.profileMenuVehicle,
                    subtitle: vehicle?.model ?? AppStrings.vehicleNone,
                    onTap: () => context.push(AppRoutes.vehicle),
                  ),
                  const Divider(height: 1, color: DriverTokens.outlineVariant),
                  _PrefTile(
                    key: const Key('profile_documents'),
                    icon: Icons.description_outlined,
                    title: AppStrings.profileMenuDocuments,
                    subtitle: AppStrings.documentsTitle,
                    onTap: () => context.push(AppRoutes.documents),
                  ),
                  const Divider(height: 1, color: DriverTokens.outlineVariant),
                  _PrefTile(
                    key: const Key('profile_ratings'),
                    icon: Icons.star_outline,
                    title: AppStrings.profileMenuRatings,
                    onTap: () => context.push(AppRoutes.ratings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DriverTokens.spaceLg),
            Material(
              color: DriverTokens.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
                side: const BorderSide(color: DriverTokens.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _PrefTile(
                    key: const Key('profile_settings'),
                    icon: Icons.settings_outlined,
                    title: AppStrings.profileMenuSettings,
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                  const Divider(height: 1, color: DriverTokens.outlineVariant),
                  _PrefTile(
                    key: const Key('profile_support'),
                    icon: Icons.support_agent,
                    title: AppStrings.profileMenuSupport,
                    onTap: () => context.push(AppRoutes.support),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DriverTokens.spaceLg),
            Material(
              color: DriverTokens.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
                side: const BorderSide(color: DriverTokens.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: const Key('logout'),
                minTileHeight: DriverTokens.touchTarget + 8,
                leading: const Icon(Icons.logout, color: DriverTokens.danger),
                title: Text(
                  AppStrings.logout,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: DriverTokens.danger,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: DriverTokens.danger,
                ),
                onTap: () => confirmLogout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: DriverTokens.touchTarget + 8,
      leading: Icon(icon, color: DriverTokens.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: DriverTokens.onSurfaceVariant),
            ),
      trailing: const Icon(Icons.chevron_right, color: DriverTokens.outline),
      onTap: onTap,
    );
  }
}
