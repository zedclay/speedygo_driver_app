import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
import 'package:speedygo_driver_app/core/design_system/primary_action_bar.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';

/// Shared chrome for onboarding steps: app bar, step progress, messages,
/// and a sticky primary action.
class OnboardingScaffold extends ConsumerWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.children,
    this.step,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.showBack = true,
  });

  /// 1-based step index out of 5 (profile, identity, license, vehicle, review).
  final int? step;
  final String title;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final bool showBack;

  static const totalSteps = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(onboardingControllerProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: showBack),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            DriverTokens.edgeMargin,
            DriverTokens.spaceLg,
            DriverTokens.edgeMargin,
            DriverTokens.spaceXl + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (step != null) ...[
                LinearProgressIndicator(
                  key: const Key('onboarding_progress'),
                  value: step! / totalSteps,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(DriverTokens.radiusSm),
                ),
                const SizedBox(height: DriverTokens.spaceLg),
              ],
              if (state.errorMessage != null) ...[
                InfoBanner(
                  key: const Key('onboarding_error'),
                  message: state.errorMessage!,
                  tone: StatusTone.danger,
                ),
                const SizedBox(height: DriverTokens.spaceMd),
              ],
              if (state.successMessage != null) ...[
                InfoBanner(
                  message: state.successMessage!,
                  tone: StatusTone.success,
                ),
                const SizedBox(height: DriverTokens.spaceMd),
              ],
              ...children,
            ],
          ),
        ),
      ),
      bottomNavigationBar: actionLabel == null
          ? null
          : PrimaryActionBar(
              buttonKey: actionKey,
              label: actionLabel!,
              busy: state.busy,
              onPressed: onAction,
            ),
    );
  }
}

/// Loads `/driver/me` once when an onboarding screen is first shown.
mixin OnboardingLoader<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(onboardingControllerProvider.notifier);
      if (ref.read(onboardingControllerProvider).me == null) {
        controller.load();
      }
    });
  }
}

String stepLabel(bool done) => done ? AppStrings.stepDone : AppStrings.stepTodo;
