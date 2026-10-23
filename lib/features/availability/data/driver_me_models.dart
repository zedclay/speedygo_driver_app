/// Mirrors `DriverMeResponseDto` / availability subset from Backend.
class DriverAvailabilityInfo {
  const DriverAvailabilityInfo({
    required this.status,
    required this.offlineAfterCurrentDelivery,
    required this.updatedAt,
  });

  final String status;
  final bool offlineAfterCurrentDelivery;
  final String updatedAt;

  bool get isOnline => status == 'ONLINE';
  bool get isOffline => status == 'OFFLINE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get isOfflineAfterCurrent => status == 'OFFLINE_AFTER_CURRENT_DELIVERY';

  factory DriverAvailabilityInfo.fromJson(Map<String, dynamic> json) {
    return DriverAvailabilityInfo(
      status: json['status']?.toString() ?? 'OFFLINE',
      offlineAfterCurrentDelivery: json['offlineAfterCurrentDelivery'] == true,
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

/// Metadata-only document row (`present` = a metadata row exists).
class DriverDocumentInfo {
  const DriverDocumentInfo({
    required this.type,
    required this.present,
    this.expiryDate,
  });

  final String type;
  final bool present;
  final String? expiryDate;

  factory DriverDocumentInfo.fromJson(Map<String, dynamic> json) {
    return DriverDocumentInfo(
      type: json['type']?.toString() ?? '',
      present: json['present'] == true,
      expiryDate: json['expiryDate']?.toString(),
    );
  }
}

class DriverVehicleInfo {
  const DriverVehicleInfo({
    required this.id,
    required this.type,
    required this.plateNumber,
    required this.model,
    required this.status,
    this.color,
  });

  final String id;
  final String type;
  final String plateNumber;
  final String model;
  final String status;
  final String? color;

  bool get isActive => status == 'ACTIVE';

  factory DriverVehicleInfo.fromJson(Map<String, dynamic> json) {
    return DriverVehicleInfo(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      color: json['color']?.toString(),
    );
  }
}

class DriverMe {
  const DriverMe({
    required this.driverProfileExists,
    required this.profileComplete,
    required this.identityDocumentComplete,
    required this.drivingLicenseComplete,
    required this.vehicleComplete,
    required this.verificationSubmitted,
    required this.verificationApproved,
    required this.operationalReady,
    required this.matchingEligible,
    required this.availability,
    this.profileFullName,
    this.verificationStatus,
    this.documents = const [],
    this.vehicles = const [],
  });

  final bool driverProfileExists;
  final bool profileComplete;
  final bool identityDocumentComplete;
  final bool drivingLicenseComplete;
  final bool vehicleComplete;
  final bool verificationSubmitted;
  final bool verificationApproved;
  final bool operationalReady;
  final bool matchingEligible;
  final DriverAvailabilityInfo? availability;
  final String? profileFullName;
  final String? verificationStatus;
  final List<DriverDocumentInfo> documents;
  final List<DriverVehicleInfo> vehicles;

  /// Onboarding data may only be edited while UNVERIFIED or REJECTED.
  bool get isOnboardingEditable =>
      verificationStatus == null ||
      verificationStatus == 'UNVERIFIED' ||
      verificationStatus == 'REJECTED';

  DriverDocumentInfo? documentOf(String type) {
    for (final doc in documents) {
      if (doc.type == type) return doc;
    }
    return null;
  }

  DriverVehicleInfo? get activeVehicle {
    for (final vehicle in vehicles) {
      if (vehicle.isActive) return vehicle;
    }
    return null;
  }

  bool get canAttemptGoOnline {
    if (!driverProfileExists || !operationalReady) return false;
    final status = availability?.status;
    return status == null || status == 'OFFLINE';
  }

  factory DriverMe.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final availability = json['availability'];
    return DriverMe(
      driverProfileExists: json['driverProfileExists'] == true,
      profileComplete: json['profileComplete'] == true,
      identityDocumentComplete: json['identityDocumentComplete'] == true,
      drivingLicenseComplete: json['drivingLicenseComplete'] == true,
      vehicleComplete: json['vehicleComplete'] == true,
      verificationSubmitted: json['verificationSubmitted'] == true,
      verificationApproved: json['verificationApproved'] == true,
      operationalReady: json['operationalReady'] == true,
      matchingEligible: json['matchingEligible'] == true,
      availability: availability is Map
          ? DriverAvailabilityInfo.fromJson(
              Map<String, dynamic>.from(availability),
            )
          : null,
      profileFullName: profile is Map ? profile['fullName']?.toString() : null,
      verificationStatus: profile is Map
          ? profile['verificationStatus']?.toString()
          : null,
      documents: json['documents'] is List
          ? (json['documents'] as List)
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) =>
                      DriverDocumentInfo.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
      vehicles: json['vehicles'] is List
          ? (json['vehicles'] as List)
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) =>
                      DriverVehicleInfo.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
    );
  }
}
