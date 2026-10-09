import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';

/// COD collection form. The delivery DTO exposes no expected amount, so the
/// driver types the exact collected amount (integer minor units) and the
/// server validates it. Nothing is computed or pre-filled client-side.
class DeliveryCodCard extends StatefulWidget {
  const DeliveryCodCard({
    super.key,
    required this.amountInput,
    required this.collected,
    required this.busy,
    required this.canSubmit,
    required this.onChanged,
    required this.onSubmit,
  });

  final String amountInput;
  final bool collected;
  final bool busy;
  final bool canSubmit;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

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
    return OperationalCard(
      key: const Key('cod_card'),
      title: AppStrings.codTitle,
      leading: const Icon(Icons.payments_outlined, color: DriverTokens.primary),
      trailing: widget.collected
          ? StatusBadge(
              label: AppStrings.codCollectedBadge,
              tone: StatusTone.success,
              icon: Icons.check,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.codIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: DriverTokens.spaceMd),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: const Key('cod_amount_field'),
              controller: _controller,
              enabled: !widget.busy && !widget.collected,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                labelText: AppStrings.codAmountLabel,
                helperText: AppStrings.codAmountHelp,
                helperMaxLines: 3,
              ),
            ),
          ),
          const SizedBox(height: DriverTokens.spaceMd),
          SizedBox(
            height: DriverTokens.touchTarget,
            child: OutlinedButton(
              key: const Key('cod_collect_button'),
              onPressed: widget.canSubmit && !widget.collected
                  ? widget.onSubmit
                  : null,
              child: widget.busy
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
    );
  }
}
