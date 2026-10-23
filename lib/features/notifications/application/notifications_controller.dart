import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';

final notificationsClientProvider = Provider<NotificationsClient>((ref) {
  return NotificationsApi(dio: ref.watch(apiClientProvider));
});

bool isNotificationMutationUncertain(AppException error) {
  final status = error is ApiException ? error.statusCode : null;
  return error.code == 'NETWORK' ||
      error.code == 'NETWORK_TIMEOUT' ||
      error.code == 'NOTIFICATION_READ_UNCERTAIN' ||
      error.code == 'NOTIFICATION_READ_ALL_UNCERTAIN' ||
      (status != null && status >= 500);
}

class UnreadNotificationsController extends Notifier<int?> {
  var _generation = 0;

  @override
  int? build() {
    ref.watch(sessionEpochProvider);
    _generation += 1;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await refresh();
    });
    return null;
  }

  void apply(int count) {
    state = count < 0 ? 0 : count;
  }

  Future<void> refresh() async {
    final generation = _generation;
    try {
      final count = await ref.read(notificationsClientProvider).unreadCount();
      if (generation != _generation) {
        return;
      }
      state = count < 0 ? 0 : count;
    } catch (_) {
      if (generation != _generation) {
        return;
      }
    }
  }
}

/// Account-wide unread count. Failures keep the last known value.
final unreadNotificationsProvider =
    NotifierProvider<UnreadNotificationsController, int?>(
      UnreadNotificationsController.new,
    );

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, PagedState<AppNotification>>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<PagedState<AppNotification>> {
  static const pageSize = 30;
  var _generation = 0;
  var _markInFlight = false;

  @override
  PagedState<AppNotification> build() {
    ref.watch(sessionEpochProvider);
    _generation += 1;
    _markInFlight = false;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await load();
    });
    return const PagedState();
  }

  NotificationsClient get _api => ref.read(notificationsClientProvider);

  Future<void> load({bool quiet = false}) async {
    final generation = _generation;
    if (!quiet || state.items.isEmpty) {
      state = state.copyWith(
        status: PagedStatus.loading,
        clearError: true,
        clearLoadMoreError: true,
      );
    } else {
      state = state.copyWith(clearError: true, clearLoadMoreError: true);
    }
    try {
      final page = await _api.list(limit: pageSize);
      if (generation != _generation) {
        return;
      }
      state = PagedState(
        status: PagedStatus.ready,
        items: _uniqueById(page.items),
        total: page.page.total,
      );
      _applyUnread(page.unreadCount);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        status: PagedStatus.error,
        errorMessage: error.message,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(loadingMore: true, clearLoadMoreError: true);
    try {
      final page = await _api.list(
        limit: pageSize,
        offset: state.items.length,
      );
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        status: PagedStatus.ready,
        loadingMore: false,
        items: _mergeUnique(state.items, page.items),
        total: page.page.total,
        clearLoadMoreError: true,
      );
      _applyUnread(page.unreadCount);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: error.message,
      );
    }
  }

  Future<void> markRead(AppNotification item) async {
    if (_markInFlight || item.read) {
      return;
    }
    final index = state.items.indexWhere((n) => n.id == item.id);
    if (index < 0) {
      return;
    }
    _markInFlight = true;
    final generation = _generation;
    final previousItems = state.items;
    final previousUnread = ref.read(unreadNotificationsProvider) ?? 0;
    final optimistic = [...previousItems];
    optimistic[index] = optimistic[index].copyWith(read: true);
    final optimisticUnread = previousUnread > 0 ? previousUnread - 1 : 0;
    state = state.copyWith(
      items: optimistic,
      mutating: true,
      clearError: true,
    );
    _applyUnread(optimisticUnread);
    try {
      await _api.markRead(item.id);
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(mutating: false);
      await _reconcileUnread(generation);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      if (isNotificationMutationUncertain(error)) {
        await _reconcileAfterUncertain(
          generation,
          previousItems,
          previousUnread,
        );
        return;
      }
      _restoreSnapshot(previousItems, previousUnread, error.message);
    } finally {
      if (generation == _generation) {
        _markInFlight = false;
      }
    }
  }

  Future<void> markAllRead() async {
    final unread = ref.read(unreadNotificationsProvider) ??
        state.items.where((n) => !n.read).length;
    if (_markInFlight || unread <= 0) {
      return;
    }
    _markInFlight = true;
    final generation = _generation;
    final previousItems = state.items;
    final previousUnread = unread;
    state = state.copyWith(
      items: [for (final n in previousItems) n.copyWith(read: true)],
      mutating: true,
      clearError: true,
    );
    _applyUnread(0);
    try {
      await _api.markAllRead();
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(mutating: false);
      await _reconcileUnread(generation);
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      if (isNotificationMutationUncertain(error)) {
        await _reconcileAfterUncertain(
          generation,
          previousItems,
          previousUnread,
        );
        return;
      }
      _restoreSnapshot(previousItems, previousUnread, error.message);
    } finally {
      if (generation == _generation) {
        _markInFlight = false;
      }
    }
  }

  void _restoreSnapshot(
    List<AppNotification> items,
    int unreadCount,
    String message,
  ) {
    state = state.copyWith(
      items: items,
      mutating: false,
      errorMessage: message,
    );
    _applyUnread(unreadCount);
  }

  Future<void> _reconcileAfterUncertain(
    int generation,
    List<AppNotification> previousItems,
    int previousUnread,
  ) async {
    await load(quiet: true);
    if (generation != _generation) {
      return;
    }
    if (state.errorMessage != null) {
      _restoreSnapshot(previousItems, previousUnread, state.errorMessage!);
      return;
    }
    state = state.copyWith(mutating: false);
  }

  Future<void> _reconcileUnread(int generation) async {
    try {
      final count = await _api.unreadCount();
      if (generation != _generation) {
        return;
      }
      _applyUnread(count);
    } catch (_) {}
  }

  void _applyUnread(int count) {
    if (!ref.mounted) {
      return;
    }
    ref.read(unreadNotificationsProvider.notifier).apply(count);
  }
}

List<AppNotification> _uniqueById(List<AppNotification> items) {
  return _mergeUnique(const [], items);
}

List<AppNotification> _mergeUnique(
  List<AppNotification> current,
  List<AppNotification> incoming,
) {
  final seen = {for (final item in current) item.id};
  final merged = [...current];
  for (final item in incoming) {
    if (seen.add(item.id)) {
      merged.add(item);
    }
  }
  return merged;
}
