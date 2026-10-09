import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/profile/presentation/profile_screen.dart';

/// Settings hub: language (implemented), notification prefs (blocked),
/// support, logout.
class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DriverTokens.edgeMargin),
        children: [
          OperationalCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: const Key('settings_language'),
                  minTileHeight: DriverTokens.touchTarget,
                  leading: const Icon(Icons.language),
                  title: Text(AppStrings.languageSettingsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.languageSettings),
                ),
                ListTile(
                  key: const Key('settings_notification_prefs'),
                  minTileHeight: DriverTokens.touchTarget,
                  leading: const Icon(Icons.notifications_off_outlined),
                  title: Text(AppStrings.settingsNotificationPrefs),
                  subtitle: Text(AppStrings.settingsNotificationPrefsHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.blockedFor(BlockedKind.notificationPrefs),
                  ),
                ),
                ListTile(
                  key: const Key('settings_support'),
                  minTileHeight: DriverTokens.touchTarget,
                  leading: const Icon(Icons.support_agent),
                  title: Text(AppStrings.supportTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.support),
                ),
              ],
            ),
          ),
          const SizedBox(height: DriverTokens.spaceLg),
          SizedBox(
            height: DriverTokens.actionHeight,
            child: OutlinedButton.icon(
              key: const Key('settings_logout'),
              onPressed: () => confirmLogout(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(AppStrings.logout),
            ),
          ),
        ],
      ),
    );
  }
}
