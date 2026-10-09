import 'package:speedygo_driver_app/core/utils/json_helpers.dart';

class EarningsSummary {
  const EarningsSummary({
    required this.totalEarnedMinor,
    required this.unpaidEarnedMinor,
    required this.earningCount,
    required this.currency,
  });

  final String totalEarnedMinor;
  final String unpaidEarnedMinor;
  final int earningCount;
  final String currency;

  factory EarningsSummary.fromJson(Map<String, dynamic> json) =>
      EarningsSummary(
        totalEarnedMinor: jsonStr(json['totalEarnedMinor'], '0'),
        unpaidEarnedMinor: jsonStr(json['unpaidEarnedMinor'], '0'),
        earningCount: jsonInt(json['earningCount']),
        currency: jsonStr(json['currency'], 'DZD'),
      );
}

class EarningItem {
  const EarningItem({
    required this.earningId,
    required this.deliveryId,
    required this.orderId,
    required this.amountMinor,
    required this.currency,
    required this.earnedAt,
  });

  final String earningId;
  final String deliveryId;
  final String orderId;
  final String amountMinor;
  final String currency;
  final String earnedAt;

  factory EarningItem.fromJson(Map<String, dynamic> json) => EarningItem(
    earningId: jsonStr(json['earningId']),
    deliveryId: jsonStr(json['deliveryId']),
    orderId: jsonStr(json['orderId']),
    amountMinor: jsonStr(json['amountMinor'], '0'),
    currency: jsonStr(json['currency'], 'DZD'),
    earnedAt: jsonStr(json['earnedAt']),
  );
}

class EarningsPage {
  const EarningsPage({required this.items, required this.page});

  final List<EarningItem> items;
  final PageInfo page;
}

/// Mirrors `CodDriverSummaryView`. Custody ≠ earnings.
class CodSummary {
  const CodSummary({
    required this.outstandingCustodyMinor,
    required this.collectedAmountMinor,
    required this.confirmedAllocatedMinor,
    required this.openDeclaredCount,
  });

  final String outstandingCustodyMinor;
  final String collectedAmountMinor;
  final String confirmedAllocatedMinor;
  final int openDeclaredCount;

  /// Remittance can only be declared when custody is outstanding and no open
  /// DECLARED remittance exists (server enforces both).
  bool get canDeclareRemittance =>
      (int.tryParse(outstandingCustodyMinor) ?? 0) > 0 &&
      openDeclaredCount == 0;

  factory CodSummary.fromJson(Map<String, dynamic> json) => CodSummary(
    outstandingCustodyMinor: jsonStr(json['outstandingCustodyMinor'], '0'),
    collectedAmountMinor: jsonStr(json['collectedAmountMinor'], '0'),
    confirmedAllocatedMinor: jsonStr(json['confirmedAllocatedMinor'], '0'),
    openDeclaredCount: jsonInt(json['openDeclaredCount']),
  );
}
