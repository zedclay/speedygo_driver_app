import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/empty_state_view.dart';
import 'package:speedygo_driver_app/core/design_system/error_retry_view.dart';
import 'package:speedygo_driver_app/core/design_system/loading_view.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/notifications/application/notification_copy.dart';
import 'package:speedygo_driver_app/features/notifications/application/notification_navigation.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';

/// In-app notification inbox (account scoped). No push provider involved.
/// Opening this screen only loads `/notifications` — never availability,
/// assignment, delivery, or location mutations.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeControllerProvider);
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final unread = ref.watch(unreadNotificationsProvider) ?? 0;
    final hasUnread = unread > 0 || state.items.any((n) => !n.read);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.notificationsTitle),
        actions: [
          IconButton(
            key: const Key('notifications_read_all'),
            tooltip: AppStrings.notificationsMarkAll,
            onPressed: hasUnread && !state.mutating
                ? controller.markAllRead
                : null,
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
            if (state.errorMessage != null && state.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: DriverTokens.spaceMd),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            if (state.isEmpty)
              EmptyStateView(
                title: AppStrings.notificationsEmpty,
                icon: Icons.notifications_none,
              ),
            for (final item in state.items) ...[
              _DriverNotificationCard(
                item: item,
                busy: state.mutating,
                onOpen: () => _openItem(context, ref, item),
              ),
              const SizedBox(height: DriverTokens.spaceMd),
            ],
            if (state.loadMoreError != null)
              Column(
                children: [
                  Text(
                    state.loadMoreError!,
                    key: const Key('notifications_pagination_error'),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    key: const Key('notifications_pagination_retry'),
                    onPressed: controller.loadMore,
                    child: Text(AppStrings.retry),
                  ),
                ],
              )
            else if (state.hasMore)
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

  Future<void> _openItem(
    BuildContext context,
    WidgetRef ref,
    AppNotification item,
  ) async {
    final inbox = ref.read(notificationsControllerProvider);
    if (inbox.mutating) {
      return;
    }
    final destination = resolveDriverNotificationDestination(item);
    if (!item.read) {
      await ref.read(notificationsControllerProvider.notifier).markRead(item);
    }
    if (!context.mounted) {
      return;
    }
    if (!destination.canOpen) {
      return;
    }
    context.go(destination.location!);
  }
}

class _DriverNotificationCard extends StatelessWidget {
  const _DriverNotificationCard({
    required this.item,
    required this.onOpen,
    required this.busy,
  });

  final AppNotification item;
  final VoidCallback onOpen;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final copy = resolveSystemNotificationCopy(
      type: item.type,
      storedTitle: item.title,
      storedBody: item.body,
    );
    final time = formatNotificationTimestamp(item.createdAt);
    final bodyDirection = _directionFor(copy.body, context);
    return OperationalCard(
      key: Key('notification_${item.id}'),
      title: copy.title,
      borderColor: item.read ? null : DriverTokens.primary,
      trailing: item.read
          ? (time.isEmpty
                ? null
                : Text(
                    time,
                    style: Theme.of(context).textTheme.labelMedium,
                  ))
          : StatusBadge(
              label: AppStrings.notificationsUnread,
              tone: StatusTone.info,
            ),
      onTap: busy ? null : onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.body,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            textDirection: bodyDirection,
            textAlign: TextAlign.start,
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              time,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

TextDirection _directionFor(String value, BuildContext context) {
  return switch (guessTextDirection(value)) {
    TextDirectionGuess.rtl => TextDirection.rtl,
    TextDirectionGuess.ltr => TextDirection.ltr,
    TextDirectionGuess.neutral => Directionality.of(context),
  };
}
