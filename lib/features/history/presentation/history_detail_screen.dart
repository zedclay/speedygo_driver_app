import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/amount_display.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
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
      backgroundColor: DriverTokens.surface,
      appBar: DriverNestedAppBar(title: AppStrings.historyDetailTitle),
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

    BoxDecoration cardDecoration() => BoxDecoration(
      color: DriverTokens.card,
      borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
      border: Border.all(color: DriverTokens.outlineVariant),
      boxShadow: DriverTokens.cardShadow,
    );

    Widget detailRow(String label, String value, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.only(bottom: DriverTokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    // Timeline: only timestamps the API actually returned.
    final steps = <(String, String?, bool)>[
      (AppStrings.historyPickedUpAt, item.pickedUpAt, false),
      (AppStrings.historyArrivedAt, item.arrivedCustomerAt, false),
      (AppStrings.historyDeliveredAt, item.deliveredAt, true),
    ];

    return ListView(
      padding: const EdgeInsets.all(DriverTokens.edgeMargin),
      children: [
        Container(
          key: const Key('history_detail_header'),
          padding: const EdgeInsets.all(DriverTokens.spaceLg),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusBadge(
                label: AppStrings.deliveryStatusLabel(item.deliveryStatus),
                tone: StatusTone.success,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: DriverTokens.spaceMd),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${AppStrings.orderIdLabel} ${item.orderPublicReference}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: DriverTokens.spaceXs),
              Text(
                item.merchantName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: DriverTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DriverTokens.spaceLg),
        Container(
          padding: const EdgeInsets.all(DriverTokens.spaceLg),
          decoration: cardDecoration(),
          child: Column(
            children: [
              Text(
                AppStrings.historyEarning.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: DriverTokens.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              AmountDisplay(
                amountMinor: item.earningAmountMinor,
                large: true,
                valueKey: const Key('history_detail_earning'),
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              StatusBadge(
                label: AppStrings.paymentMethodLabel(item.paymentMethod),
                tone: StatusTone.success,
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: DriverTokens.spaceMd),
              InfoBanner(message: AppStrings.historyEarningNote),
            ],
          ),
        ),
        const SizedBox(height: DriverTokens.spaceLg),
        Container(
          key: const Key('history_detail_timeline'),
          padding: const EdgeInsets.all(DriverTokens.spaceLg),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.historyTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DriverTokens.spaceMd),
              for (var i = 0; i < steps.length; i++)
                _TimelineRow(
                  label: steps[i].$1,
                  value: formatIsoDateTime(steps[i].$2),
                  highlighted: steps[i].$3,
                  last: i == steps.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: DriverTokens.spaceLg),
        Container(
          padding: const EdgeInsets.all(DriverTokens.spaceLg),
          decoration: cardDecoration(),
          child: Column(
            children: [
              detailRow(
                AppStrings.offerOrderRefLabel,
                item.orderPublicReference,
                ltr: true,
              ),
              detailRow(AppStrings.historyBranch, item.branchName),
              detailRow(
                AppStrings.historyPaymentMethod,
                AppStrings.paymentMethodLabel(item.paymentMethod),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.value,
    required this.highlighted,
    required this.last,
  });

  final String label;
  final String value;
  final bool highlighted;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlighted ? DriverTokens.primary : DriverTokens.textPrimary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlighted
                        ? DriverTokens.primary
                        : DriverTokens.outlineVariant,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: DriverTokens.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DriverTokens.spaceMd),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : DriverTokens.spaceMd),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: highlighted
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
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
