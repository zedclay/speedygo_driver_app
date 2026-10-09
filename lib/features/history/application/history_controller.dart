import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/history/data/history_api.dart';
import 'package:speedygo_driver_app/features/history/data/history_models.dart';

final historyClientProvider = Provider<HistoryClient>((ref) {
  return HistoryApi(dio: ref.watch(apiClientProvider));
});

final historyControllerProvider =
    NotifierProvider<HistoryController, PagedState<HistoryItem>>(
      HistoryController.new,
    );

/// Detail loads on demand and is scoped by delivery id.
final historyDetailProvider = FutureProvider.autoDispose
    .family<HistoryItem, String>((ref, id) {
      return ref.watch(historyClientProvider).detail(id);
    });

class HistoryController extends Notifier<PagedState<HistoryItem>> {
  static const _pageSize = 30;

  @override
  PagedState<HistoryItem> build() => const PagedState();

  HistoryClient get _api => ref.read(historyClientProvider);

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
}
