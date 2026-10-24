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

    test('parses captured dropoff details and skips empty labels', () {
      final delivery = DriverCurrentDelivery.fromJson({
        'assignmentId': 'a1',
        'assignmentVersion': 1,
        'deliveryId': 'd1',
        'orderId': 'o1',
        'deliveryStatus': 'IN_TRANSIT',
        'orderStatus': 'ACTIVE',
        'fulfillmentStatus': 'READY',
        'assignmentStatus': 'ACCEPTED',
        'allowedActions': ['arrive-customer'],
        'pickedUpAt': '2026-10-23T12:00:00.000Z',
        'arrivedCustomerAt': null,
        'deliveredAt': null,
        'dropoffAddressText': 'Cité 1500 Logements',
        'dropoffBuilding': 'Bloc Z',
        'dropoffFloor': '  ',
        'dropoffEntrance': null,
        'dropoffLandmark': 'Mosquée',
        'dropoffInstructions': '',
      });
      final rows = delivery.visibleDropoffDetails(
        buildingLabel: 'Bâtiment',
        floorLabel: 'Étage',
        entranceLabel: 'Entrée',
        landmarkLabel: 'Point de repère',
      );
      expect(delivery.dropoffAddressText, 'Cité 1500 Logements');
      expect(rows.map((row) => row.label).toList(), [
        'Bâtiment',
        'Point de repère',
      ]);
      expect(rows.map((row) => row.value).toList(), ['Bloc Z', 'Mosquée']);
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
