import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/empty_state_view.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';

/// Honest placeholder for flows whose backend contract does not exist yet
/// (delivery PIN, failure report, contact proxy, maps, notification prefs).
/// It never simulates the feature — it explains the blocker.
class HonestUnavailableScreen extends ConsumerWidget {
  const HonestUnavailableScreen({super.key, required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    final canSupport =
        kind == BlockedKind.contact || kind == BlockedKind.failureReport;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.blockedTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DriverTokens.edgeMargin),
        children: [
          EmptyStateView(
            key: const Key('blocked_view'),
            title: AppStrings.blockedHeading(kind),
            message: AppStrings.blockedBody(kind),
            icon: Icons.lock_clock_outlined,
          ),
          if (canSupport)
            SizedBox(
              height: DriverTokens.actionHeight,
              child: FilledButton(
                key: const Key('blocked_support'),
                onPressed: () => context.push(AppRoutes.support),
                child: Text(AppStrings.supportTitle),
              ),
            ),
          const SizedBox(height: DriverTokens.spaceMd),
          SizedBox(
            height: DriverTokens.touchTarget,
            child: TextButton(
              key: const Key('blocked_back'),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              child: Text(AppStrings.back),
            ),
          ),
        ],
      ),
    );
  }
}
