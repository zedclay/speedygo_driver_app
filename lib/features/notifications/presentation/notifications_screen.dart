import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/empty_state_view.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';

/// In-app notification inbox (account scoped). No push provider involved.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final hasUnread = state.items.any((n) => !n.read);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.notificationsTitle),
        actions: [
          IconButton(
            key: const Key('notifications_read_all'),
            tooltip: AppStrings.notificationsMarkAll,
            onPressed: hasUnread ? controller.markAllRead : null,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(DriverTokens.edgeMargin),
          children: [
            if (state.status == PagedStatus.loading && state.items.isEmpty)
              LoadingView(message: AppStrings.loading),
            if (state.status == PagedStatus.error && state.items.isEmpty)
              ErrorRetryView(
                message: state.errorMessage ?? AppStrings.unexpectedError,
                onRetry: controller.load,
                retryKey: const Key('notifications_retry'),
              ),
            if (state.isEmpty)
              EmptyStateView(
                title: AppStrings.notificationsEmpty,
                icon: Icons.notifications_none,
              ),
            for (final item in state.items) ...[
              OperationalCard(
                key: Key('notification_${item.id}'),
                title: item.title,
                borderColor: item.read ? null : DriverTokens.primary,
                trailing: item.read
                    ? null
                    : StatusBadge(
                        label: AppStrings.notificationsUnread,
                        tone: StatusTone.info,
                      ),
                onTap: () => controller.markRead(item),
                child: Text(item.body),
              ),
              const SizedBox(height: DriverTokens.spaceMd),
            ],
            if (state.hasMore)
              Center(
                child: TextButton(
                  key: const Key('notifications_load_more'),
                  onPressed: state.loadingMore ? null : controller.loadMore,
                  child: Text(AppStrings.loadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
