import 'package:speedygo_driver_app/core/utils/json_helpers.dart';

/// Mirrors `DriverDeliveryHistoryItemDto`. `earningAmountMinor` is a decimal
/// string of integer minor units (recognition only — not a payout).
class HistoryItem {
  const HistoryItem({
    required this.deliveryId,
    required this.orderPublicReference,
    required this.deliveryStatus,
    required this.deliveredAt,
    required this.merchantName,
    required this.branchName,
    required this.paymentMethod,
    required this.earningAmountMinor,
    required this.currency,
    this.pickedUpAt,
    this.arrivedCustomerAt,
  });

  final String deliveryId;
  final String orderPublicReference;
  final String deliveryStatus;
  final String deliveredAt;
  final String merchantName;
  final String branchName;
  final String? paymentMethod;
  final String earningAmountMinor;
  final String currency;
  final String? pickedUpAt;
  final String? arrivedCustomerAt;

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final earning = asJsonMap(json['earning']);
    return HistoryItem(
      deliveryId: jsonStr(json['deliveryId']),
      orderPublicReference: jsonStr(json['orderPublicReference']),
      deliveryStatus: jsonStr(json['deliveryStatus']),
      deliveredAt: jsonStr(json['deliveredAt']),
      merchantName: jsonStr(json['merchantName']),
      branchName: jsonStr(json['branchName']),
      paymentMethod: jsonStrOrNull(json['paymentMethod']),
      earningAmountMinor: jsonStr(earning['earningAmountMinor'], '0'),
      currency: jsonStr(earning['currency'], 'DZD'),
      pickedUpAt: jsonStrOrNull(json['pickedUpAt']),
      arrivedCustomerAt: jsonStrOrNull(json['arrivedCustomerAt']),
    );
  }
}

class HistoryPage {
  const HistoryPage({required this.items, required this.page});

  final List<HistoryItem> items;
  final PageInfo page;
}
