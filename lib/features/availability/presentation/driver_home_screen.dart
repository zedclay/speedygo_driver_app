import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/offer_countdown.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverHomeControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(driverHomeControllerProvider.notifier).onAppResumed();
    }
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
    final state = ref.watch(driverHomeControllerProvider);
    final controller = ref.read(driverHomeControllerProvider.notifier);
    final theme = Theme.of(context);

    ref.listen<DriverHomeState>(driverHomeControllerProvider, (prev, next) {
      if (next.acceptedNavigationPending &&
          prev?.acceptedNavigationPending != true) {
        controller.clearAcceptedNavigationFlag();
        context.go(AppRoutes.currentDelivery);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.homeTitle),
        actions: [
          IconButton(
            key: const Key('home_language'),
            tooltip: AppStrings.languageSettingsTitle,
            onPressed: () => context.push(AppRoutes.languageSettings),
            icon: const Icon(Icons.language),
          ),
          IconButton(
            key: const Key('home_refresh'),
            tooltip: AppStrings.deliveryRefresh,
            onPressed: state.loadStatus == DriverHomeLoadStatus.loading
                ? null
                : () => controller.refresh(full: true),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            key: const Key('home_logout'),
            tooltip: AppStrings.logout,
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refresh(full: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              if (state.loadStatus == DriverHomeLoadStatus.loading &&
                  state.me == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(AppStrings.homeLoading),
                    ],
                  ),
                )
              else ...[
                _AvailabilityCard(state: state, controller: controller),
                if (state.locationMessage != null) ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    key: const Key('location_banner'),
                    message: state.locationMessage!,
                    color: theme.colorScheme.errorContainer,
                    foreground: theme.colorScheme.onErrorContainer,
                    icon: Icons.location_off_outlined,
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    key: const Key('home_error_banner'),
                    message: state.errorMessage!,
                    color: theme.colorScheme.errorContainer,
                    foreground: theme.colorScheme.onErrorContainer,
                    icon: Icons.error_outline,
                  ),
                ],
                if (state.hasActiveDelivery) ...[
                  const SizedBox(height: 16),
                  _InfoBanner(
                    key: const Key('active_delivery_banner'),
                    message: AppStrings.activeDeliveryBanner,
                    color: theme.colorScheme.secondaryContainer,
                    foreground: theme.colorScheme.onSecondaryContainer,
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('open_current_delivery'),
                      onPressed: () => context.go(AppRoutes.currentDelivery),
                      child: Text(AppStrings.openCurrentDelivery),
                    ),
                  ),
                ],
                if (state.isOnline &&
                    !state.hasActiveDelivery &&
                    state.offer == null) ...[
                  const SizedBox(height: 24),
                  _WaitingCard(theme: theme),
                ],
                if (state.offer != null) ...[
                  const SizedBox(height: 24),
                  _OfferCard(
                    offer: state.offer!,
                    state: state,
                    controller: controller,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.state, required this.controller});

  final DriverHomeState state;
  final DriverHomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = state.me?.availability?.status;
    final online = state.isOnline;
    final Color statusColor = switch (status) {
      'ONLINE' => const Color(0xFF0F766E),
      'SUSPENDED' => theme.colorScheme.error,
      'OFFLINE_AFTER_CURRENT_DELIVERY' => theme.colorScheme.tertiary,
      _ => theme.colorScheme.outline,
    };

    return Semantics(
      container: true,
      label:
          '${AppStrings.statusLabel}: ${AppStrings.availabilityStatusLabel(status)}',
      child: Container(
        key: const Key('availability_card'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  online ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: statusColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.availabilityStatusLabel(status),
                    key: const Key('availability_status_text'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (state.me?.profileFullName != null) ...[
              const SizedBox(height: 8),
              Text(
                state.me!.profileFullName!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (state.isBlocked ||
                (state.me != null && !state.me!.operationalReady)) ...[
              const SizedBox(height: 12),
              Text(
                state.me?.driverProfileExists != true
                    ? AppStrings.noDriverProfile
                    : AppStrings.driverNotOperational,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (online || status == 'OFFLINE_AFTER_CURRENT_DELIVERY')
              OutlinedButton(
                key: const Key('go_offline_button'),
                onPressed: state.canToggleOnline
                    ? () => controller.goOffline()
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 56),
                ),
                child: Text(
                  state.availabilityBusy
                      ? AppStrings.goingOffline
                      : AppStrings.goOffline,
                ),
              )
            else
              FilledButton(
                key: const Key('go_online_button'),
                onPressed: state.canToggleOnline
                    ? () => controller.goOnline()
                    : null,
                child: Text(
                  state.availabilityBusy
                      ? AppStrings.goingOnline
                      : AppStrings.goOnline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('waiting_for_offer'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.waitingForOffer,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.waitingForOfferHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.state,
    required this.controller,
  });

  final AssignmentOffer offer;
  final DriverHomeState state;
  final DriverHomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = state.remainingForOffer(DateTime.now().toUtc());
    final expired = state.offerExpiredLocally || remaining == Duration.zero;
    final countdown = formatCountdown(remaining);
    final actionsEnabled =
        !expired && !state.offerActionBusy && offer.assignmentId.isNotEmpty;

    return Semantics(
      container: true,
      label:
          '${AppStrings.offerTitle}. ${AppStrings.offerCountdownLabel} $countdown',
      child: Container(
        key: const Key('offer_card'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expired
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.offerTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _OfferRow(
              label: AppStrings.offerCountdownLabel,
              value: expired ? AppStrings.offerExpired : countdown,
              valueKey: const Key('offer_countdown'),
              emphasize: true,
              error: expired,
            ),
            _OfferRow(
              label: AppStrings.offerOrderRefLabel,
              value: offer.orderPublicReference,
              valueKey: const Key('offer_order_ref'),
              ltr: true,
            ),
            _OfferRow(
              label: AppStrings.offerPickupLabel,
              value: offer.pickupName,
              valueKey: const Key('offer_pickup_name'),
            ),
            _OfferRow(
              label: AppStrings.offerPickupDistanceLabel,
              value: AppStrings.formatDistanceMeters(
                offer.pickupDistanceMeters,
              ),
              valueKey: const Key('offer_pickup_distance'),
              ltr: true,
            ),
            if (offer.deliveryDistanceMeters != null)
              _OfferRow(
                label: AppStrings.offerDeliveryDistanceLabel,
                value: AppStrings.formatDistanceMeters(
                  offer.deliveryDistanceMeters!,
                ),
                valueKey: const Key('offer_delivery_distance'),
                ltr: true,
              ),
            _OfferRow(
              label: AppStrings.offerRemunerationLabel,
              value: AppStrings.formatMinorUnits(offer.driverRemunerationMinor),
              valueKey: const Key('offer_remuneration'),
              ltr: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('offer_reject_button'),
                    onPressed: actionsEnabled
                        ? () => controller.rejectOffer()
                        : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 56),
                    ),
                    child: Text(
                      state.offerActionBusy
                          ? AppStrings.offerRejecting
                          : AppStrings.offerReject,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('offer_accept_button'),
                    onPressed: actionsEnabled
                        ? () => controller.acceptOffer()
                        : null,
                    child: Text(
                      state.offerActionBusy
                          ? AppStrings.offerAccepting
                          : AppStrings.offerAccept,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.label,
    required this.value,
    this.valueKey,
    this.emphasize = false,
    this.error = false,
    this.ltr = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool emphasize;
  final bool error;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = emphasize
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: error ? theme.colorScheme.error : theme.colorScheme.primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          )
        : theme.textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    super.key,
    required this.message,
    required this.color,
    required this.foreground,
    required this.icon,
  });

  final String message;
  final Color color;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
