import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';

/// Canonical 4-tab shell. Stitch hamburger/drawer variants merge here:
/// leading profile, centered SpeedyGo title, trailing notifications.
class DriverShell extends ConsumerWidget {
  const DriverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    final unread = ref.watch(unreadNotificationsProvider).asData?.value ?? 0;

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('shell_profile_button'),
          tooltip: AppStrings.profileTooltip,
          onPressed: () => navigationShell.goBranch(3),
          icon: const Icon(Icons.account_circle_outlined),
        ),
        title: Text(AppStrings.appName, key: const Key('shell_title')),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('shell_notifications'),
            tooltip: AppStrings.notificationsTooltip,
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          NavigationDestination(
            key: const Key('nav_orders'),
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping),
            label: AppStrings.navOrders,
          ),
          NavigationDestination(
            key: const Key('nav_history'),
            icon: const Icon(Icons.history),
            label: AppStrings.navHistory,
          ),
          NavigationDestination(
            key: const Key('nav_earnings'),
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments),
            label: AppStrings.navEarnings,
          ),
          NavigationDestination(
            key: const Key('nav_profile'),
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}
