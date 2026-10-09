import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_scaffold.dart';

/// Step 1 — personal info ("inscription"). Creates or updates the profile.
class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen>
    with OnboardingLoader {
  final _name = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final ok = await ref
        .read(onboardingControllerProvider.notifier)
        .saveProfile(_name.text);
    if (ok && mounted) {
      final me = ref.read(onboardingControllerProvider).me;
      context.go(onboardingRouteFor(me));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(onboardingControllerProvider).me;
    if (!_prefilled && me?.profileFullName != null) {
      _name.text = me!.profileFullName!;
      _prefilled = true;
    }
    final locked = me != null && !me.isOnboardingEditable;
    return OnboardingScaffold(
      step: 1,
      title: AppStrings.onboardingTitle,
      actionLabel: locked ? null : AppStrings.onboardingNext,
      actionKey: const Key('onboarding_profile_next'),
      onAction: _continue,
      children: [
        Text(
          AppStrings.onboardingStepProfile,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('onboarding_full_name'),
          controller: _name,
          enabled: !locked,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: AppStrings.fullNameLabel),
        ),
        if (locked) ...[
          const SizedBox(height: 12),
          Text(AppStrings.onboardingLocked),
        ],
      ],
    );
  }
}
