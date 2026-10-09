import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/empty_state_view.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';

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
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: DriverTokens.spaceSm),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Directionality(textDirection: TextDirection.ltr, child: Text(value)),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.vehicleTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DriverTokens.edgeMargin),
        children: [
          if (vehicle == null)
            EmptyStateView(
              title: AppStrings.vehicleNone,
              icon: Icons.two_wheeler,
            )
          else
            OperationalCard(
              key: const Key('vehicle_card'),
              title: AppStrings.vehicleTypeLabel(vehicle.type),
              child: Column(
                children: [
                  row(AppStrings.vehiclePlate, vehicle.plateNumber),
                  row(AppStrings.vehicleModel, vehicle.model),
                  if (vehicle.color != null)
                    row(AppStrings.vehicleColor, vehicle.color!),
                ],
              ),
            ),
          const SizedBox(height: DriverTokens.spaceLg),
          if (me != null && me.isOnboardingEditable)
            SizedBox(
              height: DriverTokens.actionHeight,
              child: FilledButton(
                key: const Key('vehicle_edit'),
                onPressed: () => context.push(AppRoutes.vehicleEdit),
                child: Text(AppStrings.vehicleSave),
              ),
            )
          else
            Text(AppStrings.vehicleLockedNote),
        ],
      ),
    );
  }
}
