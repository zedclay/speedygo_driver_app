import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/core/utils/json_helpers.dart';
import 'package:speedygo_driver_app/features/history/data/history_models.dart';

abstract class HistoryClient {
  Future<HistoryPage> list({int limit = 30, int offset = 0});
  Future<HistoryItem> detail(String deliveryId);
}

class HistoryApi implements HistoryClient {
  HistoryApi({required this._dio});

  final Dio _dio;

  @override
  Future<HistoryPage> list({int limit = 30, int offset = 0}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.driverHistoryPath,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = asJsonMap(response.data);
      return HistoryPage(
        items: asJsonList(data['items']).map(HistoryItem.fromJson).toList(),
        page: PageInfo.fromJson(data),
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<HistoryItem> detail(String deliveryId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.driverHistoryDetailPath(deliveryId),
      );
      return HistoryItem.fromJson(asJsonMap(response.data));
    } catch (error) {
      throw mapDioError(error);
    }
  }
}

class FakeHistoryClient implements HistoryClient {
  FakeHistoryClient({this.items = const []});

  List<HistoryItem> items;
  int listCount = 0;

  @override
  Future<HistoryPage> list({int limit = 30, int offset = 0}) async {
    listCount += 1;
    final slice = items.skip(offset).take(limit).toList();
    return HistoryPage(
      items: slice,
      page: PageInfo(total: items.length, limit: limit, offset: offset),
    );
  }

  @override
  Future<HistoryItem> detail(String deliveryId) async =>
      items.firstWhere((i) => i.deliveryId == deliveryId);
}
