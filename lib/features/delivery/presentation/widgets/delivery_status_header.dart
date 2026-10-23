import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

const _statusOrder = [
  'DRIVER_ASSIGNED',
  'TO_PICKUP',
  'AT_PICKUP',
  'PICKED_UP',
  'IN_TRANSIT',
  'ARRIVED_CUSTOMER',
  'DELIVERED',
];

/// Status progress and order reference for the active delivery sheet.
///
/// Stitch composition: white card with a lime top accent, circular status
/// glyph, bold status line, segmented step progress and a tinted order chip.
class DeliveryStatusHeader extends StatelessWidget {
  const DeliveryStatusHeader({
    super.key,
    required this.delivery,
    this.compact = false,
  });

  final DriverCurrentDelivery delivery;
  final bool compact;

  StatusTone get _tone => switch (delivery.deliveryStatus) {
    'DELIVERED' => StatusTone.success,
    'AT_PICKUP' || 'ARRIVED_CUSTOMER' => StatusTone.warning,
    _ => StatusTone.info,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = delivery.deliveryStatus;
    final index = _statusOrder.indexOf(status);
    final color = switch (_tone) {
      StatusTone.success => DriverTokens.success,
      StatusTone.warning => DriverTokens.warning,
      _ => DriverTokens.primary,
    };
    final glyphBg = switch (_tone) {
      StatusTone.success => DriverTokens.successContainer,
      StatusTone.warning => DriverTokens.warningContainer,
      _ => DriverTokens.primaryContainer,
    };

    final steps = Row(
      children: [
        for (var i = 0; i < _statusOrder.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: compact ? 4 : 6,
              decoration: BoxDecoration(
                color: i <= index ? color : DriverTokens.neutralContainer,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: compact ? 36 : 44,
              height: compact ? 36 : 44,
              decoration: BoxDecoration(color: glyphBg, shape: BoxShape.circle),
              child: Icon(
                Icons.local_shipping_outlined,
                color: color,
                size: compact ? 20 : 24,
              ),
            ),
            const SizedBox(width: DriverTokens.spaceMd),
            Expanded(
              child: Text(
                AppStrings.deliveryStatusLabel(status),
                key: const Key('delivery_status_text'),
                style:
                    (compact
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleLarge)
                        ?.copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ),
            if (!compact)
              StatusBadge(
                label: AppStrings.deliveryInProgressBadge,
                tone: StatusTone.success,
              ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            AppStrings.deliveryStepHint(status),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DriverTokens.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: DriverTokens.spaceMd),
        steps,
        if (!compact) ...[
          const SizedBox(height: DriverTokens.spaceMd),
          _CopyableReferenceRow(
            key: const Key('delivery_copy_order'),
            icon: Icons.receipt_long_outlined,
            label: AppStrings.orderIdLabel,
            value: delivery.orderId,
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          _CopyableReferenceRow(
            key: const Key('delivery_copy_assignment'),
            icon: Icons.assignment_outlined,
            label: AppStrings.assignmentLabel,
            value: delivery.assignmentId,
            subtle: true,
          ),
        ],
      ],
    );

    return Semantics(
      container: true,
      label:
          '${AppStrings.statusLabel}: ${AppStrings.deliveryStatusLabel(status)}',
      child: compact
          ? content
          : Container(
              key: const Key('delivery_status_card'),
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
                  Container(height: 4, color: DriverTokens.tertiaryFixed),
                  Padding(
                    padding: const EdgeInsets.all(DriverTokens.spaceLg),
                    child: content,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Full ID row with soft-wrap + copy — no ellipsis truncation of UUIDs.
class _CopyableReferenceRow extends StatelessWidget {
  const _CopyableReferenceRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtle = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool subtle;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppStrings.navCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = subtle ? DriverTokens.textSecondary : DriverTokens.onSecondaryFixed;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsetsDirectional.only(
        start: 10,
        end: 4,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: subtle
            ? DriverTokens.surfaceContainerLow
            : DriverTokens.secondaryFixed.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DriverTokens.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 16,
              color: subtle ? DriverTokens.outline : DriverTokens.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DriverTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value,
                    softWrap: true,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.navCopy,
            visualDensity: VisualDensity.compact,
            onPressed: value.isEmpty ? null : () => _copy(context),
            icon: const Icon(
              Icons.copy_outlined,
              size: 18,
              color: DriverTokens.primary,
            ),
          ),
        ],
      ),
    );
  }
}
