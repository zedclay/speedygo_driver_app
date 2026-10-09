import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';

enum OnboardingOutcome { pending, approved, corrections }

/// Terminal-ish states: pending review, approved, corrections required.
class OnboardingStatusScreen extends ConsumerStatefulWidget {
  const OnboardingStatusScreen({super.key, required this.outcome});

  final OnboardingOutcome outcome;

  @override
  ConsumerState<OnboardingStatusScreen> createState() =>
      _OnboardingStatusScreenState();
}

class _OnboardingStatusScreenState
    extends ConsumerState<OnboardingStatusScreen> {
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
    final theme = Theme.of(context);
    final (icon, color, title, body, cta, route) = switch (widget.outcome) {
      OnboardingOutcome.pending => (
        Icons.hourglass_top,
        DriverTokens.warning,
        AppStrings.pendingTitle,
        AppStrings.pendingBody,
        AppStrings.navOrders,
        AppRoutes.home,
      ),
      OnboardingOutcome.approved => (
        Icons.verified_outlined,
        DriverTokens.success,
        AppStrings.approvedTitle,
        AppStrings.approvedBody,
        AppStrings.approvedCta,
        AppRoutes.home,
      ),
      OnboardingOutcome.corrections => (
        Icons.edit_note,
        DriverTokens.danger,
        AppStrings.correctionsTitle,
        AppStrings.correctionsBody,
        AppStrings.correctionsCta,
        AppRoutes.onboardingProfile,
      ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.onboardingTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DriverTokens.edgeMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 72, color: color),
                const SizedBox(height: DriverTokens.spaceLg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DriverTokens.spaceSm),
                Text(body, textAlign: TextAlign.center),
                const SizedBox(height: DriverTokens.spaceXl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('onboarding_status_cta'),
                    onPressed: () => context.go(route),
                    child: Text(cta),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
