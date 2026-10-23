import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';

void main() {
  test('maps DriverMe availability ONLINE and matchingEligible', () {
    final me = DriverMe.fromJson({
      'driverProfileExists': true,
      'profileComplete': true,
      'identityDocumentComplete': true,
      'drivingLicenseComplete': true,
      'vehicleComplete': true,
      'verificationSubmitted': true,
      'verificationApproved': true,
      'operationalReady': true,
      'matchingEligible': true,
      'profile': {
        'id': 'p1',
        'fullName': 'Amine',
        'verificationStatus': 'APPROVED',
        'approvedAt': 't',
        'createdAt': 't',
        'updatedAt': 't',
      },
      'documents': <dynamic>[],
      'vehicles': <dynamic>[],
      'availability': {
        'status': 'ONLINE',
        'offlineAfterCurrentDelivery': false,
        'updatedAt': 't',
      },
    });
    expect(me.availability?.isOnline, isTrue);
    expect(me.matchingEligible, isTrue);
    expect(me.canAttemptGoOnline, isFalse);
    AppStrings.bind('fr');
    expect(AppStrings.availabilityStatusLabel('ONLINE'), 'En ligne');
  });

  test('maps OFFLINE canAttemptGoOnline when operational', () {
    final me = DriverMe.fromJson({
      'driverProfileExists': true,
      'profileComplete': true,
      'identityDocumentComplete': true,
      'drivingLicenseComplete': true,
      'vehicleComplete': true,
      'verificationSubmitted': true,
      'verificationApproved': true,
      'operationalReady': true,
      'matchingEligible': false,
      'profile': {'fullName': 'Amine', 'verificationStatus': 'APPROVED'},
      'documents': <dynamic>[],
      'vehicles': <dynamic>[],
      'availability': {
        'status': 'OFFLINE',
        'offlineAfterCurrentDelivery': false,
        'updatedAt': 't',
      },
    });
    expect(me.canAttemptGoOnline, isTrue);
  });

  test('offer DTO keeps only authorized pre-accept fields', () {
    final offer = AssignmentOffer.fromJson({
      'assignmentId': 'a1',
      'deliveryId': 'd1',
      'orderPublicReference': 'SG-100',
      'status': 'OFFERED',
      'offeredAt': '2026-10-09T12:00:00.000Z',
      'expiresAt': '2026-10-09T12:00:30.000Z',
      'driverRemunerationMinor': '300',
      'pickup': {'name': 'Café Atlas'},
      'pickupDistanceMeters': 420,
      'deliveryDistanceMeters': 2100,
    });
    expect(offer.pickupName, 'Café Atlas');
    expect(offer.pickupDistanceMeters, 420);
    expect(offer.deliveryDistanceMeters, 2100);
    expect(offer.expiresAtUtc, isNotNull);
  });
}
