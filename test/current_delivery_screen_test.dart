import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/delivery/application/current_delivery_controller.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_api.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';
import 'package:speedygo_driver_app/features/delivery/presentation/current_delivery_screen.dart';

DriverCurrentDelivery atPickup() => const DriverCurrentDelivery(
  assignmentId: 'asg-1',
  assignmentVersion: 1,
  deliveryId: 'del-1',
  orderId: 'ord-1',
  deliveryStatus: 'AT_PICKUP',
  orderStatus: 'ACTIVE',
  fulfillmentStatus: 'READY',
  assignmentStatus: 'ACCEPTED',
  allowedActions: ['confirm-pickup'],
  pickedUpAt: null,
  arrivedCustomerAt: null,
  deliveredAt: null,
);

Widget _harness(FakeDeliveryClient fake) {
  return ProviderScope(
    overrides: [
      deliveryClientProvider.overrideWithValue(fake),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
    ],
    child: const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(390, 844)),
        child: CurrentDeliveryScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('empty state at 390x844', (tester) async {
    final fake = FakeDeliveryClient(current: null);
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deliveryEmpty), findsOneWidget);
    expect(find.byKey(const Key('delivery_empty_retry')), findsOneWidget);
  });

  testWidgets('AT_PICKUP shows code entry and confirm CTA', (tester) async {
    final fake = FakeDeliveryClient(current: atPickup());
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deliveryStatusFr('AT_PICKUP')), findsOneWidget);
    expect(find.byKey(const Key('pickup_code_field')), findsOneWidget);
    expect(find.byKey(const Key('confirm_pickup_button')), findsOneWidget);
  });

  testWidgets('coded confirm success transitions UI', (tester) async {
    final fake = FakeDeliveryClient(
      current: atPickup(),
      confirmHandler: (_) async => const DriverCurrentDelivery(
        assignmentId: 'asg-1',
        assignmentVersion: 1,
        deliveryId: 'del-1',
        orderId: 'ord-1',
        deliveryStatus: 'PICKED_UP',
        orderStatus: 'ACTIVE',
        fulfillmentStatus: 'READY',
        assignmentStatus: 'ACCEPTED',
        allowedActions: ['start-delivery'],
        pickedUpAt: 't',
        arrivedCustomerAt: null,
        deliveredAt: null,
      ),
    );
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pickup_code_field')), '0427');
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm_pickup_button')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.pickedUpSuccess), findsOneWidget);
    expect(find.text(AppStrings.deliveryStatusFr('PICKED_UP')), findsWidgets);
    expect(find.byKey(const Key('pickup_code_field')), findsNothing);
  });

  testWidgets('invalid code banner with text scale 1.3', (tester) async {
    final fake = FakeDeliveryClient(
      current: atPickup(),
      confirmHandler: (_) async {
        throw ApiException(
          AppStrings.codeInvalid,
          code: 'PICKUP_HANDOFF_CODE_INVALID',
        );
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryClientProvider.overrideWithValue(fake),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(1.3),
            ),
            child: CurrentDeliveryScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pickup_code_field')), '0000');
    await tester.tap(find.byKey(const Key('confirm_pickup_button')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.codeInvalid), findsOneWidget);
  });

  testWidgets('confirm button stays visible with viewInsets keyboard', (
    tester,
  ) async {
    final fake = FakeDeliveryClient(current: atPickup());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryClientProvider.overrideWithValue(fake),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              viewInsets: EdgeInsets.only(bottom: 280),
            ),
            child: CurrentDeliveryScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm_pickup_button')), findsOneWidget);
    final button = tester.getRect(
      find.byKey(const Key('confirm_pickup_button')),
    );
    expect(button.height, greaterThanOrEqualTo(48));
  });

  testWidgets('incomplete code disables confirm button', (tester) async {
    final fake = FakeDeliveryClient(current: atPickup());
    await tester.pumpWidget(_harness(fake));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pickup_code_field')), '12');
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('confirm_pickup_button')),
    );
    expect(button.onPressed, isNull);
  });
}
