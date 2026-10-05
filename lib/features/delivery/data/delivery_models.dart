class DriverCurrentDelivery {
  const DriverCurrentDelivery({
    required this.assignmentId,
    required this.assignmentVersion,
    required this.deliveryId,
    required this.orderId,
    required this.deliveryStatus,
    required this.orderStatus,
    required this.fulfillmentStatus,
    required this.assignmentStatus,
    required this.allowedActions,
    required this.pickedUpAt,
    required this.arrivedCustomerAt,
    required this.deliveredAt,
  });

  final String assignmentId;
  final int assignmentVersion;
  final String deliveryId;
  final String orderId;
  final String deliveryStatus;
  final String orderStatus;
  final String fulfillmentStatus;
  final String assignmentStatus;
  final List<String> allowedActions;
  final String? pickedUpAt;
  final String? arrivedCustomerAt;
  final String? deliveredAt;

  bool get canConfirmPickup => allowedActions.contains('confirm-pickup');

  bool get isAtPickup => deliveryStatus == 'AT_PICKUP';

  bool get isPickedUp =>
      deliveryStatus == 'PICKED_UP' ||
      deliveryStatus == 'IN_TRANSIT' ||
      deliveryStatus == 'ARRIVED_CUSTOMER' ||
      deliveryStatus == 'DELIVERED';

  factory DriverCurrentDelivery.fromJson(Map<String, dynamic> json) {
    final actions = json['allowedActions'];
    return DriverCurrentDelivery(
      assignmentId: json['assignmentId']?.toString() ?? '',
      assignmentVersion: json['assignmentVersion'] is int
          ? json['assignmentVersion'] as int
          : int.tryParse('${json['assignmentVersion']}') ?? 1,
      deliveryId: json['deliveryId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      deliveryStatus: json['deliveryStatus']?.toString() ?? '',
      orderStatus: json['orderStatus']?.toString() ?? '',
      fulfillmentStatus: json['fulfillmentStatus']?.toString() ?? '',
      assignmentStatus: json['assignmentStatus']?.toString() ?? '',
      allowedActions: actions is List
          ? actions.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      pickedUpAt: json['pickedUpAt']?.toString(),
      arrivedCustomerAt: json['arrivedCustomerAt']?.toString(),
      deliveredAt: json['deliveredAt']?.toString(),
    );
  }
}

class ConfirmPickupRequest {
  const ConfirmPickupRequest({
    this.pickupCode,
    this.assignmentId,
    this.assignmentVersion,
  });

  final String? pickupCode;
  final String? assignmentId;
  final int? assignmentVersion;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (pickupCode != null && pickupCode!.isNotEmpty) {
      map['pickupCode'] = pickupCode;
    }
    if (assignmentId != null && assignmentId!.isNotEmpty) {
      map['assignmentId'] = assignmentId;
    }
    if (assignmentVersion != null) {
      map['assignmentVersion'] = assignmentVersion;
    }
    return map;
  }
}
