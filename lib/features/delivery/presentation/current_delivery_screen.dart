import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/date_format.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/delivery_cod_card.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/delivery_details_sheet.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/delivery_help_card.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/widgets/delivery_map_canvas.dart';
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
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _keyboardWasOpen = false;
  String? _sheetDeliveryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentDeliveryControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  bool _toMerchant(DriverCurrentDelivery delivery) =>
      delivery.deliveryStatus == 'DRIVER_ASSIGNED' ||
      delivery.deliveryStatus == 'TO_PICKUP' ||
      delivery.deliveryStatus == 'AT_PICKUP';

  void _onKeyboardChanged({
    required bool keyboardOpen,
    required DeliverySheetSnaps snaps,
  }) {
    if (keyboardOpen == _keyboardWasOpen) return;
    _keyboardWasOpen = keyboardOpen;
    if (!keyboardOpen || !_sheetController.isAttached) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        snaps.expanded,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
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
    final showCod =
        delivery != null && delivery.canCollectCod && !delivery.isDelivered;

    if (delivery == null ||
        state.loadStatus == DeliveryLoadStatus.loading ||
        state.loadStatus == DeliveryLoadStatus.empty ||
        state.loadStatus == DeliveryLoadStatus.error) {
      return Scaffold(
        backgroundColor: DriverTokens.surface,
        appBar: DriverNestedAppBar(title: AppStrings.deliveryTitle),
        body: SafeArea(
          child: _NonActiveBody(
            state: state,
            controller: controller,
            theme: theme,
          ),
        ),
      );
    }

    if (delivery.isDelivered) {
      void done() {
        controller.reset();
        ref.read(driverNavSnapshotProvider.notifier).clearActiveDelivery();
        context.go(AppRoutes.home);
      }

      return Scaffold(
        backgroundColor: DriverTokens.surface,
        appBar: DriverNestedAppBar(
          title: AppStrings.deliveryTitle,
          actions: [
            IconButton(
              key: const Key('delivery_language'),
              tooltip: AppStrings.languageSettingsTitle,
              onPressed: () => context.push(AppRoutes.languageSettings),
              icon: const Icon(Icons.language),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DriverTokens.edgeMargin),
            child: _DeliveredBanner(delivery: delivery),
          ),
        ),
        bottomNavigationBar: _StickyBar(
          child: SizedBox(
            height: DriverTokens.actionHeight,
            child: FilledButton.icon(
              key: const Key('delivery_done_back'),
              onPressed: done,
              icon: const Icon(Icons.home_outlined),
              label: Text(AppStrings.backToHome),
            ),
          ),
        ),
      );
    }

    final orderRef = delivery.orderId;
    final keyboardOpen = bottomInset > 0;
    final preferTall = showPickupUi || showCod || keyboardOpen;

    // Remount sheet only when the delivery identity changes — keeps extent
    // stable across refresh / error / lifecycle field updates.
    if (_sheetDeliveryId != delivery.deliveryId) {
      _sheetDeliveryId = delivery.deliveryId;
      _keyboardWasOpen = false;
    }

    Widget sheetBody(ScrollController scrollController) {
      // Column inside SingleChildScrollView builds all fields (not lazy), so
      // pickup/COD, validation, and copy rows stay reachable via the shared
      // sheet ScrollController without gesture conflicts.
      return SingleChildScrollView(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          DriverTokens.edgeMargin,
          0,
          DriverTokens.edgeMargin,
          DriverTokens.spaceXl + (keyboardOpen ? 24 : 0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DeliverySheetHandle(),
            if (state.successMessage != null)
              _Banner(
                color: theme.colorScheme.primaryContainer,
                foreground: theme.colorScheme.onPrimaryContainer,
                icon: Icons.check_circle_outline,
                message: state.successMessage!,
              ),
            if (state.errorMessage != null)
              _Banner(
                color: theme.colorScheme.errorContainer,
                foreground: theme.colorScheme.onErrorContainer,
                icon: Icons.error_outline,
                message: state.errorMessage!,
              ),
            DeliveryStatusHeader(delivery: delivery),
            const SizedBox(height: DriverTokens.spaceMd),
            DeliveryNavCard(delivery: delivery),
            if (showPickupUi) ...[
              const SizedBox(height: DriverTokens.spaceLg),
              PickupCodeInput(
                value: state.pickupCode,
                enabled: !state.submitting,
                onChanged: controller.updatePickupCode,
              ),
              const SizedBox(height: DriverTokens.spaceMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: DriverTokens.outline,
                  ),
                  const SizedBox(width: DriverTokens.spaceSm),
                  Expanded(
                    child: Text(
                      AppStrings.deliveryPrivacyNote,
                      key: const Key('delivery_privacy_note'),
                      softWrap: true,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DriverTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (showCod) ...[
              const SizedBox(height: DriverTokens.spaceLg),
              DeliveryCodCard(
                amountInput: state.codAmountInput,
                collected: state.codCollected,
                busy: state.codBusy,
                canSubmit: state.canCollectCod,
                invalidAmount: state.hasInvalidCodAmount,
                expectedAmountLabel: delivery.expectedCodAmountMinor == null
                    ? null
                    : AppStrings.codExpectedAmount(
                        AppStrings.formatMinorUnits(
                          delivery.expectedCodAmountMinor!,
                        ),
                      ),
                onChanged: controller.updateCodAmount,
                onSubmit: () {
                  final amount = state.codAmountMinor;
                  if (amount != null) {
                    controller.collectCod(amount);
                  }
                },
              ),
            ],
            const SizedBox(height: DriverTokens.spaceLg),
            const DeliveryHelpCard(),
            // Extra scroll room so validation / COD submit clear the sticky bar.
            const SizedBox(height: DriverTokens.spaceXl),
          ],
        ),
      );
    }

    Widget primaryButton() {
      if (stickyAction == null) return const SizedBox.shrink();
      return _StickyBar(
        bottomInset: bottomInset.clamp(0, 24),
        child: SizedBox(
          height: DriverTokens.actionHeight,
          child: FilledButton.icon(
            key: stickyAction == DeliveryActions.confirmPickup
                ? const Key('confirm_pickup_button')
                : Key('delivery_action_$stickyAction'),
            onPressed: state.submitting
                ? null
                : stickyAction == DeliveryActions.confirmPickup
                ? (state.canSubmit ? () => controller.confirmPickup() : null)
                : () => controller.performAction(stickyAction),
            icon: Icon(
              stickyAction == DeliveryActions.arrivePickup ||
                      stickyAction == DeliveryActions.arriveCustomer
                  ? Icons.location_on
                  : Icons.check_circle_outline,
            ),
            label: state.submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppStrings.deliveryActionLabel(stickyAction)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      resizeToAvoidBottomInset: true,
      appBar: DriverNestedAppBar(
        subtitle: AppStrings.deliveryTaskPhase(delivery.deliveryStatus),
        title: orderRef,
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
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: StatusBadge(
              label: AppStrings.deliveryInProgressBadge,
              tone: StatusTone.success,
            ),
          ),
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
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final snaps = DeliverySheetSnaps.forViewport(
                  viewportHeight: constraints.maxHeight,
                  preferTall: preferTall,
                );
                _onKeyboardChanged(
                  keyboardOpen: keyboardOpen,
                  snaps: snaps,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: DeliveryMapCanvas(
                        toMerchant: _toMerchant(delivery),
                      ),
                    ),
                    DeliveryDetailsSheet(
                      key: ValueKey('sheet-${delivery.deliveryId}'),
                      snaps: snaps,
                      controller: _sheetController,
                      childBuilder: (context, scrollController) =>
                          sheetBody(scrollController),
                    ),
                  ],
                );
              },
            ),
          ),
          primaryButton(),
        ],
      ),
    );
  }
}

class _NonActiveBody extends StatelessWidget {
  const _NonActiveBody({
    required this.state,
    required this.controller,
    required this.theme,
  });

  final CurrentDeliveryState state;
  final CurrentDeliveryController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DriverTokens.edgeMargin),
      child: Column(
        children: [
          if (state.loadStatus == DeliveryLoadStatus.loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: DriverTokens.spaceLg),
                  Text(AppStrings.deliveryLoading),
                ],
              ),
            ),
          if (state.loadStatus == DeliveryLoadStatus.empty)
            _EmptyState(onRetry: controller.load),
          if (state.loadStatus == DeliveryLoadStatus.error)
            _ErrorState(
              message: state.errorMessage ?? AppStrings.unexpectedError,
              onRetry: controller.load,
            ),
        ],
      ),
    );
  }
}

/// Sticky bottom action bar shared by the active sheet and the delivered view.
/// Pinned outside the scrolling sheet so lifecycle CTAs stay reachable.
class _StickyBar extends StatelessWidget {
  const _StickyBar({required this.child, this.bottomInset = 0});

  final Widget child;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('delivery_sticky_action'),
      decoration: const BoxDecoration(
        color: DriverTokens.card,
        border: Border(top: BorderSide(color: DriverTokens.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            DriverTokens.edgeMargin,
            DriverTokens.spaceMd,
            DriverTokens.edgeMargin,
            12 + bottomInset,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Stitch "Livraison terminée": lime check medallion, title, summary card.
/// Only server-provided fields are shown; no distance/duration/client data.
class _DeliveredBanner extends StatelessWidget {
  const _DeliveredBanner({required this.delivery});

  final DriverCurrentDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String label, Widget value) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DriverTokens.textSecondary,
            ),
          ),
        ),
        value,
      ],
    );
    return Column(
      key: const Key('delivered_banner'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DriverTokens.spaceXl),
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: DriverTokens.tertiaryFixed,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: DriverTokens.onTertiaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: DriverTokens.tertiaryFixed,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: DriverTokens.spaceXl),
        Text(
          AppStrings.deliveredSuccess,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: DriverTokens.spaceSm),
        Text(
          AppStrings.deliveredBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: DriverTokens.textSecondary,
          ),
        ),
        const SizedBox(height: DriverTokens.spaceXl),
        Container(
          padding: const EdgeInsets.all(DriverTokens.spaceLg),
          decoration: BoxDecoration(
            color: DriverTokens.card,
            borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
            border: Border.all(color: DriverTokens.outlineVariant),
            boxShadow: DriverTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.deliveredOrderLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: DriverTokens.textSecondary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  delivery.orderId,
                  softWrap: true,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Divider(height: DriverTokens.spaceXl),
              row(
                AppStrings.statusLabel,
                StatusBadge(
                  label: AppStrings.deliveryStatusLabel(
                    delivery.deliveryStatus,
                  ),
                  tone: StatusTone.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
              if (delivery.deliveredAt != null) ...[
                const SizedBox(height: DriverTokens.spaceMd),
                row(
                  AppStrings.historyDeliveredAt,
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      formatIsoDateTime(delivery.deliveredAt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
            child: Text(
              message,
              softWrap: true,
              style: TextStyle(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
