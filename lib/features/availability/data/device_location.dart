import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum DeviceLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
  timeout,
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.failure);

  final DeviceLocationFailure failure;

  @override
  String toString() => 'DeviceLocationException($failure)';
}

class DevicePosition {
  const DevicePosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
}

abstract class DeviceLocationSource {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
  Future<DevicePosition> getCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
  });
}

class GeolocatorLocationSource implements DeviceLocationSource {
  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<DevicePosition> getCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return DevicePosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy.isFinite ? position.accuracy : null,
      );
    } on LocationServiceDisabledException {
      throw const DeviceLocationException(
        DeviceLocationFailure.servicesDisabled,
      );
    } on PermissionDeniedException {
      throw const DeviceLocationException(
        DeviceLocationFailure.permissionDenied,
      );
    } on TimeoutException {
      throw const DeviceLocationException(DeviceLocationFailure.timeout);
    } on DeviceLocationException {
      rethrow;
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('timeout') || text.contains('time limit')) {
        throw const DeviceLocationException(DeviceLocationFailure.timeout);
      }
      if (text.contains('disabled') || text.contains('service')) {
        throw const DeviceLocationException(
          DeviceLocationFailure.servicesDisabled,
        );
      }
      if (text.contains('permission') || text.contains('denied')) {
        throw const DeviceLocationException(
          DeviceLocationFailure.permissionDenied,
        );
      }
      throw const DeviceLocationException(DeviceLocationFailure.unavailable);
    }
  }
}

/// Test double — never returns fabricated coordinates unless the test sets them.
class FakeDeviceLocationSource implements DeviceLocationSource {
  FakeDeviceLocationSource({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.position,
    this.failure,
  });

  bool serviceEnabled;
  LocationPermission permission;
  DevicePosition? position;
  DeviceLocationFailure? failure;

  /// When set, [requestPermission] assigns this value to [permission] first.
  LocationPermission? grantOnRequest;
  int getCurrentCount = 0;
  int requestPermissionCount = 0;
  int openAppSettingsCount = 0;
  int openLocationSettingsCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCount += 1;
    final next = grantOnRequest;
    if (next != null) {
      permission = next;
    }
    return permission;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCount += 1;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCount += 1;
    return true;
  }

  @override
  Future<DevicePosition> getCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    getCurrentCount += 1;
    if (failure != null) {
      throw DeviceLocationException(failure!);
    }
    final value = position;
    if (value == null) {
      throw const DeviceLocationException(DeviceLocationFailure.unavailable);
    }
    return value;
  }
}
