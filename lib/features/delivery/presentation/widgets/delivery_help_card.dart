import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';

/// Entry points for flows the backend contract does not support yet
/// (contact proxy, failure report). They open the honest blocked screen.
class DeliveryHelpCard extends StatelessWidget {
  const DeliveryHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return OperationalCard(
      key: const Key('delivery_help_card'),
      title: AppStrings.deliveryHelpTitle,
      leading: const Icon(Icons.help_outline, color: DriverTokens.primary),
      padding: const EdgeInsets.all(DriverTokens.spaceMd),
      child: Column(
        children: [
          _tile(
            context,
            key: const Key('help_contact'),
            icon: Icons.phone_disabled_outlined,
            label: AppStrings.contactUnavailableTitle,
            kind: BlockedKind.contact,
          ),
          _tile(
            context,
            key: const Key('help_report'),
            icon: Icons.report_problem_outlined,
            label: AppStrings.failureReportTitle,
            kind: BlockedKind.failureReport,
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required String kind,
  }) {
    return ListTile(
      key: key,
      minTileHeight: DriverTokens.touchTarget,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.blockedFor(kind)),
    );
  }
}
