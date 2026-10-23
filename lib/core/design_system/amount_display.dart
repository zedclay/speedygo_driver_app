import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Displays an authoritative amount received as integer minor units (string
/// from the API). Never computes money — formatting only.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amountMinor,
    this.label,
    this.large = false,
    this.color,
    this.valueKey,
  });

  final String amountMinor;
  final String? label;
  final bool large;
  final Color? color;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        (large ? theme.textTheme.headlineMedium : theme.textTheme.titleMedium)
            ?.copyWith(
              fontWeight: FontWeight.w700,
              color: color ?? DriverTokens.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: DriverTokens.textSecondary,
            ),
          ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            AppStrings.formatMinorUnits(amountMinor),
            key: valueKey,
            style: style,
          ),
        ),
      ],
    );
  }
}
