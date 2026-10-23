import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_shell_chrome.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/profile/presentation/profile_screen.dart';

/// Post-login shell — Modern White: light header, bottom tabs, drawer.
///
/// Branches: Home (Commandes) / History / Earnings / Profile.
class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _goBranch(int index) {
    Navigator.of(context).maybePop();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final unread = ref.watch(unreadNotificationsProvider) ?? 0;
    final index = widget.navigationShell.currentIndex;
    final home = ref.watch(driverHomeControllerProvider);
    final delivery = ref.watch(currentDeliveryControllerProvider);
    final me = ref.watch(onboardingControllerProvider).me;
    final name = me?.profileFullName ?? home.me?.profileFullName ?? '';
    final online = home.isOnline;
    final path = GoRouterState.of(context).uri.toString();
    final homeHasOffer = home.offer != null;
    final showAppBar = DriverShellChrome.showShellAppBar(
      path,
      homeHasOffer: homeHasOffer,
    );
    final showDrawer = DriverShellChrome.showDrawerAccess(
      path,
      homeHasOffer: homeHasOffer,
    );
    final hideNav = DriverShellChrome.hideBottomNav(
      path: path,
      homeHasOffer: homeHasOffer,
      deliveryStatus: delivery.delivery?.deliveryStatus,
      deliveryCanConfirmPickup:
          delivery.delivery?.canConfirmPickup == true,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DriverTokens.surface,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: DriverTokens.surface,
              foregroundColor: DriverTokens.navy,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                key: const Key('shell_menu_button'),
                tooltip: AppStrings.openMenu,
                onPressed: _openDrawer,
                icon: const Icon(Icons.menu),
              ),
              title: Text(
                AppStrings.appNameShort,
                key: const Key('shell_title'),
                style: const TextStyle(
                  color: DriverTokens.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.2,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  key: const Key('shell_notifications'),
                  tooltip: AppStrings.notificationsTooltip,
                  onPressed: () => context.push(AppRoutes.notifications),
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    smallSize: 10,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
                // Compatibility for prior smoke/tests.
                IconButton(
                  key: const Key('shell_profile_button'),
                  tooltip: AppStrings.profileTooltip,
                  onPressed: () => _goBranch(3),
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            )
          : null,
      drawer: showDrawer
          ? _DriverNavDrawer(
              selectedIndex: index,
              driverName: name,
              isOnline: online,
              verified:
                  me?.verificationApproved == true ||
                  home.me?.verificationApproved == true,
              onSelectBranch: _goBranch,
              onVehicle: () {
                Navigator.of(context).maybePop();
                context.push(AppRoutes.vehicle);
              },
              onDocuments: () {
                Navigator.of(context).maybePop();
                context.push(AppRoutes.documents);
              },
              onRatings: () {
                Navigator.of(context).maybePop();
                context.push(AppRoutes.ratings);
              },
              onSettings: () {
                Navigator.of(context).maybePop();
                context.push(AppRoutes.settings);
              },
              onSupport: () {
                Navigator.of(context).maybePop();
                context.push(AppRoutes.support);
              },
              onLogout: () async {
                Navigator.of(context).maybePop();
                await confirmLogout(context, ref);
              },
            )
          : null,
      body: widget.navigationShell,
      bottomNavigationBar: hideNav
          ? null
          : NavigationBar(
              key: const Key('shell_bottom_nav'),
              height: 68,
              backgroundColor: DriverTokens.surface,
              surfaceTintColor: Colors.transparent,
              indicatorColor: DriverTokens.primaryContainer,
              selectedIndex: index,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: _goBranch,
              destinations: [
                NavigationDestination(
                  key: const Key('tab_orders'),
                  icon: const Icon(Icons.local_shipping_outlined),
                  selectedIcon: const Icon(Icons.local_shipping),
                  label: AppStrings.navOrders,
                ),
                NavigationDestination(
                  key: const Key('tab_history'),
                  icon: const Icon(Icons.history),
                  selectedIcon: const Icon(Icons.history),
                  label: AppStrings.navHistory,
                ),
                NavigationDestination(
                  key: const Key('tab_earnings'),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet),
                  label: AppStrings.navEarnings,
                ),
                NavigationDestination(
                  key: const Key('tab_profile'),
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: AppStrings.navProfile,
                ),
              ],
            ),
    );
  }
}

class _DriverNavDrawer extends StatelessWidget {
  const _DriverNavDrawer({
    required this.selectedIndex,
    required this.driverName,
    required this.isOnline,
    required this.verified,
    required this.onSelectBranch,
    required this.onVehicle,
    required this.onDocuments,
    required this.onRatings,
    required this.onSettings,
    required this.onSupport,
    required this.onLogout,
  });

  final int selectedIndex;
  final String driverName;
  final bool isOnline;
  final bool verified;
  final ValueChanged<int> onSelectBranch;
  final VoidCallback onVehicle;
  final VoidCallback onDocuments;
  final VoidCallback onRatings;
  final VoidCallback onSettings;
  final VoidCallback onSupport;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = driverName.isEmpty ? AppStrings.profileNoName : driverName;
    return Drawer(
      backgroundColor: DriverTokens.surface,
      width: MediaQuery.sizeOf(context).width * 0.86,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                children: [
                  Text(
                    AppStrings.appNameShort,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: DriverTokens.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: AppStrings.closeMenu,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: DriverTokens.navy),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: DriverTokens.primaryContainer,
                    child: Text(
                      _initials(display),
                      style: const TextStyle(
                        color: DriverTokens.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: DriverTokens.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: DriverTokens.success,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  AppStrings.accountVerified,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: DriverTokens.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? DriverTokens.success
                                    : DriverTokens.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isOnline
                                    ? AppStrings.availabilityOnline
                                    : AppStrings.availabilityOffline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: DriverTokens.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: DriverTokens.outlineVariant),
            const SizedBox(height: 8),
            _DrawerTile(
              key: const Key('nav_orders'),
              icon: Icons.local_shipping,
              label: AppStrings.navOrders,
              selected: selectedIndex == 0,
              onTap: () => onSelectBranch(0),
            ),
            _DrawerTile(
              key: const Key('nav_history'),
              icon: Icons.history,
              label: AppStrings.navHistory,
              selected: selectedIndex == 1,
              onTap: () => onSelectBranch(1),
            ),
            _DrawerTile(
              key: const Key('nav_earnings'),
              icon: Icons.account_balance_wallet,
              label: AppStrings.navEarnings,
              selected: selectedIndex == 2,
              onTap: () => onSelectBranch(2),
            ),
            _DrawerTile(
              key: const Key('nav_profile'),
              icon: Icons.person,
              label: AppStrings.navProfile,
              selected: selectedIndex == 3,
              onTap: () => onSelectBranch(3),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(height: 1, color: DriverTokens.outlineVariant),
            ),
            _DrawerTile(
              key: const Key('nav_vehicle'),
              icon: Icons.directions_car_outlined,
              label: AppStrings.navVehicle,
              selected: false,
              onTap: onVehicle,
            ),
            _DrawerTile(
              key: const Key('nav_documents'),
              icon: Icons.description_outlined,
              label: AppStrings.navDocuments,
              selected: false,
              onTap: onDocuments,
            ),
            _DrawerTile(
              key: const Key('nav_ratings'),
              icon: Icons.star_outline,
              label: AppStrings.navRatings,
              selected: false,
              onTap: onRatings,
            ),
            _DrawerTile(
              key: const Key('nav_settings'),
              icon: Icons.settings_outlined,
              label: AppStrings.navSettings,
              selected: false,
              onTap: onSettings,
            ),
            _DrawerTile(
              key: const Key('nav_support'),
              icon: Icons.support_agent,
              label: AppStrings.navSupport,
              selected: false,
              onTap: onSupport,
            ),
            const Spacer(),
            const Divider(height: 1, color: DriverTokens.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                key: const Key('drawer_logout'),
                leading: const Icon(Icons.logout, color: DriverTokens.danger),
                title: Text(
                  AppStrings.logout,
                  style: const TextStyle(
                    color: DriverTokens.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: DriverTokens.outline,
                ),
                onTap: onLogout,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? DriverTokens.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
        child: ListTile(
          minTileHeight: DriverTokens.touchTarget,
          leading: Icon(
            icon,
            color: selected ? DriverTokens.primary : DriverTokens.navy,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: selected ? DriverTokens.primary : DriverTokens.navy,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: selected
                ? DriverTokens.primary
                : DriverTokens.outlineVariant,
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
          ),
        ),
      ),
    );
  }
}
