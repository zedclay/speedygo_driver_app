import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';

/// COD collection form. Drivers enter DZD; the controller converts to integer
/// minor units only at the UI boundary for the existing collect-cod API.
class DeliveryCodCard extends StatefulWidget {
  const DeliveryCodCard({
    super.key,
    required this.amountInput,
    required this.collected,
    required this.busy,
    required this.canSubmit,
    required this.invalidAmount,
    required this.onChanged,
    required this.onSubmit,
    this.expectedAmountLabel,
  });

  final String amountInput;
  final bool collected;
  final bool busy;
  final bool canSubmit;
  final bool invalidAmount;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final String? expectedAmountLabel;

  @override
  State<DeliveryCodCard> createState() => _DeliveryCodCardState();
}

class _DeliveryCodCardState extends State<DeliveryCodCard> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.amountInput,
  );

  @override
  void didUpdateWidget(covariant DeliveryCodCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amountInput != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.amountInput,
        selection: TextSelection.collapsed(offset: widget.amountInput.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expected = widget.expectedAmountLabel;
    return Container(
      key: const Key('cod_card'),
      decoration: BoxDecoration(
        color: DriverTokens.card,
        borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
        border: Border.all(color: DriverTokens.outlineVariant),
        boxShadow: DriverTokens.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DriverTokens.spaceLg,
              vertical: DriverTokens.spaceMd,
            ),
            color: DriverTokens.tertiaryFixed,
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: DriverTokens.onTertiaryFixed,
                ),
                const SizedBox(width: DriverTokens.spaceMd),
                Expanded(
                  child: Text(
                    AppStrings.codTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DriverTokens.onTertiaryFixed,
                    ),
                  ),
                ),
                if (widget.collected)
                  StatusBadge(
                    label: AppStrings.codCollectedBadge,
                    tone: StatusTone.success,
                    icon: Icons.check,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DriverTokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.codIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DriverTokens.textSecondary,
                  ),
                ),
                if (expected != null && expected.isNotEmpty) ...[
                  const SizedBox(height: DriverTokens.spaceMd),
                  Text(
                    expected,
                    key: const Key('cod_expected_amount'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DriverTokens.primary,
                    ),
                  ),
                ],
                const SizedBox(height: DriverTokens.spaceMd),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    key: const Key('cod_amount_field'),
                    controller: _controller,
                    enabled: !widget.busy && !widget.collected,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.,٠-٩۰-۹\s]'),
                      ),
                    ],
                    onChanged: widget.onChanged,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DriverTokens.primary,
                    ),
                    decoration: InputDecoration(
                      labelText: AppStrings.codAmountLabel,
                      helperText: AppStrings.codAmountHelp,
                      helperMaxLines: 3,
                      errorText: widget.invalidAmount
                          ? AppStrings.codAmountInvalid
                          : null,
                      errorMaxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(height: DriverTokens.spaceMd),
                SizedBox(
                  height: DriverTokens.actionHeight,
                  child: OutlinedButton.icon(
                    key: const Key('cod_collect_button'),
                    onPressed: widget.canSubmit && !widget.collected
                        ? widget.onSubmit
                        : null,
                    icon: const Icon(Icons.payments_outlined),
                    label: widget.busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppStrings.codCollect),
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
