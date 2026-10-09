import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/utils/paged_state.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/support/data/support_api.dart';

final supportClientProvider = Provider<SupportClient>((ref) {
  return SupportApi(dio: ref.watch(apiClientProvider));
});

final supportControllerProvider =
    NotifierProvider<SupportController, PagedState<SupportTicket>>(
      SupportController.new,
    );

final supportDetailProvider = FutureProvider.autoDispose
    .family<SupportTicket, String>((ref, id) {
      return ref.watch(supportClientProvider).detail(id);
    });

class SupportController extends Notifier<PagedState<SupportTicket>> {
  static const _pageSize = 30;

  @override
  PagedState<SupportTicket> build() => const PagedState();

  SupportClient get _api => ref.read(supportClientProvider);

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

  /// Creates a ticket; returns it on success, null (with error in state) else.
  Future<SupportTicket?> create(String body) async {
    final text = body.trim();
    if (text.isEmpty) return null;
    try {
      final ticket = await _api.create(text);
      state = state.copyWith(
        items: [ticket, ...state.items],
        total: state.total + 1,
        status: PagedStatus.ready,
        clearError: true,
      );
      return ticket;
    } on AppException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      return null;
    }
  }

  /// Replies; returns null on success or the error message.
  Future<String?> reply(String ticketId, String body) async {
    final text = body.trim();
    if (text.isEmpty) return null;
    try {
      await _api.reply(ticketId, text);
      ref.invalidate(supportDetailProvider(ticketId));
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }
}
