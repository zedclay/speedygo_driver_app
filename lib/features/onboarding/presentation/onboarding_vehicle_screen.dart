import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_scaffold.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

/// Step 4 — vehicle form. Types: MOTORCYCLE | SCOOTER | CAR (no bicycle).
class OnboardingVehicleScreen extends ConsumerStatefulWidget {
  const OnboardingVehicleScreen({super.key, this.popOnSave = false});

  /// When opened from Profile → Vehicle, return instead of advancing.
  final bool popOnSave;

  @override
  ConsumerState<OnboardingVehicleScreen> createState() =>
      _OnboardingVehicleScreenState();
}

class _OnboardingVehicleScreenState
    extends ConsumerState<OnboardingVehicleScreen>
    with OnboardingLoader {
  final _plate = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  String _type = driverVehicleTypes.first;
  bool _prefilled = false;
  String? _error;

  @override
  void dispose() {
    _plate.dispose();
    _model.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_plate.text.trim().isEmpty || _model.text.trim().isEmpty) {
      setState(() => _error = AppStrings.fullNameInvalid);
      return;
    }
    setState(() => _error = null);
    final ok = await ref
        .read(onboardingControllerProvider.notifier)
        .saveVehicle(
          type: _type,
          plateNumber: _plate.text.trim(),
          model: _model.text.trim(),
          color: _color.text.trim(),
        );
    if (!ok || !mounted) return;
    if (widget.popOnSave) {
      context.pop();
      return;
    }
    final me = ref.read(onboardingControllerProvider).me;
    context.go(
      me == null ? onboardingRouteFor(null) : nextIncompleteStepRoute(me),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(onboardingControllerProvider).me;
    final vehicle = me?.activeVehicle;
    if (!_prefilled && vehicle != null) {
      _plate.text = vehicle.plateNumber;
      _model.text = vehicle.model;
      _color.text = vehicle.color ?? '';
      if (driverVehicleTypes.contains(vehicle.type)) _type = vehicle.type;
      _prefilled = true;
    }
    final locked = me != null && !me.isOnboardingEditable;
    return OnboardingScaffold(
      step: widget.popOnSave ? null : 4,
      title: widget.popOnSave
          ? AppStrings.vehicleTitle
          : AppStrings.vehicleFormTitle,
      actionLabel: locked ? null : AppStrings.vehicleSave,
      actionKey: const Key('vehicle_save_button'),
      onAction: _save,
      children: [
        if (locked) ...[
          Text(AppStrings.vehicleLockedNote),
          const SizedBox(height: DriverTokens.spaceMd),
        ],
        Text(
          AppStrings.vehicleType,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: DriverTokens.spaceSm),
        Wrap(
          spacing: DriverTokens.spaceSm,
          children: [
            for (final type in driverVehicleTypes)
              ChoiceChip(
                key: Key('vehicle_type_$type'),
                label: Text(AppStrings.vehicleTypeLabel(type)),
                selected: _type == type,
                onSelected: locked ? null : (_) => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: DriverTokens.spaceLg),
        TextField(
          key: const Key('vehicle_plate'),
          controller: _plate,
          enabled: !locked,
          decoration: InputDecoration(
            labelText: AppStrings.vehiclePlate,
            errorText: _error,
          ),
        ),
        const SizedBox(height: DriverTokens.spaceMd),
        TextField(
          key: const Key('vehicle_model'),
          controller: _model,
          enabled: !locked,
          decoration: InputDecoration(labelText: AppStrings.vehicleModel),
        ),
        const SizedBox(height: DriverTokens.spaceMd),
        TextField(
          key: const Key('vehicle_color'),
          controller: _color,
          enabled: !locked,
          decoration: InputDecoration(labelText: AppStrings.vehicleColor),
        ),
      ],
    );
  }
}
