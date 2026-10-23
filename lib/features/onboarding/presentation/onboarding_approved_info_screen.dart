import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';

/// Read-only snapshot of server-backed approved driver fields.
class OnboardingApprovedInfoScreen extends ConsumerStatefulWidget {
  const OnboardingApprovedInfoScreen({super.key});

  @override
  ConsumerState<OnboardingApprovedInfoScreen> createState() =>
      _OnboardingApprovedInfoScreenState();
}

class _OnboardingApprovedInfoScreenState
    extends ConsumerState<OnboardingApprovedInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(onboardingControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final me = ref.watch(onboardingControllerProvider).me;
    final vehicle = me?.activeVehicle;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: DriverTokens.coolWhite,
      appBar: AppBar(
        backgroundColor: DriverTokens.surfaceContainerLowest,
        foregroundColor: DriverTokens.navy,
        elevation: 0,
        title: Text(
          AppStrings.approvedInfoTitle,
          style: const TextStyle(
            color: DriverTokens.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          key: const Key('approved_info_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.onboardingApproved);
            }
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            Text(
              AppStrings.approvedInfoReadOnlyNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceXl),
            _row(
              AppStrings.reviewFullNameLabel,
              me?.profileFullName?.trim().isNotEmpty == true
                  ? me!.profileFullName!.trim()
                  : '—',
            ),
            _row(
              AppStrings.identityTitle,
              me?.identityDocumentComplete == true
                  ? AppStrings.correctionsTransmitted
                  : AppStrings.correctionsMissingDoc,
            ),
            _row(
              AppStrings.licenseTitle,
              me?.drivingLicenseComplete == true
                  ? AppStrings.correctionsTransmitted
                  : AppStrings.correctionsMissingDoc,
            ),
            _row(
              AppStrings.approvedYourVehicle,
              vehicle == null
                  ? AppStrings.approvedVehicleNotReady
                  : [
                      vehicle.model,
                      vehicle.plateNumber,
                    ].where((s) => s.trim().isNotEmpty).join(' · '),
            ),
            if (vehicle != null)
              _row(AppStrings.onboardingStepVehicle, vehicle.type, ltr: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: DriverTokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textDirection: ltr ? TextDirection.ltr : null,
            style: const TextStyle(
              color: DriverTokens.navy,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }
}
