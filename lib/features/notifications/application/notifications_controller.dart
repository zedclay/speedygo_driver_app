import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';

final notificationsClientProvider = Provider<NotificationsClient>((ref) {
  return NotificationsApi(dio: ref.watch(apiClientProvider));
});

/// Unread badge for the shell. Failures degrade to 0 (never blocks the shell).
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  try {
    return await ref.watch(notificationsClientProvider).unreadCount();
  } on AppException {
    return 0;
  }
});

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, PagedState<AppNotification>>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<PagedState<AppNotification>> {
  static const _pageSize = 30;

  @override
  PagedState<AppNotification> build() => const PagedState();

  NotificationsClient get _api => ref.read(notificationsClientProvider);

  Future<void> load() async {
    state = state.copyWith(status: PagedStatus.loading, clearError: true);
    try {
      final page = await _api.list(limit: _pageSize);
      state = PagedState(
        status: PagedStatus.ready,
        items: page.items,
        total: page.page.total,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        status: PagedStatus.error,
        errorMessage: error.message,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _api.list(
        limit: _pageSize,
        offset: state.items.length,
      );
      state = state.copyWith(
        loadingMore: false,
        items: [...state.items, ...page.items],
        total: page.page.total,
      );
    } on AppException catch (error) {
      state = state.copyWith(loadingMore: false, errorMessage: error.message);
    }
  }

  Future<void> markRead(AppNotification item) async {
    if (item.read) return;
    try {
      await _api.markRead(item.id);
      state = state.copyWith(
        items: [
          for (final n in state.items)
            n.id == item.id ? n.copyWith(read: true) : n,
        ],
      );
      ref.invalidate(unreadNotificationsProvider);
    } on AppException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllRead();
      state = state.copyWith(
        items: [for (final n in state.items) n.copyWith(read: true)],
      );
      ref.invalidate(unreadNotificationsProvider);
    } on AppException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    }
  }
}
