import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(driverHomeControllerProvider);
    final controller = ref.read(driverHomeControllerProvider.notifier);

    ref.listen<DriverHomeState>(driverHomeControllerProvider, (prev, next) {
      if (next.acceptedNavigationPending &&
          prev?.acceptedNavigationPending != true) {
        controller.clearAcceptedNavigationFlag();
        ref.read(driverNavSnapshotProvider.notifier).markActiveDelivery(true);
        context.go(AppRoutes.currentDelivery);
      }
    });

    final offer = state.offer;
    final actionsEnabled =
        offer != null &&
        !state.offerActionBusy &&
        !state.offerExpiredLocally &&
        state.remainingForOffer(DateTime.now().toUtc()) > Duration.zero;

    // Body only — shell owns AppBar / logout. Refresh via pull-to-refresh.
    // Visual tokens from Stitch; availability/offer contracts unchanged.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refresh(full: true),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              DriverTokens.edgeMargin,
              DriverTokens.spaceLg,
              DriverTokens.edgeMargin,
              offer != null ? 120 : DriverTokens.spaceXl,
            ),
            children: [
              if (state.loadStatus == DriverHomeLoadStatus.loading &&
                  state.me == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: DriverTokens.spaceLg),
                      Text(AppStrings.homeLoading),
                    ],
                  ),
                )
              else ...[
                _AvailabilityCard(state: state, controller: controller),
                if (state.locationMessage != null) ...[
                  const SizedBox(height: DriverTokens.spaceMd),
                  InfoBanner(
                    key: const Key('location_banner'),
                    message: state.locationMessage!,
                    tone: StatusTone.danger,
                    icon: Icons.location_off_outlined,
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: DriverTokens.spaceMd),
                  InfoBanner(
                    key: const Key('home_error_banner'),
                    message: state.errorMessage!,
                    tone: StatusTone.danger,
                    icon: Icons.error_outline,
                  ),
                ],
                if (state.hasActiveDelivery) ...[
                  const SizedBox(height: DriverTokens.spaceLg),
                  InfoBanner(
                    key: const Key('active_delivery_banner'),
                    message: AppStrings.activeDeliveryBanner,
                    tone: StatusTone.info,
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: DriverTokens.spaceMd),
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
                  const SizedBox(height: DriverTokens.spaceXl),
                  const _WaitingCard(),
                ],
                if (offer != null) ...[
                  const SizedBox(height: DriverTokens.spaceXl),
                  _OfferCard(
                    offer: offer,
                    state: state,
                    controller: controller,
                    showActions: false,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: offer == null
          ? null
          : Material(
              elevation: 6,
              color: DriverTokens.card,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DriverTokens.edgeMargin,
                    DriverTokens.spaceMd,
                    DriverTokens.edgeMargin,
                    DriverTokens.spaceMd,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('offer_reject_button'),
                          onPressed: actionsEnabled
                              ? () => controller.rejectOffer()
                              : null,
                          child: Text(
                            state.offerActionBusy
                                ? AppStrings.offerRejecting
                                : AppStrings.offerReject,
                          ),
                        ),
                      ),
                      const SizedBox(width: DriverTokens.spaceMd),
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
      'ONLINE' => DriverTokens.success,
      'SUSPENDED' => DriverTokens.danger,
      'OFFLINE_AFTER_CURRENT_DELIVERY' => DriverTokens.warning,
      _ => DriverTokens.textSecondary,
    };

    return Semantics(
      container: true,
      label:
          '${AppStrings.statusLabel}: ${AppStrings.availabilityStatusLabel(status)}',
      child: OperationalCard(
        key: const Key('availability_card'),
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
                const SizedBox(width: DriverTokens.spaceMd),
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
              const SizedBox(height: DriverTokens.spaceSm),
              Text(
                state.me!.profileFullName!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (state.isBlocked ||
                (state.me != null && !state.me!.operationalReady)) ...[
              const SizedBox(height: DriverTokens.spaceMd),
              Text(
                state.me?.driverProfileExists != true
                    ? AppStrings.noDriverProfile
                    : AppStrings.driverNotOperational,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DriverTokens.danger,
                ),
              ),
            ],
            const SizedBox(height: DriverTokens.spaceLg),
            if (online || status == 'OFFLINE_AFTER_CURRENT_DELIVERY')
              OutlinedButton(
                key: const Key('go_offline_button'),
                onPressed: state.canToggleOnline
                    ? () => controller.goOffline()
                    : null,
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
  const _WaitingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OperationalCard(
      key: const Key('waiting_for_offer'),
      borderColor: DriverTokens.primaryContainer,
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: DriverTokens.spaceLg),
          Text(
            AppStrings.waitingForOffer,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            AppStrings.waitingForOfferHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DriverTokens.textSecondary,
            ),
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
    this.showActions = true,
  });

  final AssignmentOffer offer;
  final DriverHomeState state;
  final DriverHomeController controller;
  final bool showActions;

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
            if (showActions) ...[
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
