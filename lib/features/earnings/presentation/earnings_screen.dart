import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/amount_display.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/date_format.dart';
import 'package:speedygo_driver_app/features/earnings/application/earnings_controller.dart';

/// Earnings (recognized) and COD custody are deliberately separate sections.
class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earningsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(earningsControllerProvider);
    final controller = ref.read(earningsControllerProvider.notifier);
    final theme = Theme.of(context);
    final summary = state.summary;
    final cod = state.cod;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            Text(
              AppStrings.earningsTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceMd),
            if (state.status == EarningsLoadStatus.loading && summary == null)
              LoadingView(message: AppStrings.loading),
            if (state.status == EarningsLoadStatus.error && summary == null)
              ErrorRetryView(
                message: state.errorMessage ?? AppStrings.unexpectedError,
                onRetry: controller.load,
                retryKey: const Key('earnings_retry'),
              ),
            if (summary != null) ...[
              OperationalCard(
                key: const Key('earnings_summary_card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AmountDisplay(
                      label: AppStrings.earningsTotal,
                      amountMinor: summary.totalEarnedMinor,
                      large: true,
                      valueKey: const Key('earnings_total'),
                    ),
                    const SizedBox(height: DriverTokens.spaceMd),
                    Row(
                      children: [
                        Expanded(
                          child: AmountDisplay(
                            label: AppStrings.earningsUnpaid,
                            amountMinor: summary.unpaidEarnedMinor,
                            valueKey: const Key('earnings_unpaid'),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.earningsCount,
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                '${summary.earningCount}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DriverTokens.spaceMd),
                    Text(
                      AppStrings.earningsNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DriverTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DriverTokens.spaceLg),
              if (state.successMessage != null) ...[
                InfoBanner(
                  message: state.successMessage!,
                  tone: StatusTone.success,
                ),
                const SizedBox(height: DriverTokens.spaceMd),
              ],
              if (state.errorMessage != null) ...[
                InfoBanner(
                  message: state.errorMessage!,
                  tone: StatusTone.danger,
                ),
                const SizedBox(height: DriverTokens.spaceMd),
              ],
              if (cod != null)
                _CodSection(state: state, controller: controller),
              const SizedBox(height: DriverTokens.spaceLg),
              Text(
                AppStrings.earningsListTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              if (state.items.isEmpty) Text(AppStrings.earningsEmpty),
              for (final item in state.items) ...[
                OperationalCard(
                  key: Key('earning_${item.earningId}'),
                  child: Row(
                    children: [
                      Expanded(child: Text(formatIsoDateTime(item.earnedAt))),
                      AmountDisplay(amountMinor: item.amountMinor),
                    ],
                  ),
                ),
                const SizedBox(height: DriverTokens.spaceSm),
              ],
              if (state.hasMore)
                Center(
                  child: TextButton(
                    key: const Key('earnings_load_more'),
                    onPressed: state.loadingMore ? null : controller.loadMore,
                    child: Text(AppStrings.loadMore),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CodSection extends StatefulWidget {
  const _CodSection({required this.state, required this.controller});

  final EarningsState state;
  final EarningsController controller;

  @override
  State<_CodSection> createState() => _CodSectionState();
}

class _CodSectionState extends State<_CodSection> {
  final _remit = TextEditingController();

  EarningsState get state => widget.state;
  EarningsController get controller => widget.controller;

  @override
  void didUpdateWidget(covariant _CodSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (state.remitInput != _remit.text) {
      _remit.text = state.remitInput;
    }
  }

  @override
  void dispose() {
    _remit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cod = state.cod!;
    return OperationalCard(
      key: const Key('cod_summary_card'),
      title: AppStrings.codSectionTitle,
      leading: const Icon(Icons.savings_outlined, color: DriverTokens.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountDisplay(
            label: AppStrings.codOutstanding,
            amountMinor: cod.outstandingCustodyMinor,
            large: true,
            valueKey: const Key('cod_outstanding'),
          ),
          const SizedBox(height: DriverTokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: AmountDisplay(
                  label: AppStrings.codCollectedTotal,
                  amountMinor: cod.collectedAmountMinor,
                ),
              ),
              Expanded(
                child: AmountDisplay(
                  label: AppStrings.codConfirmedAllocated,
                  amountMinor: cod.confirmedAllocatedMinor,
                ),
              ),
            ],
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          Text('${AppStrings.codOpenDeclared}: ${cod.openDeclaredCount}'),
          if (cod.canDeclareRemittance) ...[
            const Divider(height: DriverTokens.spaceXl),
            Text(
              AppStrings.codRemitTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: DriverTokens.spaceSm),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                key: const Key('remit_amount_field'),
                controller: _remit,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !state.remitBusy,
                onChanged: controller.updateRemitInput,
                decoration: InputDecoration(
                  labelText: AppStrings.codRemitAmountLabel,
                  helperText: AppStrings.codRemitHelp,
                  helperMaxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: DriverTokens.spaceMd),
            SizedBox(
              height: DriverTokens.touchTarget,
              child: OutlinedButton(
                key: const Key('remit_submit_button'),
                onPressed: state.canSubmitRemittance
                    ? controller.submitRemittance
                    : null,
                child: Text(AppStrings.codRemitSubmit),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
