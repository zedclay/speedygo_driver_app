import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_scaffold.dart';

/// Step 5 — review checklist and submit for verification.
class OnboardingReviewScreen extends ConsumerStatefulWidget {
  const OnboardingReviewScreen({super.key});

  @override
  ConsumerState<OnboardingReviewScreen> createState() =>
      _OnboardingReviewScreenState();
}

class _OnboardingReviewScreenState extends ConsumerState<OnboardingReviewScreen>
    with OnboardingLoader {
  Future<void> _submit() async {
    final ok = await ref.read(onboardingControllerProvider.notifier).submit();
    if (ok && mounted) context.go(AppRoutes.onboardingPending);
  }

  Widget _row(String label, bool done, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DriverTokens.spaceSm),
      child: OperationalCard(
        title: label,
        onTap: () => context.go(route),
        trailing: StatusBadge(
          label: stepLabel(done),
          tone: done ? StatusTone.success : StatusTone.warning,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DriverMe? me = ref.watch(onboardingControllerProvider).me;
    final ready = me != null && canSubmitVerification(me);
    return OnboardingScaffold(
      step: 5,
      title: AppStrings.reviewTitle,
      actionLabel: AppStrings.reviewSubmit,
      actionKey: const Key('onboarding_submit'),
      onAction: ready ? _submit : null,
      children: [
        Text(AppStrings.reviewIntro),
        const SizedBox(height: DriverTokens.spaceLg),
        _row(
          AppStrings.onboardingStepProfile,
          me?.profileComplete == true,
          AppRoutes.onboardingProfile,
        ),
        _row(
          AppStrings.identityTitle,
          me?.identityDocumentComplete == true,
          AppRoutes.onboardingIdentity,
        ),
        _row(
          AppStrings.licenseTitle,
          me?.drivingLicenseComplete == true,
          AppRoutes.onboardingLicense,
        ),
        _row(
          AppStrings.vehicleFormTitle,
          me?.vehicleComplete == true,
          AppRoutes.onboardingVehicle,
        ),
      ],
    );
  }
}
