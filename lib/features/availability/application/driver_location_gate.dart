import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';

/// Outcome of an OS location-access check (permission + device services).
/// Does not imply a GPS fix was obtained or that coordinates were published.
enum LocationAccessOutcome {
  ready,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unableToDetermine,
}

/// Single-flight coordinator for When-In-Use permission prompts.
///
/// Home bootstrap and delivery/home recover paths share one gate so only one
/// native permission dialog runs at a time. Publishing coordinates remains the
/// caller's responsibility and must stay behind auth + ONLINE/active delivery.
class DriverLocationGate {
  DriverLocationGate(this._source);

  final DeviceLocationSource _source;

  Future<LocationAccessOutcome>? _inflight;
  bool _autoRequestConsumed = false;
  bool _cancelled = false;

  /// Clears in-flight work and allows a fresh auto-prompt after re-login.
  void reset() {
    _cancelled = true;
    _autoRequestConsumed = false;
    _inflight = null;
  }

  /// Arms the gate after logout reset so a new session can request again.
  void arm() {
    _cancelled = false;
  }

  /// Ensures OS authorization is usable. Never publishes coordinates.
  ///
  /// When [allowAutoRequest] is true and authorization is still undetermined
  /// (`denied` before the first prompt), requests When In Use once per session.
  Future<LocationAccessOutcome> ensureAccess({
    required bool allowAutoRequest,
    bool forceRequest = false,
  }) {
    final existing = _inflight;
    if (existing != null) {
      return existing;
    }
    final future = _ensureAccess(
      allowAutoRequest: allowAutoRequest,
      forceRequest: forceRequest,
    );
    _inflight = future;
    return future.whenComplete(() {
      if (identical(_inflight, future)) {
        _inflight = null;
      }
    });
  }

  Future<LocationAccessOutcome> _ensureAccess({
    required bool allowAutoRequest,
    required bool forceRequest,
  }) async {
    _cancelled = false;
    final enabled = await _source.isLocationServiceEnabled();
    if (_cancelled) {
      return LocationAccessOutcome.unableToDetermine;
    }
    if (!enabled) {
      return LocationAccessOutcome.servicesDisabled;
    }

    var permission = await _source.checkPermission();
    if (_cancelled) {
      return LocationAccessOutcome.unableToDetermine;
    }

    final shouldRequest =
        forceRequest ||
        (allowAutoRequest &&
            !_autoRequestConsumed &&
            permission == LocationPermission.denied);

    if (shouldRequest) {
      _autoRequestConsumed = true;
      permission = await _source.requestPermission();
      if (_cancelled) {
        return LocationAccessOutcome.unableToDetermine;
      }
    }

    return _mapPermission(permission);
  }

  LocationAccessOutcome _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationAccessOutcome.ready;
      case LocationPermission.deniedForever:
        return LocationAccessOutcome.permissionDeniedForever;
      case LocationPermission.denied:
        return LocationAccessOutcome.permissionDenied;
      case LocationPermission.unableToDetermine:
        return LocationAccessOutcome.unableToDetermine;
    }
  }
}

final driverLocationGateProvider = Provider<DriverLocationGate>((ref) {
  final gate = DriverLocationGate(ref.watch(deviceLocationSourceProvider));
  ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
    if (!next.canRunDriverOps) {
      gate.reset();
    } else {
      gate.arm();
    }
  });
  ref.onDispose(gate.reset);
  return gate;
});
