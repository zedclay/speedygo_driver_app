class DeliveryActions {
  DeliveryActions._();

  static const startToPickup = 'start-to-pickup';
  static const arrivePickup = 'arrive-pickup';
  static const confirmPickup = 'confirm-pickup';
  static const startDelivery = 'start-delivery';
  static const arriveCustomer = 'arrive-customer';
  static const completeDelivery = 'complete-delivery';

  static const locationGated = <String>{arrivePickup, arriveCustomer};

  static const ordered = <String>[
    startToPickup,
    arrivePickup,
    confirmPickup,
    startDelivery,
    arriveCustomer,
    completeDelivery,
  ];
}

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
    this.expectedCodAmountMinor,
    this.dropoffAddressText,
    this.dropoffBuilding,
    this.dropoffFloor,
    this.dropoffEntrance,
    this.dropoffLandmark,
    this.dropoffInstructions,
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

  /// Authoritative COD due amount as integer minor units (decimal string).
  /// Null when payment is not COD or the field is omitted.
  final String? expectedCodAmountMinor;
  final String? dropoffAddressText;
  final String? dropoffBuilding;
  final String? dropoffFloor;
  final String? dropoffEntrance;
  final String? dropoffLandmark;
  final String? dropoffInstructions;

  List<({String label, String value})> visibleDropoffDetails({
    required String buildingLabel,
    required String floorLabel,
    required String entranceLabel,
    required String landmarkLabel,
  }) {
    return [
      if (_hasText(dropoffBuilding))
        (label: buildingLabel, value: dropoffBuilding!.trim()),
      if (_hasText(dropoffFloor))
        (label: floorLabel, value: dropoffFloor!.trim()),
      if (_hasText(dropoffEntrance))
        (label: entranceLabel, value: dropoffEntrance!.trim()),
      if (_hasText(dropoffLandmark))
        (label: landmarkLabel, value: dropoffLandmark!.trim()),
    ];
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  bool get canStartToPickup =>
      allowedActions.contains(DeliveryActions.startToPickup);
  bool get canArrivePickup =>
      allowedActions.contains(DeliveryActions.arrivePickup);
  bool get canConfirmPickup =>
      allowedActions.contains(DeliveryActions.confirmPickup);
  bool get canStartDelivery =>
      allowedActions.contains(DeliveryActions.startDelivery);
  bool get canArriveCustomer =>
      allowedActions.contains(DeliveryActions.arriveCustomer);
  bool get canCompleteDelivery =>
      allowedActions.contains(DeliveryActions.completeDelivery);

  /// COD is offered at customer arrival; the server validates payment method.
  bool get canCollectCod => deliveryStatus == 'ARRIVED_CUSTOMER';

  bool get isAtPickup => deliveryStatus == 'AT_PICKUP';

  bool get isArrivedCustomer => deliveryStatus == 'ARRIVED_CUSTOMER';

  bool get isDelivered => deliveryStatus == 'DELIVERED';

  bool get isPickedUp =>
      deliveryStatus == 'PICKED_UP' ||
      deliveryStatus == 'IN_TRANSIT' ||
      deliveryStatus == 'ARRIVED_CUSTOMER' ||
      deliveryStatus == 'DELIVERED';

  /// First server-allowed action in workflow order, if any.
  String? get primaryAction {
    for (final action in DeliveryActions.ordered) {
      if (allowedActions.contains(action)) return action;
    }
    return null;
  }

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
      expectedCodAmountMinor: json['expectedCodAmountMinor']?.toString(),
      dropoffAddressText: _optionalJsonText(json['dropoffAddressText']),
      dropoffBuilding: _optionalJsonText(json['dropoffBuilding']),
      dropoffFloor: _optionalJsonText(json['dropoffFloor']),
      dropoffEntrance: _optionalJsonText(json['dropoffEntrance']),
      dropoffLandmark: _optionalJsonText(json['dropoffLandmark']),
      dropoffInstructions: _optionalJsonText(json['dropoffInstructions']),
    );
  }
}

String? _optionalJsonText(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
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
