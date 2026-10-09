import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/amount_display.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/date_format.dart';
import 'package:speedygo_driver_app/features/history/application/history_controller.dart';
import 'package:speedygo_driver_app/features/history/data/history_models.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    final detail = ref.watch(historyDetailProvider(deliveryId));
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.historyDetailTitle)),
      body: detail.when(
        loading: () => LoadingView(message: AppStrings.loading),
        error: (error, _) => ErrorRetryView(
          message: error is AppException
              ? error.message
              : AppStrings.unexpectedError,
          onRetry: () => ref.invalidate(historyDetailProvider(deliveryId)),
        ),
        data: (item) => _Body(item: item),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String label, String value, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.only(bottom: DriverTokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(DriverTokens.edgeMargin),
      children: [
        OperationalCard(
          title: item.merchantName,
          trailing: StatusBadge(
            label: AppStrings.deliveryStatusLabel(item.deliveryStatus),
            tone: StatusTone.success,
          ),
          child: Column(
            children: [
              row(
                AppStrings.offerOrderRefLabel,
                item.orderPublicReference,
                ltr: true,
              ),
              row(AppStrings.historyBranch, item.branchName),
              row(
                AppStrings.historyPaymentMethod,
                AppStrings.paymentMethodLabel(item.paymentMethod),
              ),
              row(
                AppStrings.historyPickedUpAt,
                formatIsoDateTime(item.pickedUpAt),
                ltr: true,
              ),
              row(
                AppStrings.historyArrivedAt,
                formatIsoDateTime(item.arrivedCustomerAt),
                ltr: true,
              ),
              row(
                AppStrings.historyDeliveredAt,
                formatIsoDateTime(item.deliveredAt),
                ltr: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: DriverTokens.spaceMd),
        OperationalCard(
          title: AppStrings.historyEarning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountDisplay(
                amountMinor: item.earningAmountMinor,
                large: true,
                valueKey: const Key('history_detail_earning'),
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              InfoBanner(message: AppStrings.historyEarningNote),
            ],
          ),
        ),
      ],
    );
  }
}
