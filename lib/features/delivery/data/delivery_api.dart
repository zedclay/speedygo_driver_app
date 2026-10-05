import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/features/delivery/data/delivery_models.dart';

abstract class DeliveryClient {
  Future<DriverCurrentDelivery?> getCurrent();
  Future<DriverCurrentDelivery> confirmPickup(ConfirmPickupRequest body);
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
      final data = response.data ?? {};
      // Action endpoints return the view object directly (not wrapped).
      if (data.containsKey('delivery') && data['delivery'] is Map) {
        return DriverCurrentDelivery.fromJson(
          Map<String, dynamic>.from(data['delivery'] as Map),
        );
      }
      return DriverCurrentDelivery.fromJson(data);
    } catch (error) {
      throw mapDioError(error);
    }
  }
}

class FakeDeliveryClient implements DeliveryClient {
  FakeDeliveryClient({this.current, this.confirmHandler});

  DriverCurrentDelivery? current;
  Future<DriverCurrentDelivery> Function(ConfirmPickupRequest body)?
  confirmHandler;
  int getCurrentCount = 0;
  int confirmCount = 0;
  ConfirmPickupRequest? lastConfirmBody;

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
}
