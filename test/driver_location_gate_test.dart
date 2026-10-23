import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_location_gate.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';

void main() {
  late FakeDeviceLocationSource source;
  late DriverLocationGate gate;

  setUp(() {
    source = FakeDeviceLocationSource(
      permission: LocationPermission.denied,
      position: const DevicePosition(latitude: 36.75, longitude: 3.06),
    );
    gate = DriverLocationGate(source);
  });

  test('auto-requests When In Use once when undetermined', () async {
    source.grantOnRequest = LocationPermission.whileInUse;
    final first = await gate.ensureAccess(allowAutoRequest: true);
    expect(first, LocationAccessOutcome.ready);
    expect(source.requestPermissionCount, 1);

    source.permission = LocationPermission.denied;
    final second = await gate.ensureAccess(allowAutoRequest: true);
    expect(second, LocationAccessOutcome.permissionDenied);
    expect(source.requestPermissionCount, 1);
  });

  test('single-flights concurrent ensureAccess calls', () async {
    source.grantOnRequest = LocationPermission.whileInUse;
    final a = gate.ensureAccess(allowAutoRequest: true);
    final b = gate.ensureAccess(allowAutoRequest: true);
    final results = await Future.wait([a, b]);
    expect(results, everyElement(LocationAccessOutcome.ready));
    expect(source.requestPermissionCount, 1);
  });

  test('forceRequest re-prompts after denial for recovery CTA', () async {
    source.permission = LocationPermission.denied;
    await gate.ensureAccess(allowAutoRequest: true);
    expect(source.requestPermissionCount, 1);
    source.grantOnRequest = LocationPermission.whileInUse;
    final recovered = await gate.ensureAccess(
      allowAutoRequest: false,
      forceRequest: true,
    );
    expect(recovered, LocationAccessOutcome.ready);
    expect(source.requestPermissionCount, 2);
  });

  test('services disabled does not request permission', () async {
    source.serviceEnabled = false;
    final outcome = await gate.ensureAccess(allowAutoRequest: true);
    expect(outcome, LocationAccessOutcome.servicesDisabled);
    expect(source.requestPermissionCount, 0);
  });

  test('reset clears auto-request latch for a new session', () async {
    source.grantOnRequest = LocationPermission.whileInUse;
    await gate.ensureAccess(allowAutoRequest: true);
    gate.reset();
    gate.arm();
    source.permission = LocationPermission.denied;
    source.grantOnRequest = LocationPermission.whileInUse;
    await gate.ensureAccess(allowAutoRequest: true);
    expect(source.requestPermissionCount, 2);
  });
}
