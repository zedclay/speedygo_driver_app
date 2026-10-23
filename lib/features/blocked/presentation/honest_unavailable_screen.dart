import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';

/// Honest placeholder for flows whose backend contract does not exist yet.
class HonestUnavailableScreen extends ConsumerWidget {
  const HonestUnavailableScreen({super.key, required this.kind, this.role});

  final String kind;

  /// Optional contact role (`merchant` | `customer`). When null, reads
  /// `?role=` from [GoRouterState] if a router is present.
  final String? role;

  String _title(String? resolvedRole) {
    if (kind == BlockedKind.contact) {
      return resolvedRole == 'customer'
          ? AppStrings.deliveryContactCustomer
          : AppStrings.deliveryContactMerchant;
    }
    return AppStrings.blockedHeading(kind);
  }

  IconData get _heroIcon => switch (kind) {
    BlockedKind.contact => Icons.storefront,
    BlockedKind.deliveryPin => Icons.pin,
    BlockedKind.failureReport => Icons.report_problem_outlined,
    BlockedKind.maps => Icons.map_outlined,
    _ => Icons.lock_clock_outlined,
  };

  String? _resolveRole(BuildContext context) {
    if (role != null) return role;
    try {
      return GoRouterState.of(context).uri.queryParameters['role'];
    } on Object {
      return null;
    }
  }

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    try {
      context.go(AppRoutes.home);
    } on Object {
      // Widget-test harness without GoRouter — no-op.
    }
  }

  void _openSupport(BuildContext context) {
    try {
      context.push(AppRoutes.support);
    } on Object {
      // Widget-test harness without GoRouter — no-op.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    final resolvedRole = _resolveRole(context);
    final canSupport =
        kind == BlockedKind.contact || kind == BlockedKind.failureReport;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      appBar: DriverNestedAppBar(
        title: _title(resolvedRole),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBack(context),
        ),
      ),
      body: ListView(
        key: const Key('blocked_view'),
        padding: const EdgeInsets.all(DriverTokens.edgeMargin),
        children: [
          Container(
            padding: const EdgeInsets.all(DriverTokens.spaceMd),
            decoration: BoxDecoration(
              color: DriverTokens.surfaceContainerLow,
              borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
              border: Border.all(
                color: DriverTokens.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: DriverTokens.primaryContainer,
                  child: Icon(Icons.info, color: DriverTokens.primary),
                ),
                const SizedBox(width: DriverTokens.spaceMd),
                Expanded(
                  child: Text(
                    AppStrings.blockedBody(kind),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DriverTokens.spaceLg),
          Container(
            padding: const EdgeInsets.all(DriverTokens.spaceLg),
            decoration: BoxDecoration(
              color: DriverTokens.card,
              borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
              boxShadow: DriverTokens.cardShadow,
              border: Border.all(color: DriverTokens.outlineVariant),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: DriverTokens.surfaceContainer,
                  child: Icon(_heroIcon, size: 36, color: DriverTokens.primary),
                ),
                const SizedBox(height: DriverTokens.spaceMd),
                Text(
                  AppStrings.blockedHeading(kind),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DriverTokens.spaceSm),
                Text(
                  AppStrings.blockedActionUnavailable,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: DriverTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DriverTokens.spaceXl),
          SizedBox(
            height: DriverTokens.actionHeight,
            child: FilledButton.icon(
              onPressed: null,
              icon: Icon(switch (kind) {
                BlockedKind.contact => Icons.call,
                BlockedKind.deliveryPin => Icons.verified_user,
                BlockedKind.failureReport => Icons.warning_amber,
                _ => Icons.block,
              }),
              label: Text(AppStrings.blockedHeading(kind)),
            ),
          ),
          const SizedBox(height: DriverTokens.spaceMd),
          if (kind == BlockedKind.contact)
            SizedBox(
              height: DriverTokens.actionHeight,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(AppStrings.navContact),
              ),
            ),
          if (canSupport) ...[
            const SizedBox(height: DriverTokens.spaceMd),
            SizedBox(
              height: DriverTokens.actionHeight,
              child: FilledButton(
                key: const Key('blocked_support'),
                onPressed: () => _openSupport(context),
                child: Text(AppStrings.supportTitle),
              ),
            ),
          ],
          const SizedBox(height: DriverTokens.spaceMd),
          TextButton.icon(
            key: const Key('blocked_back'),
            onPressed: () => _goBack(context),
            icon: const Icon(Icons.map_outlined),
            label: Text(AppStrings.blockedReturnToDelivery),
          ),
        ],
      ),
    );
  }
}
