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
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/date_format.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';

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
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            Text(
              AppStrings.historyTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceMd),
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
              OperationalCard(
                key: Key('history_item_${item.deliveryId}'),
                title: item.merchantName,
                trailing: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(item.orderPublicReference),
                ),
                onTap: () =>
                    context.push(AppRoutes.historyDetailFor(item.deliveryId)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatIsoDateTime(item.deliveredAt),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    AmountDisplay(amountMinor: item.earningAmountMinor),
                  ],
                ),
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
