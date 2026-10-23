import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/offer_countdown.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';
import 'package:speedygo_driver_app/features/availability/presentation/availability_slide_control.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';

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
      ref.read(earningsControllerProvider.notifier).load();
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
    final earnings = ref.watch(earningsControllerProvider);

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

    final name = state.me?.profileFullName ?? '';
    final now = DateTime.now();
    // Avoid intl locale-data init requirement in widget tests; keep LTR digits.
    final dateLine =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} · '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    final goOffline = state.isOnline ||
        state.me?.availability?.status == 'OFFLINE_AFTER_CURRENT_DELIVERY';
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      // 03 focused: Back header while shell hides AppBar + tabs.
      appBar: offer != null
          ? DriverNestedAppBar(
              key: const Key('offer_focused_app_bar'),
              title: AppStrings.offerTitle,
              leading: IconButton(
                key: const Key('offer_back_button'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Soft leave focused chrome without accept/reject; offer
                  // remains until Accept, Reject, or expiresAt.
                  if (context.canPop()) {
                    context.pop();
                  }
                },
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.refresh(full: true);
                await ref.read(earningsControllerProvider.notifier).load();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  DriverTokens.edgeMargin,
                  DriverTokens.spaceMd,
                  DriverTokens.edgeMargin,
                  DriverTokens.spaceLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    else if (offer != null) ...[
                      // Focused offer surface (ref 03) — no greeting/status chrome.
                      if (state.errorMessage != null) ...[
                        GestureDetector(
                          onTap: () => controller.refresh(full: true),
                          child: InfoBanner(
                            key: const Key('home_error_banner'),
                            message: state.errorMessage!,
                            tone: StatusTone.danger,
                            icon: Icons.error_outline,
                          ),
                        ),
                        const SizedBox(height: DriverTokens.spaceMd),
                      ],
                      _OfferCard(
                        offer: offer,
                        state: state,
                        controller: controller,
                        showActions: false,
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.homeGreeting(name),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 26,
                                        color: DriverTokens.navy,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateLine,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: DriverTokens.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: DriverTokens.primaryContainer,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: DriverTokens.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DriverTokens.spaceXl),
                      _AvailabilityStatusCard(
                        state: state,
                        controller: controller,
                      ),
                      if (state.locationMessage != null) ...[
                        const SizedBox(height: DriverTokens.spaceMd),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InfoBanner(
                              key: const Key('location_banner'),
                              message: state.locationMessage!,
                              tone: StatusTone.danger,
                              icon: Icons.location_off_outlined,
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key: const Key('location_recovery_button'),
                                onPressed: () => controller.recoverLocation(),
                                child: Text(
                                  controller.locationRecoveryActionLabel(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: DriverTokens.spaceMd),
                        GestureDetector(
                          onTap: () => controller.refresh(full: true),
                          child: InfoBanner(
                            key: const Key('home_error_banner'),
                            message: state.errorMessage!,
                            tone: StatusTone.danger,
                            icon: Icons.error_outline,
                          ),
                        ),
                      ],
                      if (state.hasActiveDelivery) ...[
                        const SizedBox(height: DriverTokens.spaceXl),
                        Text(
                          AppStrings.homeActiveTaskSection,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: DriverTokens.navy,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: DriverTokens.spaceMd),
                        _ActiveTaskCard(
                          onResume: () =>
                              context.go(AppRoutes.currentDelivery),
                        ),
                      ],
                      if (state.isOnline && !state.hasActiveDelivery) ...[
                        const SizedBox.shrink(key: Key('waiting_for_offer')),
                      ],
                      // Home activity / links only when no live offer (03 is focused).
                      ...[
                        const SizedBox(height: DriverTokens.spaceXl),
                        Text(
                          AppStrings.yourActivityLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: DriverTokens.navy,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.accountTotalsNote,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: DriverTokens.onSurfaceVariant),
                        ),
                        const SizedBox(height: DriverTokens.spaceMd),
                        _TotalsRow(earnings: earnings),
                        const SizedBox(height: DriverTokens.spaceLg),
                        _QuickLinksCard(
                          onHistory: () => context.go(AppRoutes.history),
                          onDocuments: () => context.push(AppRoutes.documents),
                        ),
                        const SizedBox(height: DriverTokens.spaceMd),
                        _SupportCard(
                          onTap: () => context.push(AppRoutes.support),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Slider above shell nav; hidden while an offer demands Accept/Reject.
          if (state.me != null && offer == null)
            Material(
              color: DriverTokens.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DriverTokens.edgeMargin,
                  DriverTokens.spaceSm,
                  DriverTokens.edgeMargin,
                  DriverTokens.spaceMd,
                ),
                child: AvailabilitySlideControl(
                  key: Key(
                    goOffline ? 'go_offline_button' : 'go_online_button',
                  ),
                  onlineMode: goOffline,
                  label: goOffline
                      ? AppStrings.slideToGoOffline
                      : AppStrings.slideToGoOnline,
                  pendingLabel: goOffline
                      ? AppStrings.goingOffline
                      : AppStrings.goingOnline,
                  semanticActionLabel: goOffline
                      ? AppStrings.goOffline
                      : AppStrings.goOnline,
                  enabled: state.canToggleOnline,
                  busy: state.availabilityBusy,
                  onConfirmed: () {
                    if (goOffline) {
                      controller.goOffline();
                    } else {
                      controller.goOnline();
                    }
                  },
                ),
              ),
            ),
          if (offer != null)
            Material(
              elevation: 4,
              color: DriverTokens.card,
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
                      flex: 2,
                      child: FilledButton.icon(
                        key: const Key('offer_accept_button'),
                        onPressed: actionsEnabled
                            ? () => controller.acceptOffer()
                            : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          state.offerActionBusy
                              ? AppStrings.offerAccepting
                              : AppStrings.offerAcceptCta,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvailabilityStatusCard extends StatelessWidget {
  const _AvailabilityStatusCard({
    required this.state,
    required this.controller,
  });

  final DriverHomeState state;
  final DriverHomeController controller;

  @override
  Widget build(BuildContext context) {
    final online = state.isOnline;
    final status = state.me?.availability?.status;
    final theme = Theme.of(context);
    final locationReady = state.locationStatus == LocationUiStatus.ready;
    final showSearching =
        online && !state.hasActiveDelivery && locationReady;
    final subtitle = !online
        ? AppStrings.goOnlineHint
        : state.hasActiveDelivery
        ? AppStrings.activeDeliveryBanner
        : showSearching
        ? AppStrings.waitingForOffer
        : AppStrings.waitingForOfferHint;

    return Semantics(
      container: true,
      label:
          '${AppStrings.statusLabel}: ${AppStrings.availabilityStatusLabel(status)}',
      child: Container(
        key: const Key('availability_card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.yourStatusLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: DriverTokens.onSurfaceVariant,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceSm),
            Row(
              children: [
                Container(
                  key: const Key('availability_status_dot'),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: online
                        ? DriverTokens.success
                        : DriverTokens.outline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DriverTokens.spaceSm),
                Expanded(
                  child: Text(
                    AppStrings.availabilityStatusLabel(status),
                    key: const Key('availability_status_text'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DriverTokens.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DriverTokens.spaceXs),
            Text(
              subtitle,
              key: const Key('availability_subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DriverTokens.onSurfaceVariant,
              ),
            ),
            if (showSearching) ...[
              const SizedBox(height: 2),
              Text(
                AppStrings.searchingDeliveries,
                key: const Key('availability_searching'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: DriverTokens.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: DriverTokens.spaceMd),
            Row(
              children: [
                Icon(
                  state.locationStatus == LocationUiStatus.ready
                      ? Icons.location_on
                      : Icons.location_off_outlined,
                  size: 18,
                  color: state.locationStatus == LocationUiStatus.ready
                      ? DriverTokens.primary
                      : DriverTokens.danger,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppStrings.locationStatusLine(state.locationStatus.name),
                    key: const Key('home_location_status_line'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DriverTokens.navy,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('home_location_check_button'),
                  onPressed: () => controller.recoverLocation(),
                  child: Text(
                    state.locationStatus == LocationUiStatus.ready
                        ? AppStrings.zoneCheckCta
                        : controller.locationRecoveryActionLabel(),
                  ),
                ),
              ],
            ),
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
          ],
        ),
      ),
    );
  }
}

class _QuickLinksCard extends StatelessWidget {
  const _QuickLinksCard({
    required this.onHistory,
    required this.onDocuments,
  });

  final VoidCallback onHistory;
  final VoidCallback onDocuments;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DriverTokens.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
        side: const BorderSide(color: DriverTokens.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history, color: DriverTokens.navy),
            title: Text(
              AppStrings.navHistory,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: DriverTokens.navy,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: DriverTokens.outline,
            ),
            onTap: onHistory,
          ),
          const Divider(height: 1, color: DriverTokens.outlineVariant),
          ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: DriverTokens.navy,
            ),
            title: Text(
              AppStrings.navDocuments,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: DriverTokens.navy,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: DriverTokens.outline,
            ),
            onTap: onDocuments,
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(DriverTokens.spaceLg),
      decoration: BoxDecoration(
        color: DriverTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
        border: Border.all(color: DriverTokens.primary.withValues(alpha: 0.2)),
        boxShadow: DriverTokens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DriverTokens.primaryContainer.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent, color: DriverTokens.primary),
          ),
          const SizedBox(width: DriverTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.homeSupportTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.homeSupportBody,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DriverTokens.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: DriverTokens.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, DriverTokens.touchTarget),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppStrings.homeSupportCta,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTaskCard extends StatelessWidget {
  const _ActiveTaskCard({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('active_delivery_banner'),
      decoration: BoxDecoration(
        color: DriverTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
        border: Border.all(color: DriverTokens.primary.withValues(alpha: 0.2)),
        boxShadow: DriverTokens.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: DriverTokens.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(DriverTokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.activeDeliveryBanner,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: DriverTokens.spaceMd),
                    FilledButton.icon(
                      key: const Key('open_current_delivery'),
                      onPressed: onResume,
                      icon: const Icon(Icons.navigation),
                      label: Text(AppStrings.homeResumeDelivery),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.earnings});

  final EarningsState earnings;

  @override
  Widget build(BuildContext context) {
    final summary = earnings.summary;
    final cod = earnings.cod;
    final gains = summary == null
        ? AppStrings.homeMetricUnavailable
        : AppStrings.formatMinorUnits(summary.totalEarnedMinor);
    final collections = cod == null
        ? AppStrings.homeMetricUnavailable
        : AppStrings.formatMinorUnits(cod.collectedAmountMinor);
    final rides = summary == null
        ? AppStrings.homeMetricUnavailable
        : '${summary.earningCount}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.payments_outlined,
              label: AppStrings.navEarnings,
              value: gains,
              emphasize: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              icon: Icons.account_balance_wallet_outlined,
              label: AppStrings.homeCollectionsLabel,
              value: collections,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              icon: Icons.check_circle_outline,
              label: AppStrings.homeCompletedRidesLabel,
              value: rides,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DriverTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
        border: Border.all(color: DriverTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: DriverTokens.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DriverTokens.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: emphasize ? DriverTokens.primary : DriverTokens.onSurface,
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
    final pickupDist = AppStrings.formatDistanceMeters(
      offer.pickupDistanceMeters,
    );
    final deliveryDist = offer.deliveryDistanceMeters == null
        ? null
        : AppStrings.formatDistanceMeters(offer.deliveryDistanceMeters!);
    final totalMeters = offer.deliveryDistanceMeters == null
        ? offer.pickupDistanceMeters
        : offer.pickupDistanceMeters + offer.deliveryDistanceMeters!;

    return Semantics(
      container: true,
      label:
          '${AppStrings.offerTitle}. ${AppStrings.offerCountdownLabel} $countdown',
      child: Column(
        key: const Key('offer_card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.offerTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: DriverTokens.navy,
            ),
          ),
          const SizedBox(height: DriverTokens.spaceMd),
          Container(
            padding: const EdgeInsets.all(DriverTokens.spaceLg),
            decoration: BoxDecoration(
              color: DriverTokens.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
              border: Border.all(
                color: expired
                    ? DriverTokens.danger
                    : DriverTokens.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: DriverTokens.surface,
                  child: Icon(
                    Icons.timer_outlined,
                    color: expired ? DriverTokens.danger : DriverTokens.primary,
                  ),
                ),
                const SizedBox(width: DriverTokens.spaceMd),
                Expanded(
                  child: Text(
                    AppStrings.offerCountdownLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DriverTokens.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    expired ? AppStrings.offerExpired : countdown,
                    key: const Key('offer_countdown'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: expired
                          ? DriverTokens.danger
                          : DriverTokens.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DriverTokens.spaceLg),
          Text(
            AppStrings.offerItineraryTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: DriverTokens.navy,
            ),
          ),
          const SizedBox(height: DriverTokens.spaceMd),
          _OfferStop(
            icon: Icons.radio_button_unchecked,
            title: offer.pickupName,
            titleKey: const Key('offer_pickup_name'),
            subtitle: AppStrings.offerPickupLabel,
            meta: pickupDist,
            metaKey: const Key('offer_pickup_distance'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 19),
            child: Container(
              width: 2,
              height: 20,
              color: DriverTokens.outlineVariant,
            ),
          ),
          _OfferStop(
            icon: Icons.location_on,
            title: AppStrings.offerPrivacyDelivery,
            subtitle: AppStrings.offerDeliveryDistanceLabel,
            meta: deliveryDist,
            metaKey: deliveryDist == null
                ? null
                : const Key('offer_delivery_distance'),
            privacy: true,
          ),
          const SizedBox(height: DriverTokens.spaceMd),
          _OfferRow(
            label: AppStrings.offerOrderRefLabel,
            value: offer.orderPublicReference,
            valueKey: const Key('offer_order_ref'),
            forceLtr: true,
          ),
          _OfferRow(
            label: AppStrings.offerRemunerationLabel,
            value: AppStrings.formatMinorUnits(offer.driverRemunerationMinor),
            valueKey: const Key('offer_remuneration'),
            forceLtr: true,
            emphasize: true,
          ),
          Text(
            '${AppStrings.offerPickupDistanceLabel} + '
            '${AppStrings.offerDeliveryDistanceLabel}: '
            '${AppStrings.formatDistanceMeters(totalMeters)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: DriverTokens.onSurfaceVariant,
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: DriverTokens.spaceXl),
            Row(
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
                  flex: 2,
                  child: FilledButton(
                    key: const Key('offer_accept_button'),
                    onPressed: actionsEnabled
                        ? () => controller.acceptOffer()
                        : null,
                    child: Text(
                      state.offerActionBusy
                          ? AppStrings.offerAccepting
                          : AppStrings.offerAcceptCta,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferStop extends StatelessWidget {
  const _OfferStop({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.meta,
    this.titleKey,
    this.metaKey,
    this.privacy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? meta;
  final Key? titleKey;
  final Key? metaKey;
  final bool privacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DriverTokens.primary, size: 22),
        const SizedBox(width: DriverTokens.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: titleKey,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DriverTokens.navy,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (privacy) ...[
                    const Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: DriverTokens.outline,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DriverTokens.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (meta != null) ...[
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    meta!,
                    key: metaKey,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: DriverTokens.primary,
                      fontWeight: FontWeight.w600,
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

class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.label,
    required this.value,
    this.valueKey,
    this.emphasize = false,
    this.forceLtr = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool emphasize;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = emphasize
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: DriverTokens.primary,
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
              textDirection: forceLtr ? TextDirection.ltr : null,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
