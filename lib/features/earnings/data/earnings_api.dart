import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/core/utils/json_helpers.dart';
import 'package:speedygo_driver_app/features/earnings/data/earnings_models.dart';

abstract class EarningsClient {
  Future<EarningsSummary> summary();
  Future<EarningsPage> list({int limit = 30, int offset = 0});
  Future<CodSummary> codSummary();
  Future<void> submitRemittance({required int submittedAmountMinor});
}

class EarningsApi implements EarningsClient {
  EarningsApi({required this._dio});

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<EarningsSummary> summary() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.driverEarningsSummaryPath,
    );
    return EarningsSummary.fromJson(asJsonMap(response.data));
  });

  @override
  Future<EarningsPage> list({int limit = 30, int offset = 0}) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.driverEarningsPath,
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final data = asJsonMap(response.data);
        return EarningsPage(
          items: asJsonList(data['items']).map(EarningItem.fromJson).toList(),
          page: PageInfo.fromJson(data),
        );
      });

  @override
  Future<CodSummary> codSummary() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.driverCodSummaryPath,
    );
    return CodSummary.fromJson(asJsonMap(response.data));
  });

  @override
  Future<void> submitRemittance({required int submittedAmountMinor}) =>
      _guard(() async {
        await _dio.post<dynamic>(
          ApiEndpoints.driverCodRemittancesPath,
          data: {'submittedAmountMinor': submittedAmountMinor},
        );
      });
}

class FakeEarningsClient implements EarningsClient {
  FakeEarningsClient({
    this.summaryValue = const EarningsSummary(
      totalEarnedMinor: '0',
      unpaidEarnedMinor: '0',
      earningCount: 0,
      currency: 'DZD',
    ),
    this.items = const [],
    this.cod = const CodSummary(
      outstandingCustodyMinor: '0',
      collectedAmountMinor: '0',
      confirmedAllocatedMinor: '0',
      openDeclaredCount: 0,
    ),
    this.remittanceHandler,
  });

  EarningsSummary summaryValue;
  List<EarningItem> items;
  CodSummary cod;
  Future<void> Function(int amountMinor)? remittanceHandler;
  int? lastRemittanceMinor;

  @override
  Future<EarningsSummary> summary() async => summaryValue;

  @override
  Future<EarningsPage> list({int limit = 30, int offset = 0}) async =>
      EarningsPage(
        items: items.skip(offset).take(limit).toList(),
        page: PageInfo(total: items.length, limit: limit, offset: offset),
      );

  @override
  Future<CodSummary> codSummary() async => cod;

  @override
  Future<void> submitRemittance({required int submittedAmountMinor}) async {
    lastRemittanceMinor = submittedAmountMinor;
    await remittanceHandler?.call(submittedAmountMinor);
  }
}
