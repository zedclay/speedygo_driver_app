import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

enum StatusTone { neutral, info, success, warning, danger }

/// Compact pill used for delivery / verification / ticket statuses.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  (Color, Color) get _colors => switch (tone) {
    StatusTone.info => (DriverTokens.primaryContainer, DriverTokens.primary),
    StatusTone.success => (DriverTokens.successContainer, DriverTokens.success),
    StatusTone.warning => (DriverTokens.warningContainer, DriverTokens.warning),
    StatusTone.danger => (DriverTokens.dangerContainer, DriverTokens.danger),
    StatusTone.neutral => (
      DriverTokens.neutralContainer,
      DriverTokens.textSecondary,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
