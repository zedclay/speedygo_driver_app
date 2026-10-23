import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

/// Provider-neutral navigation card for the bottom delivery sheet.
///
/// Maps and call remain honest blocked entries (no fake ETA / distance).
class DeliveryNavCard extends StatelessWidget {
  const DeliveryNavCard({super.key, required this.delivery});

  final DriverCurrentDelivery delivery;

  bool get _toMerchant =>
      delivery.deliveryStatus == 'DRIVER_ASSIGNED' ||
      delivery.deliveryStatus == 'TO_PICKUP' ||
      delivery.deliveryStatus == 'AT_PICKUP';

  bool get _waitingPrep => AppStrings.deliveryWaitingForPrep(
    delivery.deliveryStatus,
    delivery.fulfillmentStatus,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _toMerchant
        ? AppStrings.navPickupTitle
        : AppStrings.navDropoffTitle;
    return Column(
      key: const Key('nav_unavailable'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DriverTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: DriverTokens.spaceXs),
                  Text(
                    AppStrings.deliveryOrderRefPrefix,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: DriverTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            delivery.orderId,
                            softWrap: true,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DriverTokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('nav_copy_order'),
                        tooltip: AppStrings.navCopy,
                        visualDensity: VisualDensity.compact,
                        onPressed: delivery.orderId.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: delivery.orderId),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppStrings.navCopied),
                                  ),
                                );
                              },
                        icon: const Icon(
                          Icons.copy_outlined,
                          size: 18,
                          color: DriverTokens.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DriverTokens.spaceSm),
                  Text(
                    AppStrings.deliveryStepHint(delivery.deliveryStatus),
                    softWrap: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DriverTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DriverTokens.spaceMd),
            Container(
              constraints: const BoxConstraints(minWidth: 72),
              padding: const EdgeInsets.symmetric(
                horizontal: DriverTokens.spaceMd,
                vertical: DriverTokens.spaceSm,
              ),
              decoration: BoxDecoration(
                color: DriverTokens.secondaryFixed.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
                border: Border.all(color: DriverTokens.secondaryFixed),
              ),
              child: Column(
                children: [
                  Text(
                    '—',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: DriverTokens.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    AppStrings.navDistance,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: DriverTokens.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_waitingPrep) ...[
          const SizedBox(height: DriverTokens.spaceMd),
          Container(
            key: const Key('delivery_waiting_prep'),
            padding: const EdgeInsets.all(DriverTokens.spaceMd),
            decoration: BoxDecoration(
              color: DriverTokens.surfaceContainerLow,
              borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
              border: Border.all(color: DriverTokens.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: DriverTokens.warningContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top,
                    color: DriverTokens.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: DriverTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.deliveryWaitingPrepTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.deliveryWaitingPrepBody,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DriverTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: DriverTokens.spaceMd),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.assistant_navigation,
                label: AppStrings.navExternal,
                onTap: () =>
                    context.push(AppRoutes.blockedFor(BlockedKind.maps)),
              ),
            ),
            const SizedBox(width: DriverTokens.spaceMd),
            Expanded(
              child: _ActionTile(
                icon: Icons.call_outlined,
                label: AppStrings.navContact,
                onTap: () => context.push(
                  '${AppRoutes.blockedFor(BlockedKind.contact)}?role=${_toMerchant ? 'merchant' : 'customer'}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DriverTokens.radiusMd);
    return Material(
      color: DriverTokens.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: DriverTokens.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DriverTokens.spaceMd,
              horizontal: DriverTokens.spaceSm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: DriverTokens.primary, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DriverTokens.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
