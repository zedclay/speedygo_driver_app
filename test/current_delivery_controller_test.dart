import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

DriverCurrentDelivery _delivery({
  String status = 'AT_PICKUP',
  List<String> actions = const ['confirm-pickup'],
  int version = 1,
}) {
  return DriverCurrentDelivery(
    assignmentId: 'asg-1',
    assignmentVersion: version,
    deliveryId: 'del-1',
    orderId: 'ord-1',
    deliveryStatus: status,
    orderStatus: 'ACTIVE',
    fulfillmentStatus: 'READY',
    assignmentStatus: 'ACCEPTED',
    allowedActions: actions,
    pickedUpAt: status == 'PICKED_UP' ? '2026-10-04T12:00:00.000Z' : null,
    arrivedCustomerAt: null,
    deliveredAt: null,
  );
}

void main() {
  late FakeDeliveryClient fake;
  late ProviderContainer container;

  setUp(() {
    fake = FakeDeliveryClient();
    container = ProviderContainer(
      overrides: [
        deliveryClientProvider.overrideWithValue(fake),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      ],
    );
  });

  tearDown(() => container.dispose());

  CurrentDeliveryController controller() =>
      container.read(currentDeliveryControllerProvider.notifier);

  CurrentDeliveryState state() =>
      container.read(currentDeliveryControllerProvider);

  test('load empty state', () async {
    fake.current = null;
    await controller().load();
    expect(state().loadStatus, DeliveryLoadStatus.empty);
    expect(state().delivery, isNull);
  });

  test('load AT_PICKUP ready state', () async {
    fake.current = _delivery();
    await controller().load();
    expect(state().loadStatus, DeliveryLoadStatus.ready);
    expect(state().delivery?.isAtPickup, isTrue);
    expect(state().canSubmit, isTrue); // legacy empty code allowed
  });

  test('incomplete code disables submit; 4 digits enables', () async {
    fake.current = _delivery();
    await controller().load();
    controller().updatePickupCode('12');
    expect(state().canSubmit, isFalse);
    controller().updatePickupCode('1234');
    expect(state().canSubmit, isTrue);
  });

  test(
    'successful coded confirmation clears code and updates status',
    () async {
      fake.current = _delivery();
      fake.confirmHandler = (body) async {
        expect(body.pickupCode, '0427');
        expect(body.assignmentId, 'asg-1');
        expect(body.assignmentVersion, 1);
        return _delivery(
          status: 'PICKED_UP',
          actions: const ['start-delivery'],
        );
      };
      await controller().load();
      controller().updatePickupCode('0427');
      await controller().confirmPickup();
      expect(fake.confirmCount, 1);
      expect(state().delivery?.deliveryStatus, 'PICKED_UP');
      expect(state().pickupCode, isEmpty);
      expect(state().successMessage, AppStrings.pickedUpSuccess);
      expect(state().submitting, isFalse);
    },
  );

  test('successful legacy confirmation sends empty body', () async {
    fake.current = _delivery();
    fake.confirmHandler = (body) async {
      expect(body.toJson(), isEmpty);
      return _delivery(status: 'PICKED_UP', actions: const ['start-delivery']);
    };
    await controller().load();
    await controller().confirmPickup();
    expect(fake.lastConfirmBody?.toJson(), isEmpty);
    expect(state().delivery?.isPickedUp, isTrue);
  });

  test('incorrect code keeps in-memory code', () async {
    fake.current = _delivery();
    fake.confirmHandler = (_) async {
      throw ApiException(
        AppStrings.codeInvalid,
        code: 'PICKUP_HANDOFF_CODE_INVALID',
        statusCode: 409,
      );
    };
    await controller().load();
    controller().updatePickupCode('9999');
    await controller().confirmPickup();
    expect(state().pickupCode, '9999');
    expect(state().errorCode, 'PICKUP_HANDOFF_CODE_INVALID');
    expect(state().errorMessage, AppStrings.codeInvalid);
  });

  test('expired code mapping', () async {
    fake.current = _delivery();
    fake.confirmHandler = (_) async {
      throw ApiException(
        AppStrings.codeExpired,
        code: 'PICKUP_HANDOFF_EXPIRED',
        statusCode: 409,
      );
    };
    await controller().load();
    controller().updatePickupCode('1234');
    await controller().confirmPickup();
    expect(state().errorMessage, AppStrings.codeExpired);
    expect(state().pickupCode, '1234');
  });

  test('locked handoff mapping', () async {
    fake.current = _delivery();
    fake.confirmHandler = (_) async {
      throw ApiException(
        AppStrings.codeLocked,
        code: 'PICKUP_HANDOFF_LOCKED',
        statusCode: 429,
      );
    };
    await controller().load();
    controller().updatePickupCode('1234');
    await controller().confirmPickup();
    expect(state().errorMessage, AppStrings.codeLocked);
  });

  test('inactive assignment clears code and reloads', () async {
    fake.current = _delivery();
    var confirmCalls = 0;
    fake.confirmHandler = (_) async {
      confirmCalls += 1;
      throw ApiException(
        AppStrings.assignmentInactive,
        code: 'DRIVER_DELIVERY_ASSIGNMENT_NOT_ACTIVE',
        statusCode: 409,
      );
    };
    await controller().load();
    controller().updatePickupCode('1234');
    final loadsBefore = fake.getCurrentCount;
    await controller().confirmPickup();
    expect(confirmCalls, 1);
    expect(state().pickupCode, isEmpty);
    expect(fake.getCurrentCount, greaterThan(loadsBefore));
  });

  test('invalid delivery state refreshes current delivery', () async {
    fake.current = _delivery();
    fake.confirmHandler = (_) async {
      throw ApiException(
        AppStrings.invalidState,
        code: 'DRIVER_DELIVERY_INVALID_STATE',
        statusCode: 409,
      );
    };
    await controller().load();
    controller().updatePickupCode('1234');
    final loadsBefore = fake.getCurrentCount;
    await controller().confirmPickup();
    expect(state().errorMessage, AppStrings.invalidState);
    expect(state().pickupCode, '1234');
    expect(fake.getCurrentCount, greaterThan(loadsBefore));
  });

  test('network failure preserves code for retry', () async {
    fake.current = _delivery();
    fake.confirmHandler = (_) async {
      throw NetworkException(AppStrings.networkError, code: 'NETWORK');
    };
    await controller().load();
    controller().updatePickupCode('5555');
    await controller().confirmPickup();
    expect(state().pickupCode, '5555');
    expect(state().errorMessage, AppStrings.networkError);
    expect(state().submitting, isFalse);
  });

  test('duplicate submit prevention while in-flight', () async {
    fake.current = _delivery();
    var started = 0;
    fake.confirmHandler = (_) async {
      started += 1;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return _delivery(status: 'PICKED_UP', actions: const ['start-delivery']);
    };
    await controller().load();
    final first = controller().confirmPickup();
    final second = controller().confirmPickup();
    await Future.wait([first, second]);
    expect(started, 1);
  });

  test('digits-only clipping of pickup code', () async {
    fake.current = _delivery();
    await controller().load();
    controller().updatePickupCode('12ab34xx99');
    expect(state().pickupCode, '1234');
  });
}
