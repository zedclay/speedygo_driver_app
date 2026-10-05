import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

void main() {
  group('DriverCurrentDelivery', () {
    test('parses assignmentVersion and allowedActions', () {
      final delivery = DriverCurrentDelivery.fromJson({
        'assignmentId': 'a1',
        'assignmentVersion': 3,
        'deliveryId': 'd1',
        'orderId': 'o1',
        'deliveryStatus': 'AT_PICKUP',
        'orderStatus': 'ACTIVE',
        'fulfillmentStatus': 'READY',
        'assignmentStatus': 'ACCEPTED',
        'allowedActions': ['confirm-pickup'],
        'pickedUpAt': null,
        'arrivedCustomerAt': null,
        'deliveredAt': null,
      });
      expect(delivery.assignmentVersion, 3);
      expect(delivery.canConfirmPickup, isTrue);
      expect(delivery.isAtPickup, isTrue);
    });

    test('confirm request omits empty legacy body fields', () {
      expect(const ConfirmPickupRequest().toJson(), isEmpty);
      expect(
        const ConfirmPickupRequest(
          pickupCode: '0427',
          assignmentId: 'a1',
          assignmentVersion: 1,
        ).toJson(),
        {'pickupCode': '0427', 'assignmentId': 'a1', 'assignmentVersion': 1},
      );
    });
  });
}
