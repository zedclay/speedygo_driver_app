import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';

/// Shared providers extracted so delivery actions can publish location without
/// importing the home controller (avoids a circular dependency).
final availabilityClientProvider = Provider<AvailabilityClient>((ref) {
  return AvailabilityApi(dio: ref.watch(apiClientProvider));
});

final deviceLocationSourceProvider = Provider<DeviceLocationSource>((ref) {
  return GeolocatorLocationSource();
});
