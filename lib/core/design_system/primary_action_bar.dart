import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Sticky bottom action area. Safe-area aware and keeps the primary action
/// at 56 dp height. Use as `Scaffold.bottomNavigationBar`.
class PrimaryActionBar extends StatelessWidget {
  const PrimaryActionBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.buttonKey,
    this.secondary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Key? buttonKey;
  final Widget? secondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: DriverTokens.card,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DriverTokens.edgeMargin,
            DriverTokens.spaceMd,
            DriverTokens.edgeMargin,
            DriverTokens.spaceMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: DriverTokens.actionHeight,
                child: FilledButton(
                  key: buttonKey,
                  onPressed: busy ? null : onPressed,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Flexible(child: Text(label)),
                          ],
                        ),
                ),
              ),
              ?secondary,
            ],
          ),
        ),
      ),
    );
  }
}
