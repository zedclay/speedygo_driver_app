import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';

/// Full-screen logout confirmation (Stitch `d_connexion_confirmation`).
///
/// Policy: session logout remains allowed even with an active delivery —
/// server ownership restores the assignment after re-login. Cancel leaves
/// availability, task, drafts, and navigation unchanged.
class LogoutConfirmationScreen extends ConsumerWidget {
  const LogoutConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    final me = ref.watch(onboardingControllerProvider).me;
    final home = ref.watch(driverHomeControllerProvider);
    final name =
        me?.profileFullName ??
        home.me?.profileFullName ??
        AppStrings.profileNoName;
    final vehicle = me?.activeVehicle;
    final vehicleLine = (vehicle?.model.trim().isNotEmpty == true)
        ? vehicle!.model.trim()
        : AppStrings.vehicleNone;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      appBar: DriverNestedAppBar(
        title: AppStrings.logoutScreenTitle,
        leading: IconButton(
          key: const Key('logout_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DriverTokens.edgeMargin,
            DriverTokens.spaceLg,
            DriverTokens.edgeMargin,
            DriverTokens.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DriverTokens.spaceLg),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: DriverTokens.dangerContainer,
                    shape: BoxShape.circle,
                    boxShadow: DriverTokens.cardShadow,
                  ),
                  child: Icon(
                    Icons.logout,
                    size: 56,
                    color: DriverTokens.danger,
                  ),
                ),
              ),
              const SizedBox(height: DriverTokens.spaceXl),
              Container(
                padding: const EdgeInsets.all(DriverTokens.spaceMd),
                decoration: BoxDecoration(
                  color: DriverTokens.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
                  border: Border.all(color: DriverTokens.outlineVariant),
                  boxShadow: DriverTokens.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (vehicleLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        vehicleLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DriverTokens.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DriverTokens.spaceLg),
              Container(
                padding: const EdgeInsets.all(DriverTokens.spaceMd),
                decoration: BoxDecoration(
                  color: DriverTokens.dangerContainer,
                  borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
                  border: Border.all(
                    color: DriverTokens.danger.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: DriverTokens.danger),
                        const SizedBox(width: DriverTokens.spaceXs),
                        Text(
                          AppStrings.logoutAttentionLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: DriverTokens.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DriverTokens.spaceSm),
                    Text(
                      AppStrings.logoutConfirmWarningFull,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DriverTokens.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: DriverTokens.actionHeight,
                child: FilledButton.icon(
                  key: const Key('logout_confirm'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DriverTokens.danger,
                    foregroundColor: DriverTokens.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusLg,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(sessionControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.power_settings_new),
                  label: Text(AppStrings.logoutConfirmAction),
                ),
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              SizedBox(
                height: DriverTokens.actionHeight,
                child: OutlinedButton(
                  key: const Key('confirmation_cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DriverTokens.primary,
                    side: const BorderSide(
                      color: DriverTokens.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusLg,
                      ),
                    ),
                  ),
                  onPressed: () {
                    // Prefer pop to restore prior shell tab; fall back to Profile.
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.profile);
                    }
                  },
                  child: Text(AppStrings.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
