import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_api.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_models.dart';

final earningsClientProvider = Provider<EarningsClient>((ref) {
  return EarningsApi(dio: ref.watch(apiClientProvider));
});

enum EarningsLoadStatus { idle, loading, ready, error }

class EarningsState {
  const EarningsState({
    this.status = EarningsLoadStatus.idle,
    this.summary,
    this.cod,
    this.items = const [],
    this.total = 0,
    this.loadingMore = false,
    this.remitInput = '',
    this.remitBusy = false,
    this.errorMessage,
    this.successMessage,
  });

  final EarningsLoadStatus status;
  final EarningsSummary? summary;
  final CodSummary? cod;
  final List<EarningItem> items;
  final int total;
  final bool loadingMore;
  final String remitInput;
  final bool remitBusy;
  final String? errorMessage;
  final String? successMessage;

  bool get hasMore => items.length < total;

  int? get remitAmountMinor =>
      RegExp(r'^\d{1,12}$').hasMatch(remitInput) ? int.parse(remitInput) : null;

  bool get canSubmitRemittance =>
      !remitBusy &&
      cod?.canDeclareRemittance == true &&
      (remitAmountMinor ?? 0) > 0;

  EarningsState copyWith({
    EarningsLoadStatus? status,
    EarningsSummary? summary,
    CodSummary? cod,
    List<EarningItem>? items,
    int? total,
    bool? loadingMore,
    String? remitInput,
    bool? remitBusy,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return EarningsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      cod: cod ?? this.cod,
      items: items ?? this.items,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
      remitInput: remitInput ?? this.remitInput,
      remitBusy: remitBusy ?? this.remitBusy,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

final earningsControllerProvider =
    NotifierProvider<EarningsController, EarningsState>(EarningsController.new);

class EarningsController extends Notifier<EarningsState> {
  static const _pageSize = 30;

  @override
  EarningsState build() => const EarningsState();

  EarningsClient get _api => ref.read(earningsClientProvider);

  Future<void> load() async {
    state = state.copyWith(
      status: EarningsLoadStatus.loading,
      clearMessages: true,
    );
    try {
      final summary = await _api.summary();
      final page = await _api.list(limit: _pageSize);
      final cod = await _api.codSummary();
      state = state.copyWith(
        status: EarningsLoadStatus.ready,
        summary: summary,
        cod: cod,
        items: page.items,
        total: page.page.total,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        status: EarningsLoadStatus.error,
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

  void updateRemitInput(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(
      remitInput: digits.length > 12 ? digits.substring(0, 12) : digits,
      clearMessages: true,
    );
  }

  /// Declares a remittance. Does not change custody locally — the server
  /// summary is reloaded and remains the only authority.
  Future<void> submitRemittance() async {
    final amount = state.remitAmountMinor;
    if (!state.canSubmitRemittance || amount == null) return;
    state = state.copyWith(remitBusy: true, clearMessages: true);
    try {
      await _api.submitRemittance(submittedAmountMinor: amount);
      final cod = await _api.codSummary();
      state = state.copyWith(
        remitBusy: false,
        cod: cod,
        remitInput: '',
        successMessage: AppStrings.codRemitSuccess,
      );
    } on AppException catch (error) {
      state = state.copyWith(remitBusy: false, errorMessage: error.message);
    }
  }
}
