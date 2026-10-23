import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Entry points for flows the backend contract does not support yet.
/// Each row opens the honest blocked screen — nothing is simulated.
class DeliveryHelpCard extends StatelessWidget {
  const DeliveryHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('delivery_help_card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.deliveryHelpTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: DriverTokens.spaceSm),
        Material(
          color: DriverTokens.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
            side: const BorderSide(color: DriverTokens.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _tile(
                context,
                key: const Key('help_contact'),
                icon: Icons.storefront_outlined,
                label: AppStrings.deliveryContactMerchant,
                route:
                    '${AppRoutes.blockedFor(BlockedKind.contact)}?role=merchant',
              ),
              _divider,
              _tile(
                context,
                key: const Key('help_contact_customer'),
                icon: Icons.person_outline,
                label: AppStrings.deliveryContactCustomer,
                route:
                    '${AppRoutes.blockedFor(BlockedKind.contact)}?role=customer',
              ),
              _divider,
              _tile(
                context,
                key: const Key('help_delivery_pin'),
                icon: Icons.pin_outlined,
                label: AppStrings.blockedHeading(BlockedKind.deliveryPin),
                route: AppRoutes.blockedFor(BlockedKind.deliveryPin),
              ),
              _divider,
              _tile(
                context,
                key: const Key('help_report'),
                icon: Icons.report_problem_outlined,
                label: AppStrings.deliveryReportProblem,
                route: AppRoutes.blockedFor(BlockedKind.failureReport),
                danger: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const Widget _divider = Divider(
    height: 1,
    color: DriverTokens.outlineVariant,
  );

  Widget _tile(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required String route,
    bool danger = false,
  }) {
    final color = danger ? DriverTokens.danger : DriverTokens.primary;
    return ListTile(
      key: key,
      minTileHeight: DriverTokens.touchTarget,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: danger ? DriverTokens.danger : DriverTokens.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: DriverTokens.outline),
      onTap: () => context.push(route),
    );
  }
}
