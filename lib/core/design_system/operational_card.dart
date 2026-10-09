import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Standard white card with outline, used for every operational block.
class OperationalCard extends StatelessWidget {
  const OperationalCard({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.child,
    this.padding = const EdgeInsets.all(DriverTokens.spaceLg),
    this.borderColor,
  });

  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(DriverTokens.radiusLg);
    final header = (title != null || leading != null || trailing != null)
        ? Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: DriverTokens.spaceMd),
              ],
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const Spacer(),
              ?trailing,
            ],
          )
        : null;

    return Material(
      color: DriverTokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? DriverTokens.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ?header,
              if (header != null && child != null)
                const SizedBox(height: DriverTokens.spaceMd),
              ?child,
            ],
          ),
        ),
      ),
    );
  }
}
