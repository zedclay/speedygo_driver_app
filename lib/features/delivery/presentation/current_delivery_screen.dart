import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.logoutConfirmTitle),
        content: Text(AppStrings.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            key: const Key('logout_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.logoutConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(sessionControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(currentDeliveryControllerProvider);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final showPickupUi = state.delivery?.canConfirmPickup == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.deliveryTitle),
        leading: IconButton(
          key: const Key('delivery_back_home'),
          tooltip: AppStrings.homeTitle,
          onPressed: () => context.go(AppRoutes.home),
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
                : () => ref
                      .read(currentDeliveryControllerProvider.notifier)
                      .load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            key: const Key('delivery_logout'),
            tooltip: AppStrings.logout,
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
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
                              const SizedBox(height: 16),
                              Text(AppStrings.deliveryLoading),
                            ],
                          ),
                        ),
                      ),
                    if (state.loadStatus == DeliveryLoadStatus.empty)
                      _EmptyState(
                        onRetry: () => ref
                            .read(currentDeliveryControllerProvider.notifier)
                            .load(),
                      ),
                    if (state.loadStatus == DeliveryLoadStatus.error &&
                        state.delivery == null)
                      _ErrorState(
                        message:
                            state.errorMessage ?? AppStrings.unexpectedError,
                        onRetry: () => ref
                            .read(currentDeliveryControllerProvider.notifier)
                            .load(),
                      ),
                    if (state.delivery != null) ...[
                      _StatusCard(
                        status: state.delivery!.deliveryStatus,
                        orderId: state.delivery!.orderId,
                        assignmentId: state.delivery!.assignmentId,
                      ),
                      const SizedBox(height: 20),
                      if (state.successMessage != null)
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
                        const SizedBox(height: 12),
                      ],
                      if (showPickupUi) ...[
                        PickupCodeInput(
                          value: state.pickupCode,
                          enabled: !state.submitting,
                          onChanged: (value) => ref
                              .read(currentDeliveryControllerProvider.notifier)
                              .updatePickupCode(value),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (state.delivery!.isPickedUp &&
                          !showPickupUi &&
                          state.successMessage == null)
                        Text(
                          AppStrings.deliveryStatusLabel(
                            state.delivery!.deliveryStatus,
                          ),
                          style: theme.textTheme.titleMedium,
                        ),
                    ],
                    SizedBox(height: showPickupUi ? 88 : 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: showPickupUi
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  12 + bottomInset.clamp(0, 24),
                ),
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: const Key('confirm_pickup_button'),
                    onPressed: state.canSubmit
                        ? () => ref
                              .read(currentDeliveryControllerProvider.notifier)
                              .confirmPickup()
                        : null,
                    child: state.submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppStrings.confirmPickup),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.orderId,
    required this.assignmentId,
  });

  final String status;
  final String orderId;
  final String assignmentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(theme, status);
    return Semantics(
      label:
          '${AppStrings.statusLabel}: ${AppStrings.deliveryStatusLabel(status)}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.deliveryStatusLabel(status),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${AppStrings.orderIdLabel}: $orderId',
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${AppStrings.assignmentLabel}: $assignmentId',
                textAlign: TextAlign.left,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, String status) {
    switch (status) {
      case 'AT_PICKUP':
        return theme.colorScheme.tertiary;
      case 'PICKED_UP':
      case 'IN_TRANSIT':
        return theme.colorScheme.primary;
      case 'DELIVERED':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurface;
    }
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
          const SizedBox(height: 16),
          Text(AppStrings.deliveryEmpty, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
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
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
