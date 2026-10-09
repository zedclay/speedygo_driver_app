import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

abstract class DeliveryClient {
  Future<DriverCurrentDelivery?> getCurrent();
  Future<DriverCurrentDelivery> confirmPickup(ConfirmPickupRequest body);
  Future<DriverCurrentDelivery> postAction(String path);
  Future<void> collectCod(int collectedAmountMinor);
}

class DeliveryApi implements DeliveryClient {
  DeliveryApi({required this._dio});

  final Dio _dio;

  @override
  Future<DriverCurrentDelivery?> getCurrent() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.currentDeliveryPath,
      );
      final data = response.data;
      final delivery = data?['delivery'];
      if (delivery == null) return null;
      if (delivery is! Map) return null;
      return DriverCurrentDelivery.fromJson(
        Map<String, dynamic>.from(delivery),
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<DriverCurrentDelivery> confirmPickup(ConfirmPickupRequest body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.confirmPickupPath,
        data: body.toJson(),
      );
      return _parseView(response.data);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<DriverCurrentDelivery> postAction(String path) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path);
      return _parseView(response.data);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> collectCod(int collectedAmountMinor) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.driverCollectCodPath,
        data: {'collectedAmountMinor': collectedAmountMinor},
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  DriverCurrentDelivery _parseView(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    if (map.containsKey('delivery') && map['delivery'] is Map) {
      return DriverCurrentDelivery.fromJson(
        Map<String, dynamic>.from(map['delivery'] as Map),
      );
    }
    return DriverCurrentDelivery.fromJson(map);
  }
}

class FakeDeliveryClient implements DeliveryClient {
  FakeDeliveryClient({
    this.current,
    this.confirmHandler,
    this.actionHandler,
    this.collectCodHandler,
  });

  DriverCurrentDelivery? current;
  Future<DriverCurrentDelivery> Function(ConfirmPickupRequest body)?
  confirmHandler;
  Future<DriverCurrentDelivery> Function(String path)? actionHandler;
  Future<void> Function(int amountMinor)? collectCodHandler;

  int getCurrentCount = 0;
  int confirmCount = 0;
  int actionCount = 0;
  int collectCodCount = 0;
  ConfirmPickupRequest? lastConfirmBody;
  String? lastActionPath;
  int? lastCollectedAmountMinor;

  @override
  Future<DriverCurrentDelivery?> getCurrent() async {
    getCurrentCount += 1;
    return current;
  }

  @override
  Future<DriverCurrentDelivery> confirmPickup(ConfirmPickupRequest body) async {
    confirmCount += 1;
    lastConfirmBody = body;
    if (confirmHandler != null) {
      return confirmHandler!(body);
    }
    throw StateError('confirmHandler not set');
  }

  @override
  Future<DriverCurrentDelivery> postAction(String path) async {
    actionCount += 1;
    lastActionPath = path;
    if (actionHandler != null) {
      return actionHandler!(path);
    }
    throw StateError('actionHandler not set');
  }

  @override
  Future<void> collectCod(int collectedAmountMinor) async {
    collectCodCount += 1;
    lastCollectedAmountMinor = collectedAmountMinor;
    if (collectCodHandler != null) {
      await collectCodHandler!(collectedAmountMinor);
      return;
    }
  }
}
