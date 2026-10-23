import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Displays a server-authoritative remaining duration (already computed by the
/// caller from expiresAt). Turns red when expired or about to expire.
class CountdownBadge extends StatelessWidget {
  const CountdownBadge({
    super.key,
    required this.text,
    this.expired = false,
    this.urgent = false,
    this.valueKey,
  });

  final String text;
  final bool expired;
  final bool urgent;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final danger = expired || urgent;
    final fg = danger ? DriverTokens.danger : DriverTokens.primary;
    final bg = danger
        ? DriverTokens.dangerContainer
        : DriverTokens.primaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              key: valueKey,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
