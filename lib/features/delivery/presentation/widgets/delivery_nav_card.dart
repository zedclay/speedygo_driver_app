import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

/// Provider-neutral navigation card. The current-delivery DTO does not expose
/// merchant/customer addresses or a maps deep-link, so this stays honest.
class DeliveryNavCard extends StatelessWidget {
  const DeliveryNavCard({super.key, required this.delivery});

  final DriverCurrentDelivery delivery;

  bool get _toMerchant =>
      delivery.deliveryStatus == 'DRIVER_ASSIGNED' ||
      delivery.deliveryStatus == 'TO_PICKUP' ||
      delivery.deliveryStatus == 'AT_PICKUP';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _toMerchant
        ? AppStrings.navPickupTitle
        : AppStrings.navDropoffTitle;
    return OperationalCard(
      key: const Key('nav_unavailable'),
      title: title,
      leading: const Icon(Icons.map_outlined, color: DriverTokens.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.navUnavailable, style: theme.textTheme.bodyMedium),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            AppStrings.navCopyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: DriverTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
