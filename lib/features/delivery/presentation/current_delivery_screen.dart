import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/delivery_cod_card.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/delivery_help_card.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/delivery_nav_card.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/delivery_status_header.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/pickup_code_input.dart';

class CurrentDeliveryScreen extends ConsumerStatefulWidget {
  const CurrentDeliveryScreen({super.key});

  @override
  ConsumerState<CurrentDeliveryScreen> createState() =>
      _CurrentDeliveryScreenState();
}

class _CurrentDeliveryScreenState extends ConsumerState<CurrentDeliveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentDeliveryControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(currentDeliveryControllerProvider);
    final controller = ref.read(currentDeliveryControllerProvider.notifier);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final delivery = state.delivery;
    final showPickupUi = delivery?.canConfirmPickup == true;
    final stickyAction = (delivery != null && !delivery.isDelivered)
        ? delivery.primaryAction
        : null;
    final showNav =
        delivery != null &&
        !delivery.isDelivered &&
        delivery.deliveryStatus != 'AT_PICKUP';
    final showCod =
        delivery != null && delivery.canCollectCod && !delivery.isDelivered;

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      appBar: AppBar(
        title: Text(AppStrings.deliveryTitle),
        leading: IconButton(
          key: const Key('delivery_back_home'),
          tooltip: AppStrings.homeTitle,
          onPressed: () {
            ref.read(driverNavSnapshotProvider.notifier).clearActiveDelivery();
            context.go(AppRoutes.home);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            key: const Key('delivery_language'),
            tooltip: AppStrings.languageSettingsTitle,
            onPressed: () => context.push(AppRoutes.languageSettings),
            icon: const Icon(Icons.language),
          ),
          IconButton(
            key: const Key('delivery_refresh'),
            tooltip: AppStrings.deliveryRefresh,
            onPressed: state.loadStatus == DeliveryLoadStatus.loading
                ? null
                : () => controller.load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                DriverTokens.edgeMargin,
                DriverTokens.spaceLg,
                DriverTokens.edgeMargin,
                // Extra space when COD is visible so collect isn't under sticky complete.
                24 +
                    bottomInset +
                    (stickyAction != null ? 72 : 0) +
                    (showCod && !state.codCollected ? 88 : 0),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.loadStatus == DeliveryLoadStatus.loading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: DriverTokens.spaceLg),
                              Text(AppStrings.deliveryLoading),
                            ],
                          ),
                        ),
                      ),
                    if (state.loadStatus == DeliveryLoadStatus.empty)
                      _EmptyState(onRetry: controller.load),
                    if (state.loadStatus == DeliveryLoadStatus.error &&
                        delivery == null)
                      _ErrorState(
                        message:
                            state.errorMessage ?? AppStrings.unexpectedError,
                        onRetry: controller.load,
                      ),
                    if (delivery != null) ...[
                      if (delivery.isDelivered)
                        _DeliveredBanner(
                          onDone: () {
                            controller.reset();
                            ref
                                .read(driverNavSnapshotProvider.notifier)
                                .clearActiveDelivery();
                            context.go(AppRoutes.home);
                          },
                        )
                      else
                        DeliveryStatusHeader(delivery: delivery),
                      const SizedBox(height: DriverTokens.spaceLg),
                      if (state.successMessage != null && !delivery.isDelivered)
                        _Banner(
                          color: theme.colorScheme.primaryContainer,
                          foreground: theme.colorScheme.onPrimaryContainer,
                          icon: Icons.check_circle_outline,
                          message: state.successMessage!,
                        ),
                      if (state.errorMessage != null) ...[
                        _Banner(
                          color: theme.colorScheme.errorContainer,
                          foreground: theme.colorScheme.onErrorContainer,
                          icon: Icons.error_outline,
                          message: state.errorMessage!,
                        ),
                        const SizedBox(height: DriverTokens.spaceMd),
                      ],
                      if (showNav) ...[
                        DeliveryNavCard(delivery: delivery),
                        const SizedBox(height: DriverTokens.spaceLg),
                      ],
                      if (showPickupUi) ...[
                        PickupCodeInput(
                          value: state.pickupCode,
                          enabled: !state.submitting,
                          onChanged: controller.updatePickupCode,
                        ),
                        const SizedBox(height: DriverTokens.spaceXl),
                      ],
                      if (showCod) ...[
                        DeliveryCodCard(
                          amountInput: state.codAmountInput,
                          collected: state.codCollected,
                          busy: state.codBusy,
                          canSubmit: state.canCollectCod,
                          onChanged: controller.updateCodAmount,
                          onSubmit: () {
                            final amount = state.codAmountMinor;
                            if (amount != null) {
                              controller.collectCod(amount);
                            }
                          },
                        ),
                        const SizedBox(height: DriverTokens.spaceLg),
                      ],
                      if (!delivery.isDelivered) const DeliveryHelpCard(),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: stickyAction == null
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DriverTokens.edgeMargin,
                  DriverTokens.spaceSm,
                  DriverTokens.edgeMargin,
                  12 + bottomInset.clamp(0, 24),
                ),
                child: SizedBox(
                  height: DriverTokens.actionHeight,
                  child: FilledButton(
                    key: stickyAction == DeliveryActions.confirmPickup
                        ? const Key('confirm_pickup_button')
                        : Key('delivery_action_$stickyAction'),
                    onPressed: state.submitting
                        ? null
                        : stickyAction == DeliveryActions.confirmPickup
                        ? (state.canSubmit
                              ? () => controller.confirmPickup()
                              : null)
                        : () => controller.performAction(stickyAction),
                    child: state.submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppStrings.deliveryActionLabel(stickyAction)),
                  ),
                ),
              ),
            ),
    );
  }
}

class _DeliveredBanner extends StatelessWidget {
  const _DeliveredBanner({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('delivered_banner'),
      padding: const EdgeInsets.all(DriverTokens.spaceLg),
      decoration: BoxDecoration(
        color: DriverTokens.successContainer,
        borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
        border: Border.all(color: DriverTokens.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: DriverTokens.success),
              const SizedBox(width: DriverTokens.spaceMd),
              Expanded(
                child: Text(
                  AppStrings.deliveredSuccess,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: DriverTokens.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(AppStrings.deliveredBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: DriverTokens.spaceLg),
          SizedBox(
            height: DriverTokens.touchTarget,
            child: FilledButton(
              key: const Key('delivery_done_back'),
              onPressed: onDone,
              child: Text(AppStrings.backToOrders),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48),
          const SizedBox(height: DriverTokens.spaceLg),
          Text(AppStrings.deliveryEmpty, textAlign: TextAlign.center),
          const SizedBox(height: DriverTokens.spaceLg),
          SizedBox(
            height: DriverTokens.touchTarget,
            child: OutlinedButton(
              key: const Key('delivery_empty_retry'),
              onPressed: onRetry,
              child: Text(AppStrings.retry),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: DriverTokens.spaceLg),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: DriverTokens.spaceLg),
          SizedBox(
            height: DriverTokens.touchTarget,
            child: FilledButton(
              key: const Key('delivery_error_retry'),
              onPressed: onRetry,
              child: Text(AppStrings.retry),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.message,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: DriverTokens.spaceMd),
      padding: const EdgeInsets.all(DriverTokens.spaceMd),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
