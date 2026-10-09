import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';
import 'package:speedygo_driver_app/features/onboarding/data/document_source.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

final driverProfileClientProvider = Provider<DriverProfileClient>((ref) {
  return DriverProfileApi(dio: ref.watch(apiClientProvider));
});

enum OnboardingLoadStatus { idle, loading, ready, error }

class OnboardingState {
  const OnboardingState({
    this.loadStatus = OnboardingLoadStatus.idle,
    this.me,
    this.busy = false,
    this.errorMessage,
    this.successMessage,
  });

  final OnboardingLoadStatus loadStatus;
  final DriverMe? me;
  final bool busy;
  final String? errorMessage;
  final String? successMessage;

  OnboardingState copyWith({
    OnboardingLoadStatus? loadStatus,
    DriverMe? me,
    bool? busy,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return OnboardingState(
      loadStatus: loadStatus ?? this.loadStatus,
      me: me ?? this.me,
      busy: busy ?? this.busy,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

/// Drives onboarding / profile edits using only the real `/driver/*` contract.
/// Each mutating method reloads `/driver/me` so the server stays authoritative.
class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.status == SessionStatus.signedOut) {
        state = const OnboardingState();
      }
    });
    return const OnboardingState();
  }

  DriverProfileClient get _api => ref.read(driverProfileClientProvider);

  Future<void> load() async {
    state = state.copyWith(
      loadStatus: OnboardingLoadStatus.loading,
      clearMessages: true,
    );
    try {
      final me = await _api.getMe();
      state = state.copyWith(loadStatus: OnboardingLoadStatus.ready, me: me);
    } on AppException catch (error) {
      state = state.copyWith(
        loadStatus: OnboardingLoadStatus.error,
        errorMessage: error.message,
      );
    }
  }

  /// Runs a mutation, then reloads `me`. Returns true on success.
  Future<bool> _mutate(
    Future<void> Function() run, {
    String? successMessage,
  }) async {
    if (state.busy) return false;
    state = state.copyWith(busy: true, clearMessages: true);
    try {
      await run();
      final me = await _api.getMe();
      state = state.copyWith(
        busy: false,
        me: me,
        loadStatus: OnboardingLoadStatus.ready,
        successMessage: successMessage,
      );
      return true;
    } on AppException catch (error) {
      state = state.copyWith(busy: false, errorMessage: error.message);
      return false;
    }
  }

  Future<bool> saveProfile(String fullName) async {
    final name = fullName.trim();
    if (name.isEmpty) {
      state = state.copyWith(errorMessage: AppStrings.fullNameInvalid);
      return false;
    }
    final exists = state.me?.driverProfileExists == true;
    final ok = await _mutate(
      () => exists ? _api.updateProfile(name) : _api.createProfile(name),
    );
    if (ok && !exists) {
      // Account now has a DriverProfile: promote the session out of
      // needsDriverProfile so the app shell becomes reachable.
      await ref.read(sessionControllerProvider.notifier).restore();
    }
    return ok;
  }

  /// Picks a file, uploads bytes (multipart), then registers metadata.
  Future<bool> uploadDocument(String type, {String? expiryDate}) async {
    if (state.busy) return false;
    PickedDocument? pickedFile;
    try {
      pickedFile = await ref.read(documentSourceProvider).pick();
    } on DocumentPickerUnavailable {
      state = state.copyWith(
        errorMessage: AppStrings.uploadPickerUnavailable,
        clearMessages: false,
      );
      return false;
    }
    final picked = pickedFile;
    if (picked == null) return false;
    return _mutate(() async {
      final reference = await _api.uploadDocumentContent(
        type: type,
        bytes: picked.bytes,
        filename: picked.filename,
        mimeType: picked.mimeType,
      );
      await _api.upsertDocument(
        type: type,
        expiryDate: expiryDate,
        uploadReference: reference,
      );
    }, successMessage: AppStrings.uploadDone);
  }

  Future<bool> saveVehicle({
    required String type,
    required String plateNumber,
    required String model,
    String? color,
  }) {
    final existing = state.me?.activeVehicle;
    return _mutate(() {
      if (existing != null) {
        return _api.updateVehicle(
          existing.id,
          type: type,
          plateNumber: plateNumber,
          model: model,
          color: color,
        );
      }
      return _api.createVehicle(
        type: type,
        plateNumber: plateNumber,
        model: model,
        color: color,
      );
    }, successMessage: AppStrings.vehicleSaved);
  }

  /// Submits for review. Server validates (incl. mandatory DRIVING_LICENSE).
  Future<bool> submit() async {
    final me = state.me;
    if (me == null || !canSubmitVerification(me) || state.busy) return false;
    state = state.copyWith(busy: true, clearMessages: true);
    try {
      final updated = await _api.submitVerification();
      state = state.copyWith(busy: false, me: updated);
      return true;
    } on AppException catch (error) {
      state = state.copyWith(busy: false, errorMessage: error.message);
      return false;
    }
  }
}
