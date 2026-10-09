import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';
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
    this.busyAction,
    this.successMessage,
    this.codAmountInput = '',
    this.codCollected = false,
    this.codBusy = false,
  });

  final DeliveryLoadStatus loadStatus;
  final DriverCurrentDelivery? delivery;
  final String? errorMessage;
  final String? errorCode;
  final String pickupCode;
  final String? busyAction;
  final String? successMessage;
  final String codAmountInput;
  final bool codCollected;
  final bool codBusy;

  bool get submitting => busyAction != null;

  int? get codAmountMinor {
    if (codAmountInput.isEmpty) return null;
    return int.tryParse(codAmountInput);
  }

  bool get canSubmit {
    if (submitting) return false;
    final d = delivery;
    if (d == null || !d.canConfirmPickup) return false;
    // Empty = legacy optional body; 1–3 digits = incomplete (disabled); 4 = coded.
    if (pickupCode.isEmpty) return true;
    return pickupCode.length == 4 && RegExp(r'^\d{4}$').hasMatch(pickupCode);
  }

  bool get canCollectCod {
    if (codBusy || codCollected || submitting) return false;
    final d = delivery;
    if (d == null || !d.canCollectCod) return false;
    final amount = codAmountMinor;
    return amount != null && amount >= 0;
  }

  CurrentDeliveryState copyWith({
    DeliveryLoadStatus? loadStatus,
    DriverCurrentDelivery? delivery,
    bool clearDelivery = false,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    String? pickupCode,
    String? busyAction,
    bool clearBusy = false,
    String? successMessage,
    bool clearSuccess = false,
    String? codAmountInput,
    bool? codCollected,
    bool? codBusy,
  }) {
    return CurrentDeliveryState(
      loadStatus: loadStatus ?? this.loadStatus,
      delivery: clearDelivery ? null : (delivery ?? this.delivery),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      pickupCode: pickupCode ?? this.pickupCode,
      busyAction: clearBusy ? null : (busyAction ?? this.busyAction),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      codAmountInput: codAmountInput ?? this.codAmountInput,
      codCollected: codCollected ?? this.codCollected,
      codBusy: codBusy ?? this.codBusy,
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
        state = const CurrentDeliveryState();
      }
    });
    return const CurrentDeliveryState();
  }

  DeliveryClient get _api => ref.read(deliveryClientProvider);
  AvailabilityClient get _availability => ref.read(availabilityClientProvider);
  DeviceLocationSource get _location => ref.read(deviceLocationSourceProvider);

  static String? pathForAction(String action) {
    switch (action) {
      case DeliveryActions.startToPickup:
        return ApiEndpoints.driverStartToPickupPath;
      case DeliveryActions.arrivePickup:
        return ApiEndpoints.driverArrivePickupPath;
      case DeliveryActions.startDelivery:
        return ApiEndpoints.driverStartDeliveryPath;
      case DeliveryActions.arriveCustomer:
        return ApiEndpoints.driverArriveCustomerPath;
      case DeliveryActions.completeDelivery:
        return ApiEndpoints.driverCompleteDeliveryPath;
      default:
        return null;
    }
  }

  Future<void> load() async {
    final previous = state.delivery;
    state = state.copyWith(
      loadStatus: DeliveryLoadStatus.loading,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final delivery = await _api.getCurrent();
      if (delivery == null) {
        // Keep a completed DELIVERED view until the driver acknowledges it.
        if (previous?.isDelivered == true) {
          state = state.copyWith(
            loadStatus: DeliveryLoadStatus.ready,
            delivery: previous,
            clearError: true,
          );
          return;
        }
        state = state.copyWith(
          loadStatus: DeliveryLoadStatus.empty,
          clearDelivery: true,
        );
        return;
      }
      final clearCode = !delivery.canConfirmPickup || delivery.isPickedUp;
      final resetCod = delivery.deliveryStatus != previous?.deliveryStatus;
      state = state.copyWith(
        loadStatus: DeliveryLoadStatus.ready,
        delivery: delivery,
        pickupCode: clearCode ? '' : state.pickupCode,
        codAmountInput: resetCod ? '' : state.codAmountInput,
        codCollected: resetCod ? false : state.codCollected,
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

  void updateCodAmount(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(
      codAmountInput: digits,
      clearError: true,
      clearSuccess: true,
    );
  }

  void reset() {
    state = const CurrentDeliveryState();
  }

  Future<void> performAction(String action) async {
    final delivery = state.delivery;
    if (delivery == null || state.submitting) return;
    if (!delivery.allowedActions.contains(action)) return;

    if (action == DeliveryActions.confirmPickup) {
      await confirmPickup();
      return;
    }

    final path = pathForAction(action);
    if (path == null) return;

    state = state.copyWith(
      busyAction: action,
      clearError: true,
      clearSuccess: true,
    );
    try {
      if (DeliveryActions.locationGated.contains(action)) {
        await _publishFreshLocation();
      }
      final updated = await _api.postAction(path);
      state = state.copyWith(
        clearBusy: true,
        delivery: updated,
        loadStatus: DeliveryLoadStatus.ready,
        successMessage: updated.isDelivered
            ? AppStrings.deliveredSuccess
            : null,
        clearError: true,
        codAmountInput: updated.isArrivedCustomer ? state.codAmountInput : '',
        codCollected: updated.isArrivedCustomer ? state.codCollected : false,
      );
    } on DeviceLocationException catch (error) {
      state = state.copyWith(
        clearBusy: true,
        errorMessage: AppStrings.locationErrorFor(error.failure.name),
      );
    } on AppException catch (error) {
      state = state.copyWith(
        clearBusy: true,
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
  }

  Future<void> confirmPickup() async {
    final delivery = state.delivery;
    if (delivery == null || !state.canSubmit || state.submitting) return;

    state = state.copyWith(
      busyAction: DeliveryActions.confirmPickup,
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
        body = const ConfirmPickupRequest();
      }
      final updated = await _api.confirmPickup(body);
      state = state.copyWith(
        clearBusy: true,
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
      final clearCode =
          code == 'PICKUP_HANDOFF_ASSIGNMENT_CONFLICT' ||
          code == 'DRIVER_DELIVERY_ASSIGNMENT_NOT_ACTIVE';
      final preservedCode = clearCode ? '' : state.pickupCode;
      state = state.copyWith(
        clearBusy: true,
        errorMessage: error.message,
        errorCode: code,
        pickupCode: preservedCode,
      );
      if (shouldRefresh) {
        await load();
        state = state.copyWith(
          errorMessage: error.message,
          errorCode: code,
          pickupCode: clearCode ? '' : preservedCode,
        );
      }
    }
  }

  Future<void> collectCod(int amountMinor) async {
    final delivery = state.delivery;
    if (delivery == null || !delivery.canCollectCod) return;
    if (state.codBusy || state.codCollected || state.submitting) return;

    state = state.copyWith(codBusy: true, clearError: true, clearSuccess: true);
    try {
      await _api.collectCod(amountMinor);
      state = state.copyWith(
        codBusy: false,
        codCollected: true,
        successMessage: AppStrings.codCollectedSuccess,
        clearError: true,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        codBusy: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
  }

  Future<void> _publishFreshLocation() async {
    final position = await _location.getCurrentPosition();
    await _availability.publishLocation(
      DriverLocationUpdate(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracyMeters,
      ),
    );
  }
}
