import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';

/// Shows one verification document row (metadata only — never a file URL).
class DocumentStatusCard extends StatelessWidget {
  const DocumentStatusCard({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.tone,
    this.detail,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final String title;
  final String statusLabel;
  final StatusTone tone;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OperationalCard(
      title: title,
      leading: const Icon(
        Icons.description_outlined,
        color: DriverTokens.primary,
      ),
      trailing: StatusBadge(label: statusLabel, tone: tone),
      child: (detail != null || onAction != null)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(detail!, style: theme.textTheme.bodyMedium),
                  ),
                if (onAction != null && actionLabel != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      key: actionKey,
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
              ],
            )
          : null,
    );
  }
}
