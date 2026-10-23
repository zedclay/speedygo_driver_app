import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/empty_state_view.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/profile/presentation/profile_screen.dart';

/// Read-only active vehicle. Editing reuses the onboarding vehicle form.
class VehicleScreen extends ConsumerStatefulWidget {
  const VehicleScreen({super.key});

  @override
  ConsumerState<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends ConsumerState<VehicleScreen> {
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
    final me = ref.watch(onboardingControllerProvider).me;
    final vehicle = me?.activeVehicle;
    final theme = Theme.of(context);
    final status = me?.verificationStatus;

    BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
      color: color ?? DriverTokens.card,
      borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
      border: Border.all(color: DriverTokens.outlineVariant),
    );

    Widget labelCaps(String text) => Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: DriverTokens.textSecondary,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: DriverTokens.spaceSm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      appBar: DriverNestedAppBar(title: AppStrings.vehicleTitle),
      body: ListView(
        padding: const EdgeInsets.all(DriverTokens.edgeMargin),
        children: [
          if (vehicle == null)
            EmptyStateView(
              title: AppStrings.vehicleNone,
              icon: Icons.two_wheeler,
            )
          else ...[
            Container(
              key: const Key('vehicle_card'),
              padding: const EdgeInsets.all(DriverTokens.spaceLg),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // No vehicle photo is exposed by the API: honest icon tile.
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: DriverTokens.surfaceContainer,
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusMd,
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_outlined,
                      size: 56,
                      color: DriverTokens.primary,
                    ),
                  ),
                  const SizedBox(height: DriverTokens.spaceLg),
                  Text(
                    vehicle.model,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DriverTokens.spaceSm),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DriverTokens.spaceLg,
                        vertical: DriverTokens.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: DriverTokens.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          DriverTokens.radiusMd,
                        ),
                        border: Border.all(color: DriverTokens.outlineVariant),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          vehicle.plateNumber,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: DriverTokens.spaceMd),
                    child: Divider(
                      height: 1,
                      color: DriverTokens.outlineVariant,
                    ),
                  ),
                  row(
                    AppStrings.vehicleType,
                    AppStrings.vehicleTypeLabel(vehicle.type),
                  ),
                  if (vehicle.color != null)
                    row(AppStrings.vehicleColor, vehicle.color!),
                ],
              ),
            ),
            const SizedBox(height: DriverTokens.spaceLg),
            Container(
              key: const Key('vehicle_status_card'),
              padding: const EdgeInsets.all(DriverTokens.spaceLg),
              decoration: cardDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [labelCaps(AppStrings.vehicleApprovalLabel)],
                    ),
                  ),
                  StatusBadge(
                    label: AppStrings.verificationStatusLabel(status),
                    tone: verificationTone(status),
                    icon: status == 'APPROVED' ? Icons.check_circle : null,
                  ),
                ],
              ),
            ),
            if (me?.profileFullName != null) ...[
              const SizedBox(height: DriverTokens.spaceLg),
              Container(
                padding: const EdgeInsets.all(DriverTokens.spaceLg),
                decoration: cardDecoration(),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: DriverTokens.cobalt,
                      child: Icon(Icons.person, color: DriverTokens.onPrimary),
                    ),
                    const SizedBox(width: DriverTokens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          labelCaps(AppStrings.vehicleRegisteredDriver),
                          const SizedBox(height: 2),
                          Text(
                            me!.profileFullName!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: DriverTokens.spaceLg),
          Container(
            padding: const EdgeInsets.all(DriverTokens.spaceLg),
            decoration: cardDecoration(color: DriverTokens.surfaceContainerLow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.vehicleChangeTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: DriverTokens.spaceSm),
                Text(
                  AppStrings.vehicleChangeBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DriverTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: DriverTokens.spaceLg),
                if (me != null && me.isOnboardingEditable)
                  SizedBox(
                    height: DriverTokens.actionHeight,
                    child: FilledButton.icon(
                      key: const Key('vehicle_edit'),
                      onPressed: () => context.push(AppRoutes.vehicleEdit),
                      icon: const Icon(Icons.edit_document),
                      label: Text(AppStrings.vehicleSave),
                    ),
                  )
                else
                  Text(
                    AppStrings.vehicleLockedNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DriverTokens.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
