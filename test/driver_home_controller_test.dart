import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/driver_home_controller.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

DriverMe _me({
  String availability = 'OFFLINE',
  bool operationalReady = true,
  bool matchingEligible = false,
  bool profileExists = true,
  String verification = 'APPROVED',
}) {
  return DriverMe(
    driverProfileExists: profileExists,
    profileComplete: true,
    identityDocumentComplete: true,
    drivingLicenseComplete: true,
    vehicleComplete: true,
    verificationSubmitted: true,
    verificationApproved: verification == 'APPROVED',
    operationalReady: operationalReady,
    matchingEligible: matchingEligible,
    profileFullName: 'Amine',
    verificationStatus: verification,
    availability: DriverAvailabilityInfo(
      status: availability,
      offlineAfterCurrentDelivery:
          availability == 'OFFLINE_AFTER_CURRENT_DELIVERY',
      updatedAt: 't',
    ),
  );
}

AssignmentOffer _offer({
  String id = 'asg-offer',
  String expiresAt = '2099-01-01T00:00:30.000Z',
}) {
  return AssignmentOffer(
    assignmentId: id,
    deliveryId: 'del-1',
    orderPublicReference: 'SG-42',
    status: 'OFFERED',
    offeredAt: '2099-01-01T00:00:00.000Z',
    expiresAt: expiresAt,
    driverRemunerationMinor: '300',
    pickupName: 'Café Atlas',
    pickupDistanceMeters: 350,
    deliveryDistanceMeters: 1200,
  );
}

void main() {
  late FakeAvailabilityClient availability;
  late FakeDeliveryClient delivery;
  late FakeDeviceLocationSource location;
  late ProviderContainer container;

  setUp(() {
    AppStrings.bind('fr');
    availability = FakeAvailabilityClient(me: _me());
    delivery = FakeDeliveryClient(current: null);
    location = FakeDeviceLocationSource(
      position: const DevicePosition(
        latitude: 36.75,
        longitude: 3.06,
        accuracyMeters: 12,
      ),
    );
    container = ProviderContainer(
      overrides: [
        availabilityClientProvider.overrideWithValue(availability),
        deliveryClientProvider.overrideWithValue(delivery),
        deviceLocationSourceProvider.overrideWithValue(location),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      ],
    );
  });

  tearDown(() => container.dispose());

  DriverHomeController ctl() =>
      container.read(driverHomeControllerProvider.notifier);
  DriverHomeState st() => container.read(driverHomeControllerProvider);

  test('maps server availability state on bootstrap', () async {
    availability.me = _me(availability: 'OFFLINE');
    await ctl().bootstrap();
    expect(st().loadStatus, DriverHomeLoadStatus.ready);
    expect(st().me?.availability?.status, 'OFFLINE');
    expect(st().isOnline, isFalse);
  });

  test('successful online transition waits for server me', () async {
    availability.me = _me();
    availability.goOnlineHandler = () async =>
        _me(availability: 'ONLINE', matchingEligible: true);
    await ctl().bootstrap();
    await ctl().goOnline();
    expect(availability.goOnlineCount, 1);
    expect(st().isOnline, isTrue);
    expect(st().availabilityBusy, isFalse);
    expect(availability.publishCount, greaterThanOrEqualTo(1));
  });

  test(
    'successful offline transition clears offer and stops as offline',
    () async {
      availability.me = _me(availability: 'ONLINE', matchingEligible: true);
      availability.goOfflineHandler = () async => _me();
      await ctl().bootstrap();
      availability.offer = _offer();
      await ctl().refresh(full: false);
      expect(st().offer, isNotNull);
      await ctl().goOffline();
      expect(availability.goOfflineCount, 1);
      expect(st().isOnline, isFalse);
      expect(st().offer, isNull);
    },
  );

  test('duplicate toggle prevention while busy', () async {
    availability.me = _me();
    var release = false;
    availability.goOnlineHandler = () async {
      while (!release) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return _me(availability: 'ONLINE', matchingEligible: true);
    };
    await ctl().bootstrap();
    final first = ctl().goOnline();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await ctl().goOnline();
    expect(availability.goOnlineCount, 1);
    release = true;
    await first;
  });

  test('location services disabled surfaces message after online', () async {
    availability.me = _me();
    availability.goOnlineHandler = () async =>
        _me(availability: 'ONLINE', matchingEligible: true);
    location.serviceEnabled = false;
    location.failure = DeviceLocationFailure.servicesDisabled;
    await ctl().bootstrap();
    await ctl().goOnline();
    expect(st().isOnline, isTrue);
    expect(st().locationStatus, LocationUiStatus.servicesDisabled);
    expect(st().locationMessage, AppStrings.locationServicesDisabled);
  });

  test('permission denied surfaces message', () async {
    availability.me = _me();
    availability.goOnlineHandler = () async =>
        _me(availability: 'ONLINE', matchingEligible: true);
    location.permission = LocationPermission.denied;
    location.failure = DeviceLocationFailure.permissionDenied;
    await ctl().bootstrap();
    await ctl().goOnline();
    expect(st().locationStatus, LocationUiStatus.permissionDenied);
  });

  test('permission denied forever surfaces message', () async {
    availability.me = _me();
    availability.goOnlineHandler = () async =>
        _me(availability: 'ONLINE', matchingEligible: true);
    location.permission = LocationPermission.deniedForever;
    location.failure = DeviceLocationFailure.permissionDeniedForever;
    await ctl().bootstrap();
    await ctl().goOnline();
    expect(st().locationStatus, LocationUiStatus.permissionDeniedForever);
  });

  test('location timeout surfaces on publish before accept', () async {
    availability.me = _me(availability: 'ONLINE', matchingEligible: true);
    availability.offer = _offer();
    availability.acceptHandler = (_) async {};
    await ctl().bootstrap();
    location.failure = DeviceLocationFailure.timeout;
    await ctl().acceptOffer();
    expect(st().locationStatus, LocationUiStatus.timeout);
    expect(st().locationMessage, AppStrings.locationTimeout);
  });

  test('empty online waiting state has no offer', () async {
    availability.me = _me(availability: 'ONLINE', matchingEligible: true);
    availability.offer = null;
    await ctl().bootstrap();
    expect(st().isOnline, isTrue);
    expect(st().offer, isNull);
    expect(st().hasActiveDelivery, isFalse);
  });

  test('accept success clears offer and flags navigation', () async {
    availability.me = _me(availability: 'ONLINE', matchingEligible: true);
    availability.offer = _offer();
    availability.acceptHandler = (_) async {};
    delivery.current = null;
    await ctl().bootstrap();
    expect(st().offer, isNotNull);
    delivery.current = const DriverCurrentDelivery(
      assignmentId: 'asg-offer',
      assignmentVersion: 1,
      deliveryId: 'del-1',
      orderId: 'ord-1',
      deliveryStatus: 'DRIVER_ASSIGNED',
      orderStatus: 'ACTIVE',
      fulfillmentStatus: 'READY',
      assignmentStatus: 'ACCEPTED',
      allowedActions: ['start-to-pickup'],
      pickedUpAt: null,
      arrivedCustomerAt: null,
      deliveredAt: null,
    );
    await ctl().acceptOffer();
    expect(availability.acceptCount, 1);
    expect(st().offer, isNull);
    expect(st().acceptedNavigationPending, isTrue);
    expect(st().hasActiveDelivery, isTrue);
  });

  test('reject success clears offer', () async {
    availability.me = _me(availability: 'ONLINE', matchingEligible: true);
    availability.offer = _offer();
    availability.rejectHandler = (_) async {
      availability.offer = null;
    };
    await ctl().bootstrap();
    await ctl().rejectOffer();
    expect(availability.rejectCount, 1);
    expect(st().offer, isNull);
  });

  test('accept/reject double-submit prevention', () async {
    availability.me = _me(availability: 'ONLINE', matchingEligible: true);
    availability.offer = _offer();
    var release = false;
    availability.acceptHandler = (_) async {
      while (!release) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    };
    await ctl().bootstrap();
    final first = ctl().acceptOffer();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await ctl().acceptOffer();
    await ctl().rejectOffer();
    expect(availability.acceptCount, 1);
    expect(availability.rejectCount, 0);
    release = true;
    await first;
  });

  test('stale or already-taken offer refreshes state', () async {
    availability.me = _me(availability: 'ONLINE', matchingEligible: true);
    availability.offer = _offer();
    availability.acceptHandler = (_) async {
      throw ApiException(
        AppStrings.offerTakenOrStale,
        code: 'DRIVER_ASSIGNMENT_INVALID_STATE',
        statusCode: 409,
      );
    };
    await ctl().bootstrap();
    availability.offer = null;
    await ctl().acceptOffer();
    expect(st().errorCode, 'DRIVER_ASSIGNMENT_INVALID_STATE');
    expect(st().offer, isNull);
  });

  test('network failure surfaces retryable error', () async {
    availability.me = _me();
    availability.goOnlineHandler = () async {
      throw NetworkException(AppStrings.networkError, code: 'NETWORK');
    };
    await ctl().bootstrap();
    await ctl().goOnline();
    expect(st().errorCode, 'NETWORK');
    expect(st().isOnline, isFalse);
  });

  test('logout clears home state and stops timers', () async {
    availability.me = _me(availability: 'ONLINE', matchingEligible: true);
    availability.offer = _offer();
    await ctl().bootstrap();
    expect(st().offer, isNotNull);
    container.read(sessionControllerProvider.notifier).markSignedOut();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(st().me, isNull);
    expect(st().offer, isNull);
  });

  test('expired offer blocks accept without submitting', () async {
    availability.me = _me(availability: 'ONLINE', matchingEligible: true);
    availability.offer = _offer(expiresAt: '2000-01-01T00:00:00.000Z');
    await ctl().bootstrap();
    await ctl().acceptOffer();
    expect(availability.acceptCount, 0);
    expect(st().offerExpiredLocally, isTrue);
  });
}
