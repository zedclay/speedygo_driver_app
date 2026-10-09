import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/application/offer_countdown.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';

export 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';

enum DriverHomeLoadStatus { idle, loading, ready, error }

enum LocationUiStatus {
  unknown,
  ready,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
  timeout,
  publishing,
  error,
}

class DriverHomeState {
  const DriverHomeState({
    this.loadStatus = DriverHomeLoadStatus.idle,
    this.me,
    this.offer,
    this.hasActiveDelivery = false,
    this.availabilityBusy = false,
    this.offerActionBusy = false,
    this.acceptedNavigationPending = false,
    this.errorMessage,
    this.errorCode,
    this.locationStatus = LocationUiStatus.unknown,
    this.locationMessage,
    this.serverSkewMs = 0,
    this.countdownTick = 0,
    this.offerExpiredLocally = false,
  });

  final DriverHomeLoadStatus loadStatus;
  final DriverMe? me;
  final AssignmentOffer? offer;
  final bool hasActiveDelivery;
  final bool availabilityBusy;
  final bool offerActionBusy;
  final bool acceptedNavigationPending;
  final String? errorMessage;
  final String? errorCode;
  final LocationUiStatus locationStatus;
  final String? locationMessage;
  final int serverSkewMs;
  final int countdownTick;
  final bool offerExpiredLocally;

  bool get isOnline => me?.availability?.isOnline == true;

  bool get isBlocked {
    final m = me;
    if (m == null) return false;
    if (!m.driverProfileExists) return true;
    if (m.availability?.isSuspended == true) return true;
    if (m.verificationStatus == 'SUSPENDED' ||
        m.verificationStatus == 'REJECTED') {
      return true;
    }
    return false;
  }

  bool get canToggleOnline {
    if (availabilityBusy || loadStatus == DriverHomeLoadStatus.loading) {
      return false;
    }
    final m = me;
    if (m == null || isBlocked) return false;
    final status = m.availability?.status;
    if (status == 'ONLINE' || status == 'OFFLINE_AFTER_CURRENT_DELIVERY') {
      return true;
    }
    return m.canAttemptGoOnline;
  }

  Duration remainingForOffer(DateTime localNowUtc) {
    final expires = offer?.expiresAtUtc;
    if (expires == null) return Duration.zero;
    return remainingUntilExpiry(
      expiresAtUtc: expires,
      localNowUtc: localNowUtc,
      serverSkewMs: serverSkewMs,
    );
  }

  DriverHomeState copyWith({
    DriverHomeLoadStatus? loadStatus,
    DriverMe? me,
    bool clearMe = false,
    AssignmentOffer? offer,
    bool clearOffer = false,
    bool? hasActiveDelivery,
    bool? availabilityBusy,
    bool? offerActionBusy,
    bool? acceptedNavigationPending,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    LocationUiStatus? locationStatus,
    String? locationMessage,
    bool clearLocationMessage = false,
    int? serverSkewMs,
    int? countdownTick,
    bool? offerExpiredLocally,
  }) {
    return DriverHomeState(
      loadStatus: loadStatus ?? this.loadStatus,
      me: clearMe ? null : (me ?? this.me),
      offer: clearOffer ? null : (offer ?? this.offer),
      hasActiveDelivery: hasActiveDelivery ?? this.hasActiveDelivery,
      availabilityBusy: availabilityBusy ?? this.availabilityBusy,
      offerActionBusy: offerActionBusy ?? this.offerActionBusy,
      acceptedNavigationPending:
          acceptedNavigationPending ?? this.acceptedNavigationPending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      locationStatus: locationStatus ?? this.locationStatus,
      locationMessage: clearLocationMessage
          ? null
          : (locationMessage ?? this.locationMessage),
      serverSkewMs: serverSkewMs ?? this.serverSkewMs,
      countdownTick: countdownTick ?? this.countdownTick,
      offerExpiredLocally: offerExpiredLocally ?? this.offerExpiredLocally,
    );
  }
}

final driverHomeControllerProvider =
    NotifierProvider<DriverHomeController, DriverHomeState>(
      DriverHomeController.new,
    );

class DriverHomeController extends Notifier<DriverHomeState> {
  static const offerPollInterval = Duration(seconds: 4);
  static const locationPublishInterval = Duration(seconds: 20);

  Timer? _offerPollTimer;
  Timer? _locationTimer;
  Timer? _countdownTimer;
  bool _disposed = false;

  @override
  DriverHomeState build() {
    _disposed = false;
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.status == SessionStatus.signedOut) {
        _stopBackgroundWork();
        state = const DriverHomeState();
      }
    });
    ref.onDispose(() {
      _disposed = true;
      _stopBackgroundWork();
    });
    return const DriverHomeState();
  }

  AvailabilityClient get _api => ref.read(availabilityClientProvider);
  DeviceLocationSource get _location => ref.read(deviceLocationSourceProvider);
  DeliveryClient get _delivery => ref.read(deliveryClientProvider);

  Future<void> bootstrap() async {
    await refresh(full: true);
  }

  Future<void> onAppResumed() async {
    if (state.me == null) {
      await refresh(full: true);
      return;
    }
    await refresh(full: false);
    _syncBackgroundWork();
    _bumpCountdown();
  }

  Future<void> refresh({bool full = true}) async {
    if (full) {
      state = state.copyWith(
        loadStatus: DriverHomeLoadStatus.loading,
        clearError: true,
        acceptedNavigationPending: false,
      );
    }
    try {
      final me = await _api.getMe();
      final delivery = await _delivery.getCurrent();
      final hasDelivery = delivery != null;
      AssignmentOffer? offer = state.offer;
      var skew = state.serverSkewMs;
      if (me.availability?.isOnline == true && !hasDelivery) {
        final result = await _api.getCurrentOffer();
        offer = result.offer;
        skew = estimateServerSkewMs(
          localSampleUtc: DateTime.now().toUtc(),
          serverSampleUtc: result.serverTime,
        );
      } else {
        offer = null;
      }
      if (_disposed) return;
      state = state.copyWith(
        loadStatus: DriverHomeLoadStatus.ready,
        me: me,
        offer: offer,
        clearOffer: offer == null,
        hasActiveDelivery: hasDelivery,
        serverSkewMs: skew,
        offerExpiredLocally: false,
        clearError: true,
      );
      _syncBackgroundWork();
      _bumpCountdown();
    } on AppException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        loadStatus: DriverHomeLoadStatus.error,
        errorMessage: error.message,
        errorCode: error.code,
      );
      _stopBackgroundWork();
    }
  }

  Future<void> goOnline() async {
    if (state.availabilityBusy || !state.canToggleOnline) return;
    if (state.isOnline) return;
    state = state.copyWith(availabilityBusy: true, clearError: true);
    try {
      // Server is authoritative — never mark ONLINE before this succeeds.
      final me = await _api.goOnline();
      if (_disposed) return;
      state = state.copyWith(me: me, availabilityBusy: false, clearError: true);
      // Matching/accept require fresh location (<=45s); best-effort after ONLINE.
      try {
        await _ensureLocationReady(requestIfNeeded: true);
        await _publishLocationOnce();
      } on DeviceLocationException catch (error) {
        if (_disposed) return;
        state = state.copyWith(
          locationStatus: _mapLocationFailure(error.failure),
          locationMessage: AppStrings.locationErrorFor(error.failure.name),
        );
      }
      await _pollOfferOnce();
      _syncBackgroundWork();
    } on AppException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        availabilityBusy: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
      await _reloadMeQuietly();
    }
  }

  Future<void> goOffline() async {
    if (state.availabilityBusy) return;
    final status = state.me?.availability?.status;
    if (status != 'ONLINE' && status != 'OFFLINE_AFTER_CURRENT_DELIVERY') {
      return;
    }
    state = state.copyWith(availabilityBusy: true, clearError: true);
    try {
      final me = await _api.goOffline();
      if (_disposed) return;
      state = state.copyWith(
        me: me,
        availabilityBusy: false,
        clearOffer: true,
        offerExpiredLocally: false,
        clearError: true,
      );
      _syncBackgroundWork();
    } on AppException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        availabilityBusy: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
      await _reloadMeQuietly();
    }
  }

  Future<void> acceptOffer() async {
    final offer = state.offer;
    if (offer == null || state.offerActionBusy || state.offerExpiredLocally) {
      return;
    }
    final remaining = state.remainingForOffer(DateTime.now().toUtc());
    if (remaining == Duration.zero) {
      state = state.copyWith(
        offerExpiredLocally: true,
        errorMessage: AppStrings.offerExpired,
        errorCode: 'DRIVER_ASSIGNMENT_EXPIRED',
      );
      await _pollOfferOnce();
      return;
    }
    state = state.copyWith(offerActionBusy: true, clearError: true);
    try {
      await _publishLocationOnce();
      await _api.acceptOffer(offer.assignmentId);
      if (_disposed) return;
      state = state.copyWith(
        offerActionBusy: false,
        clearOffer: true,
        hasActiveDelivery: true,
        acceptedNavigationPending: true,
        clearError: true,
      );
      _stopOfferPolling();
      // Refresh delivery cache for the existing screen.
      await ref.read(currentDeliveryControllerProvider.notifier).load();
    } on AppException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        offerActionBusy: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
      await refresh(full: false);
      if (_disposed) return;
      state = state.copyWith(
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
  }

  Future<void> rejectOffer() async {
    final offer = state.offer;
    if (offer == null || state.offerActionBusy || state.offerExpiredLocally) {
      return;
    }
    state = state.copyWith(offerActionBusy: true, clearError: true);
    try {
      await _api.rejectOffer(offer.assignmentId);
      if (_disposed) return;
      state = state.copyWith(
        offerActionBusy: false,
        clearOffer: true,
        offerExpiredLocally: false,
        clearError: true,
      );
      await _pollOfferOnce();
      _syncBackgroundWork();
    } on AppException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        offerActionBusy: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
      await refresh(full: false);
      if (_disposed) return;
      state = state.copyWith(
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
  }

  void clearAcceptedNavigationFlag() {
    if (state.acceptedNavigationPending) {
      state = state.copyWith(acceptedNavigationPending: false);
    }
  }

  void _syncBackgroundWork() {
    final online = state.isOnline;
    final busyWithDelivery = state.hasActiveDelivery;
    if (online && !busyWithDelivery) {
      _startOfferPolling();
      _startLocationPublishing();
      _startCountdown();
    } else if (online && busyWithDelivery) {
      _stopOfferPolling();
      _startLocationPublishing();
      _stopCountdown();
    } else {
      _stopBackgroundWork();
    }
  }

  void _stopBackgroundWork() {
    _stopOfferPolling();
    _stopLocationPublishing();
    _stopCountdown();
  }

  void _startOfferPolling() {
    _offerPollTimer ??= Timer.periodic(offerPollInterval, (_) {
      unawaited(_pollOfferOnce());
    });
  }

  void _stopOfferPolling() {
    _offerPollTimer?.cancel();
    _offerPollTimer = null;
  }

  void _startLocationPublishing() {
    _locationTimer ??= Timer.periodic(locationPublishInterval, (_) {
      unawaited(_publishLocationOnce());
    });
  }

  void _stopLocationPublishing() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _startCountdown() {
    _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _bumpCountdown();
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _bumpCountdown() {
    if (_disposed) return;
    final offer = state.offer;
    if (offer == null) {
      if (state.countdownTick != 0 || state.offerExpiredLocally) {
        state = state.copyWith(countdownTick: 0, offerExpiredLocally: false);
      }
      return;
    }
    final remaining = state.remainingForOffer(DateTime.now().toUtc());
    final expired = remaining == Duration.zero;
    state = state.copyWith(
      countdownTick: state.countdownTick + 1,
      offerExpiredLocally: expired,
    );
    if (expired) {
      unawaited(_pollOfferOnce());
    }
  }

  Future<void> _pollOfferOnce() async {
    if (!state.isOnline || state.hasActiveDelivery || state.offerActionBusy) {
      return;
    }
    try {
      final result = await _api.getCurrentOffer();
      if (_disposed) return;
      final skew = estimateServerSkewMs(
        localSampleUtc: DateTime.now().toUtc(),
        serverSampleUtc: result.serverTime,
      );
      final next = result.offer;
      if (next == null) {
        state = state.copyWith(
          clearOffer: true,
          serverSkewMs: skew,
          offerExpiredLocally: false,
        );
        return;
      }
      state = state.copyWith(
        offer: next,
        serverSkewMs: skew,
        offerExpiredLocally: isOfferExpiredByServer(
          expiresAtUtc: next.expiresAtUtc ?? DateTime.now().toUtc(),
          localNowUtc: DateTime.now().toUtc(),
          serverSkewMs: skew,
        ),
      );
    } on AppException catch (error) {
      if (_disposed) return;
      // Soft-fail polling; keep last known offer and surface recoverable error.
      state = state.copyWith(
        errorMessage: error.message,
        errorCode: error.code,
      );
    }
  }

  Future<void> _ensureLocationReady({required bool requestIfNeeded}) async {
    final enabled = await _location.isLocationServiceEnabled();
    if (!enabled) {
      throw const DeviceLocationException(
        DeviceLocationFailure.servicesDisabled,
      );
    }
    var permission = await _location.checkPermission();
    if (permission == LocationPermission.denied && requestIfNeeded) {
      permission = await _location.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(
        DeviceLocationFailure.permissionDenied,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        DeviceLocationFailure.permissionDeniedForever,
      );
    }
    state = state.copyWith(
      locationStatus: LocationUiStatus.ready,
      clearLocationMessage: true,
    );
  }

  Future<void> _publishLocationOnce() async {
    if (!state.isOnline && !state.hasActiveDelivery) return;
    try {
      await _ensureLocationReady(requestIfNeeded: false);
      state = state.copyWith(locationStatus: LocationUiStatus.publishing);
      final position = await _location.getCurrentPosition();
      await _api.publishLocation(
        DriverLocationUpdate(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracyMeters,
        ),
      );
      if (_disposed) return;
      state = state.copyWith(
        locationStatus: LocationUiStatus.ready,
        clearLocationMessage: true,
      );
    } on DeviceLocationException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        locationStatus: _mapLocationFailure(error.failure),
        locationMessage: AppStrings.locationErrorFor(error.failure.name),
      );
    } on AppException catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        locationStatus: LocationUiStatus.error,
        locationMessage: error.message,
      );
    }
  }

  Future<void> _reloadMeQuietly() async {
    try {
      final me = await _api.getMe();
      if (_disposed) return;
      state = state.copyWith(me: me);
      _syncBackgroundWork();
    } catch (_) {
      // Keep previous me; UI already shows the action error.
    }
  }

  LocationUiStatus _mapLocationFailure(DeviceLocationFailure failure) {
    switch (failure) {
      case DeviceLocationFailure.servicesDisabled:
        return LocationUiStatus.servicesDisabled;
      case DeviceLocationFailure.permissionDenied:
        return LocationUiStatus.permissionDenied;
      case DeviceLocationFailure.permissionDeniedForever:
        return LocationUiStatus.permissionDeniedForever;
      case DeviceLocationFailure.timeout:
        return LocationUiStatus.timeout;
      case DeviceLocationFailure.unavailable:
        return LocationUiStatus.unavailable;
    }
  }
}
