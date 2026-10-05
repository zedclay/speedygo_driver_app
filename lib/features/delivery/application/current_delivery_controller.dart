import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

enum DeliveryLoadStatus { idle, loading, ready, empty, error }

class CurrentDeliveryState {
  const CurrentDeliveryState({
    this.loadStatus = DeliveryLoadStatus.idle,
    this.delivery,
    this.errorMessage,
    this.errorCode,
    this.pickupCode = '',
    this.submitting = false,
    this.successMessage,
  });

  final DeliveryLoadStatus loadStatus;
  final DriverCurrentDelivery? delivery;
  final String? errorMessage;
  final String? errorCode;
  final String pickupCode;
  final bool submitting;
  final String? successMessage;

  bool get canSubmit {
    if (submitting) return false;
    final d = delivery;
    if (d == null || !d.canConfirmPickup) return false;
    // Empty = legacy optional body; 1–3 digits = incomplete (disabled); 4 = coded.
    if (pickupCode.isEmpty) return true;
    return pickupCode.length == 4 && RegExp(r'^\d{4}$').hasMatch(pickupCode);
  }

  CurrentDeliveryState copyWith({
    DeliveryLoadStatus? loadStatus,
    DriverCurrentDelivery? delivery,
    bool clearDelivery = false,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    String? pickupCode,
    bool? submitting,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return CurrentDeliveryState(
      loadStatus: loadStatus ?? this.loadStatus,
      delivery: clearDelivery ? null : (delivery ?? this.delivery),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      pickupCode: pickupCode ?? this.pickupCode,
      submitting: submitting ?? this.submitting,
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

final deliveryClientProvider = Provider<DeliveryClient>((ref) {
  return DeliveryApi(dio: ref.watch(apiClientProvider));
});

final currentDeliveryControllerProvider =
    NotifierProvider<CurrentDeliveryController, CurrentDeliveryState>(
      CurrentDeliveryController.new,
    );

class CurrentDeliveryController extends Notifier<CurrentDeliveryState> {
  @override
  CurrentDeliveryState build() {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.status == SessionStatus.signedOut) {
        // Clear in-memory pickup code on logout / session drop.
        state = const CurrentDeliveryState();
      }
    });
    return const CurrentDeliveryState();
  }

  DeliveryClient get _api => ref.read(deliveryClientProvider);

  Future<void> load() async {
    state = state.copyWith(
      loadStatus: DeliveryLoadStatus.loading,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final delivery = await _api.getCurrent();
      if (delivery == null) {
        state = state.copyWith(
          loadStatus: DeliveryLoadStatus.empty,
          clearDelivery: true,
        );
        return;
      }
      final clearCode = !delivery.canConfirmPickup || delivery.isPickedUp;
      state = state.copyWith(
        loadStatus: DeliveryLoadStatus.ready,
        delivery: delivery,
        pickupCode: clearCode ? '' : state.pickupCode,
        clearError: true,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        loadStatus: DeliveryLoadStatus.error,
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
  }

  void updatePickupCode(String value) {
    // Digits only, max 4 — never logged.
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;
    state = state.copyWith(
      pickupCode: clipped,
      clearError: true,
      clearSuccess: true,
    );
  }

  void clearPickupCode() {
    state = state.copyWith(pickupCode: '');
  }

  Future<void> confirmPickup() async {
    final delivery = state.delivery;
    if (delivery == null || !state.canSubmit || state.submitting) return;

    state = state.copyWith(
      submitting: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final code = state.pickupCode;
      final ConfirmPickupRequest body;
      if (code.length == 4) {
        body = ConfirmPickupRequest(
          pickupCode: code,
          assignmentId: delivery.assignmentId,
          assignmentVersion: delivery.assignmentVersion,
        );
      } else {
        // Legacy path: empty body (no invented handoffRequired).
        body = const ConfirmPickupRequest();
      }
      final updated = await _api.confirmPickup(body);
      state = state.copyWith(
        submitting: false,
        delivery: updated,
        loadStatus: DeliveryLoadStatus.ready,
        pickupCode: '',
        successMessage: AppStrings.pickedUpSuccess,
        clearError: true,
      );
    } on AppException catch (error) {
      final code = error.code;
      final shouldRefresh =
          code == 'PICKUP_HANDOFF_ASSIGNMENT_CONFLICT' ||
          code == 'DRIVER_DELIVERY_ASSIGNMENT_NOT_ACTIVE' ||
          code == 'DRIVER_DELIVERY_INVALID_STATE' ||
          code == 'PICKUP_HANDOFF_INVALID_STATE';
      // Preserve in-memory code on network / invalid code / locked / expired.
      final clearCode =
          code == 'PICKUP_HANDOFF_ASSIGNMENT_CONFLICT' ||
          code == 'DRIVER_DELIVERY_ASSIGNMENT_NOT_ACTIVE';
      final preservedCode = clearCode ? '' : state.pickupCode;
      state = state.copyWith(
        submitting: false,
        errorMessage: error.message,
        errorCode: code,
        pickupCode: preservedCode,
      );
      if (shouldRefresh) {
        await load();
        // load() clears transient errors; restore the authoritative conflict reason.
        state = state.copyWith(
          errorMessage: error.message,
          errorCode: code,
          pickupCode: clearCode ? '' : preservedCode,
        );
      }
    }
  }
}
