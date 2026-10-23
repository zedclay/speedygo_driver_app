enum PagedStatus { idle, loading, ready, error }

/// Immutable list state shared by thin paginated controllers.
class PagedState<T> {
  const PagedState({
    this.status = PagedStatus.idle,
    this.items = const [],
    this.total = 0,
    this.loadingMore = false,
    this.mutating = false,
    this.errorMessage,
    this.loadMoreError,
  });

  final PagedStatus status;
  final List<T> items;
  final int total;
  final bool loadingMore;
  final bool mutating;
  final String? errorMessage;
  final String? loadMoreError;

  bool get hasMore => items.length < total;
  bool get isEmpty => status == PagedStatus.ready && items.isEmpty;

  PagedState<T> copyWith({
    PagedStatus? status,
    List<T>? items,
    int? total,
    bool? loadingMore,
    bool? mutating,
    String? errorMessage,
    String? loadMoreError,
    bool clearError = false,
    bool clearLoadMoreError = false,
  }) {
    return PagedState<T>(
      status: status ?? this.status,
      items: items ?? this.items,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
      mutating: mutating ?? this.mutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
    );
  }
}
