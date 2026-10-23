/// Mirrors `AssignmentOfferResponseDto` — pre-accept privacy boundary.
class AssignmentOffer {
  const AssignmentOffer({
    required this.assignmentId,
    required this.deliveryId,
    required this.orderPublicReference,
    required this.status,
    required this.offeredAt,
    required this.expiresAt,
    required this.driverRemunerationMinor,
    required this.pickupName,
    required this.pickupDistanceMeters,
    this.deliveryDistanceMeters,
  });

  final String assignmentId;
  final String deliveryId;
  final String orderPublicReference;
  final String status;
  final String offeredAt;
  final String expiresAt;
  final String driverRemunerationMinor;
  final String pickupName;
  final int pickupDistanceMeters;
  final int? deliveryDistanceMeters;

  DateTime? get expiresAtUtc => DateTime.tryParse(expiresAt)?.toUtc();

  factory AssignmentOffer.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickup'];
    final pickupName = pickup is Map ? pickup['name']?.toString() ?? '' : '';
    final pickupDistance = json['pickupDistanceMeters'];
    final deliveryDistance = json['deliveryDistanceMeters'];
    return AssignmentOffer(
      assignmentId: json['assignmentId']?.toString() ?? '',
      deliveryId: json['deliveryId']?.toString() ?? '',
      orderPublicReference: json['orderPublicReference']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      offeredAt: json['offeredAt']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
      driverRemunerationMinor:
          json['driverRemunerationMinor']?.toString() ?? '0',
      pickupName: pickupName,
      pickupDistanceMeters: pickupDistance is int
          ? pickupDistance
          : int.tryParse('$pickupDistance') ?? 0,
      deliveryDistanceMeters: deliveryDistance == null
          ? null
          : (deliveryDistance is int
                ? deliveryDistance
                : int.tryParse('$deliveryDistance')),
    );
  }
}

class DriverLocationPublishResult {
  const DriverLocationPublishResult({
    required this.driverId,
    required this.recordedAt,
    required this.applied,
  });

  final String driverId;
  final String recordedAt;
  final bool applied;

  factory DriverLocationPublishResult.fromJson(Map<String, dynamic> json) {
    return DriverLocationPublishResult(
      driverId: json['driverId']?.toString() ?? '',
      recordedAt: json['recordedAt']?.toString() ?? '',
      applied: json['applied'] == true,
    );
  }
}

class DriverLocationUpdate {
  const DriverLocationUpdate({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'latitude': latitude, 'longitude': longitude};
    if (accuracyMeters != null) {
      map['accuracyMeters'] = accuracyMeters;
    }
    return map;
  }
}
