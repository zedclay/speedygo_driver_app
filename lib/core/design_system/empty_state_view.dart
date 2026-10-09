import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: DriverTokens.edgeMargin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: DriverTokens.textSecondary),
          const SizedBox(height: DriverTokens.spaceLg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: DriverTokens.spaceSm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: DriverTokens.spaceLg),
            SizedBox(
              height: DriverTokens.touchTarget,
              child: OutlinedButton(
                key: actionKey,
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
