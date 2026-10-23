import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/amount_display.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/empty_state_view.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/date_format.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';
import 'package:speedygo_driver_app/features/history/data/history_models.dart';

/// Completed deliveries (shell branch 1). Body only — the shell owns the bar.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            Text(
              AppStrings.historyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: DriverTokens.textPrimary,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceXs),
            Text(
              AppStrings.historyEmptyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceLg),
            if (state.status == PagedStatus.loading && state.items.isEmpty)
              LoadingView(message: AppStrings.loading),
            if (state.status == PagedStatus.error && state.items.isEmpty)
              ErrorRetryView(
                message: state.errorMessage ?? AppStrings.unexpectedError,
                onRetry: controller.load,
                retryKey: const Key('history_retry'),
              ),
            if (state.isEmpty)
              EmptyStateView(
                title: AppStrings.historyEmpty,
                message: AppStrings.historyEmptyHint,
                icon: Icons.history,
              ),
            for (final item in state.items) ...[
              _HistoryRow(
                item: item,
                onTap: () =>
                    context.push(AppRoutes.historyDetailFor(item.deliveryId)),
              ),
              const SizedBox(height: DriverTokens.spaceMd),
            ],
            if (state.hasMore)
              Center(
                child: TextButton(
                  key: const Key('history_load_more'),
                  onPressed: state.loadingMore ? null : controller.loadMore,
                  child: Text(AppStrings.loadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.onTap});

  final HistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
        boxShadow: DriverTokens.cardShadow,
      ),
      child: Material(
        key: Key('history_item_${item.deliveryId}'),
        color: DriverTokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
          side: const BorderSide(color: DriverTokens.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DriverTokens.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(DriverTokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '${AppStrings.historyRefLabel}: ${item.orderPublicReference}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: DriverTokens.outline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.merchantName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: DriverTokens.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.branchName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: DriverTokens.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DriverTokens.spaceMd),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AmountDisplay(
                            amountMinor: item.earningAmountMinor,
                            large: true,
                          ),
                          const SizedBox(height: 6),
                          StatusBadge(
                            label: AppStrings.deliveryStatusLabel(
                              item.deliveryStatus,
                            ),
                            tone: StatusTone.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: DriverTokens.spaceMd,
                    ),
                    child: Divider(
                      height: 1,
                      color: DriverTokens.outlineVariant,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: DriverTokens.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${formatIsoDateTime(item.deliveredAt)} · '
                          '${AppStrings.paymentMethodLabel(item.paymentMethod)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DriverTokens.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: DriverTokens.outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
