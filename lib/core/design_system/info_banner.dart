import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';

/// Inline success / error / info message block.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.tone = StatusTone.info,
    this.icon,
  });

  final String message;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, defaultIcon) = switch (tone) {
      StatusTone.success => (
        DriverTokens.successContainer,
        DriverTokens.success,
        Icons.check_circle_outline,
      ),
      StatusTone.danger => (
        DriverTokens.dangerContainer,
        DriverTokens.danger,
        Icons.error_outline,
      ),
      StatusTone.warning => (
        DriverTokens.warningContainer,
        DriverTokens.warning,
        Icons.warning_amber_outlined,
      ),
      _ => (
        DriverTokens.primaryContainer,
        DriverTokens.primary,
        Icons.info_outline,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DriverTokens.spaceMd),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: fg, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
