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
    );
  }
}
