import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/availability/data/device_location.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/current_delivery_screen.dart';

DriverCurrentDelivery _delivery(String status, List<String> actions) {
  return DriverCurrentDelivery(
    assignmentId: 'asg-1',
    assignmentVersion: 1,
    deliveryId: 'del-1',
    orderId: 'ord-1',
    deliveryStatus: status,
    orderStatus: 'ACTIVE',
    fulfillmentStatus: 'READY',
    assignmentStatus: 'ACCEPTED',
    allowedActions: actions,
    pickedUpAt: null,
    arrivedCustomerAt: null,
    deliveredAt: status == 'DELIVERED' ? '2026-10-09T12:00:00.000Z' : null,
  );
}

void main() {
  late FakeDeliveryClient delivery;
  late FakeAvailabilityClient availability;
  late FakeDeviceLocationSource location;
  late ProviderContainer container;

  List<Override> overrides() => [
    deliveryClientProvider.overrideWithValue(delivery),
    availabilityClientProvider.overrideWithValue(availability),
    deviceLocationSourceProvider.overrideWithValue(location),
    sessionStoreProvider.overrideWithValue(MemorySessionStore()),
  ];

  setUp(() {
    delivery = FakeDeliveryClient();
    availability = FakeAvailabilityClient();
    location = FakeDeviceLocationSource(
      position: const DevicePosition(latitude: 36.75, longitude: 3.06),
    );
    container = ProviderContainer(overrides: overrides());
  });

  tearDown(() => container.dispose());

  CurrentDeliveryController controller() =>
      container.read(currentDeliveryControllerProvider.notifier);
  CurrentDeliveryState state() =>
      container.read(currentDeliveryControllerProvider);

  group('model helpers', () {
    test('can* flags derive from allowedActions', () {
      final d = _delivery('TO_PICKUP', ['arrive-pickup']);
      expect(d.canArrivePickup, isTrue);
      expect(d.canStartToPickup, isFalse);
      expect(d.canStartDelivery, isFalse);
      expect(d.canArriveCustomer, isFalse);
      expect(d.canCompleteDelivery, isFalse);
      expect(d.canCollectCod, isFalse);
    });

    test('collect COD is offered only at ARRIVED_CUSTOMER', () {
      final d = _delivery('ARRIVED_CUSTOMER', ['complete-delivery']);
      expect(d.canCollectCod, isTrue);
      expect(d.canCompleteDelivery, isTrue);
      expect(
        _delivery('IN_TRANSIT', ['arrive-customer']).canCollectCod,
        isFalse,
      );
    });
  });

  group('performAction', () {
    test('start-to-pickup posts the exact path and applies the view', () async {
      delivery.current = _delivery('DRIVER_ASSIGNED', ['start-to-pickup']);
      delivery.actionHandler = (_) async =>
          _delivery('TO_PICKUP', ['arrive-pickup']);
      await controller().load();
      await controller().performAction(DeliveryActions.startToPickup);
      expect(delivery.lastActionPath, ApiEndpoints.driverStartToPickupPath);
      expect(state().delivery?.deliveryStatus, 'TO_PICKUP');
      expect(state().busyAction, isNull);
      // No location needed for start-to-pickup.
      expect(availability.publishCount, 0);
    });

    test('arrive-pickup publishes location first, then posts', () async {
      delivery.current = _delivery('TO_PICKUP', ['arrive-pickup']);
      delivery.actionHandler = (_) async =>
          _delivery('AT_PICKUP', ['confirm-pickup']);
      await controller().load();
      await controller().performAction(DeliveryActions.arrivePickup);
      expect(availability.publishCount, 1);
      expect(availability.lastLocation?.latitude, 36.75);
      expect(delivery.lastActionPath, ApiEndpoints.driverArrivePickupPath);
      expect(state().delivery?.isAtPickup, isTrue);
    });

    test('arrive-customer also publishes location', () async {
      delivery.current = _delivery('IN_TRANSIT', ['arrive-customer']);
      delivery.actionHandler = (_) async =>
          _delivery('ARRIVED_CUSTOMER', ['complete-delivery']);
      await controller().load();
      await controller().performAction(DeliveryActions.arriveCustomer);
      expect(availability.publishCount, 1);
      expect(delivery.lastActionPath, ApiEndpoints.driverArriveCustomerPath);
      expect(state().delivery?.isArrivedCustomer, isTrue);
    });

    test('device location failure aborts the action with a message', () async {
      location.failure = DeviceLocationFailure.permissionDenied;
      delivery.current = _delivery('TO_PICKUP', ['arrive-pickup']);
      await controller().load();
      await controller().performAction(DeliveryActions.arrivePickup);
      expect(delivery.actionCount, 0);
      expect(state().errorMessage, AppStrings.locationPermissionDenied);
      expect(state().busyAction, isNull);
    });

    test('server proximity error is surfaced and delivery is kept', () async {
      delivery.current = _delivery('TO_PICKUP', ['arrive-pickup']);
      delivery.actionHandler = (_) async => throw ApiException(
        AppStrings.errorForCode('DRIVER_DELIVERY_NOT_NEAR_PICKUP'),
        code: 'DRIVER_DELIVERY_NOT_NEAR_PICKUP',
      );
      await controller().load();
      await controller().performAction(DeliveryActions.arrivePickup);
      expect(state().errorCode, 'DRIVER_DELIVERY_NOT_NEAR_PICKUP');
      expect(state().delivery?.deliveryStatus, 'TO_PICKUP');
      expect(state().busyAction, isNull);
    });

    test('actions not in allowedActions are ignored', () async {
      delivery.current = _delivery('IN_TRANSIT', ['arrive-customer']);
      await controller().load();
      await controller().performAction(DeliveryActions.completeDelivery);
      expect(delivery.actionCount, 0);
    });

    test('confirm-pickup keeps the handoff path', () async {
      delivery.current = _delivery('AT_PICKUP', ['confirm-pickup']);
      delivery.confirmHandler = (_) async =>
          _delivery('PICKED_UP', ['start-delivery']);
      await controller().load();
      await controller().performAction(DeliveryActions.confirmPickup);
      expect(delivery.confirmCount, 1);
      expect(delivery.actionCount, 0);
      expect(state().delivery?.deliveryStatus, 'PICKED_UP');
    });

    test('complete-delivery success shows DELIVERED view', () async {
      delivery.current = _delivery('ARRIVED_CUSTOMER', ['complete-delivery']);
      delivery.actionHandler = (_) async => _delivery('DELIVERED', const []);
      await controller().load();
      await controller().performAction(DeliveryActions.completeDelivery);
      expect(delivery.lastActionPath, ApiEndpoints.driverCompleteDeliveryPath);
      expect(state().delivery?.isDelivered, isTrue);
      expect(state().successMessage, AppStrings.deliveredSuccess);
      // A follow-up load (server returns null) keeps the DELIVERED view…
      delivery.current = null;
      await controller().load();
      expect(state().delivery?.isDelivered, isTrue);
      // …until the driver acknowledges it.
      controller().reset();
      expect(state().delivery, isNull);
    });

    test('COD completion not ready is surfaced as a COD hint', () async {
      delivery.current = _delivery('ARRIVED_CUSTOMER', ['complete-delivery']);
      delivery.actionHandler = (_) async => throw ApiException(
        AppStrings.errorForCode('DRIVER_DELIVERY_COD_COMPLETION_NOT_READY'),
        code: 'DRIVER_DELIVERY_COD_COMPLETION_NOT_READY',
      );
      await controller().load();
      await controller().performAction(DeliveryActions.completeDelivery);
      expect(state().errorCode, 'DRIVER_DELIVERY_COD_COMPLETION_NOT_READY');
      expect(
        state().errorMessage,
        AppStrings.errorForCode('DRIVER_DELIVERY_COD_COMPLETION_NOT_READY'),
      );
      expect(state().delivery?.isArrivedCustomer, isTrue);
    });
  });

  group('collectCod', () {
    setUp(() async {
      delivery.current = _delivery('ARRIVED_CUSTOMER', ['complete-delivery']);
      await controller().load();
    });

    test('amount input is digits only and parsed as integer minor units', () {
      controller().updateCodAmount('12a00');
      expect(state().codAmountInput, '1200');
      expect(state().codAmountMinor, 1200);
      expect(state().canCollectCod, isTrue);
      controller().updateCodAmount('');
      expect(state().canCollectCod, isFalse);
    });

    test('sends the exact integer to the server', () async {
      await controller().collectCod(1200);
      expect(delivery.lastCollectedAmountMinor, 1200);
      expect(state().codCollected, isTrue);
      expect(state().successMessage, AppStrings.codCollectedSuccess);
    });

    test(
      'exact-amount mismatch is surfaced and nothing is collected',
      () async {
        delivery.collectCodHandler = (_) async => throw ApiException(
          AppStrings.errorForCode('DRIVER_COD_COLLECTION_AMOUNT_MISMATCH'),
          code: 'DRIVER_COD_COLLECTION_AMOUNT_MISMATCH',
        );
        await controller().collectCod(999);
        expect(state().codCollected, isFalse);
        expect(state().errorCode, 'DRIVER_COD_COLLECTION_AMOUNT_MISMATCH');
        expect(state().codBusy, isFalse);
      },
    );

    test('not offered before ARRIVED_CUSTOMER', () async {
      delivery.current = _delivery('IN_TRANSIT', ['arrive-customer']);
      await controller().load();
      await controller().collectCod(100);
      expect(delivery.collectCodCount, 0);
    });
  });

  group('current delivery screen', () {
    Widget harness(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      return ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: CurrentDeliveryScreen()),
      );
    }

    testWidgets('PICKED_UP shows start-delivery as the sticky action', (
      tester,
    ) async {
      delivery.current = _delivery('PICKED_UP', ['start-delivery']);
      await tester.pumpWidget(harness(tester));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('delivery_action_start-delivery')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('pickup_code_field')), findsNothing);
      expect(find.byKey(const Key('cod_card')), findsNothing);
      // Provider-neutral nav card is honest: no address/maps from the server.
      expect(find.byKey(const Key('nav_unavailable')), findsOneWidget);
      expect(find.text(AppStrings.navUnavailable), findsOneWidget);
    });

    testWidgets('ARRIVED_CUSTOMER shows COD form and complete action', (
      tester,
    ) async {
      delivery.current = _delivery('ARRIVED_CUSTOMER', ['complete-delivery']);
      delivery.actionHandler = (_) async => _delivery('DELIVERED', const []);
      await tester.pumpWidget(harness(tester));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cod_card')), findsOneWidget);
      expect(
        find.byKey(const Key('delivery_action_complete-delivery')),
        findsOneWidget,
      );
      final collect = tester.widget<OutlinedButton>(
        find.byKey(const Key('cod_collect_button')),
      );
      expect(collect.onPressed, isNull);

      await tester.enterText(find.byKey(const Key('cod_amount_field')), '1200');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('cod_collect_button')));
      // Live regression: collect must sit above the sticky complete bar.
      final collectTop = tester
          .getTopLeft(find.byKey(const Key('cod_collect_button')))
          .dy;
      final stickyTop = tester
          .getTopLeft(
            find.byKey(const Key('delivery_action_complete-delivery')),
          )
          .dy;
      expect(collectTop, lessThan(stickyTop));
      await tester.tap(find.byKey(const Key('cod_collect_button')));
      await tester.pumpAndSettle();
      expect(delivery.lastCollectedAmountMinor, 1200);
      expect(find.text(AppStrings.codCollectedSuccess), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('delivery_action_complete-delivery')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('delivered_banner')), findsOneWidget);
      expect(find.byKey(const Key('delivery_done_back')), findsOneWidget);
      expect(find.byKey(const Key('cod_card')), findsNothing);
    });

    testWidgets('no allowed action means no sticky bar', (tester) async {
      delivery.current = _delivery('IN_TRANSIT', const []);
      await tester.pumpWidget(harness(tester));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
