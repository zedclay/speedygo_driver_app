import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
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

/// Status card: label (once), step hint, progress and order reference.
class DeliveryStatusHeader extends StatelessWidget {
  const DeliveryStatusHeader({super.key, required this.delivery});

  final DriverCurrentDelivery delivery;

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
    final progress = index < 0 ? 0.0 : (index + 1) / _statusOrder.length;
    final color = switch (_tone) {
      StatusTone.success => DriverTokens.success,
      StatusTone.warning => DriverTokens.warning,
      _ => DriverTokens.primary,
    };
    return Semantics(
      container: true,
      label:
          '${AppStrings.statusLabel}: ${AppStrings.deliveryStatusLabel(status)}',
      child: OperationalCard(
        key: const Key('delivery_status_card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: color, size: 28),
                const SizedBox(width: DriverTokens.spaceMd),
                Expanded(
                  child: Text(
                    AppStrings.deliveryStatusLabel(status),
                    key: const Key('delivery_status_text'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DriverTokens.spaceSm),
            Text(
              AppStrings.deliveryStepHint(status),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(DriverTokens.radiusSm),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: color,
                backgroundColor: DriverTokens.neutralContainer,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceMd),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${AppStrings.orderIdLabel}: ${delivery.orderId}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceXs),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${AppStrings.assignmentLabel}: ${delivery.assignmentId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
