import 'dart:io';

import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';
import 'package:speedygo_driver_app/features/availability/data/offer_models.dart';

abstract class AvailabilityClient {
  Future<DriverMe> getMe();
  Future<DriverMe> goOnline();
  Future<DriverMe> goOffline();
  Future<({AssignmentOffer? offer, DateTime? serverTime})> getCurrentOffer();
  Future<void> acceptOffer(String assignmentId);
  Future<void> rejectOffer(String assignmentId);
  Future<DriverLocationPublishResult> publishLocation(
    DriverLocationUpdate update,
  );
}

class AvailabilityApi implements AvailabilityClient {
  AvailabilityApi({required this._dio});

  final Dio _dio;

  @override
  Future<DriverMe> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.driverMePath,
      );
      return DriverMe.fromJson(response.data ?? const {});
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<DriverMe> goOnline() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.driverGoOnlinePath,
      );
      return DriverMe.fromJson(response.data ?? const {});
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<DriverMe> goOffline() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.driverGoOfflinePath,
      );
      return DriverMe.fromJson(response.data ?? const {});
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<({AssignmentOffer? offer, DateTime? serverTime})>
  getCurrentOffer() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.driverCurrentOfferPath,
      );
      final data = response.data ?? const {};
      final raw = data['offer'];
      AssignmentOffer? offer;
      if (raw is Map) {
        offer = AssignmentOffer.fromJson(Map<String, dynamic>.from(raw));
      }
      return (offer: offer, serverTime: _parseServerDate(response));
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> acceptOffer(String assignmentId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.driverAcceptOfferPath(assignmentId),
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> rejectOffer(String assignmentId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.driverRejectOfferPath(assignmentId),
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<DriverLocationPublishResult> publishLocation(
    DriverLocationUpdate update,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.driverLocationPath,
        data: update.toJson(),
      );
      return DriverLocationPublishResult.fromJson(response.data ?? const {});
    } catch (error) {
      throw mapDioError(error);
    }
  }

  DateTime? _parseServerDate(Response<dynamic> response) {
    final header = response.headers.value('date');
    if (header == null || header.isEmpty) return null;
    try {
      return HttpDate.parse(header).toUtc();
    } catch (_) {
      return DateTime.tryParse(header)?.toUtc();
    }
  }
}

class FakeAvailabilityClient implements AvailabilityClient {
  FakeAvailabilityClient({
    this.me,
    this.offer,
    this.serverTime,
    this.goOnlineHandler,
    this.goOfflineHandler,
    this.acceptHandler,
    this.rejectHandler,
    this.publishHandler,
    this.offerHandler,
  });

  DriverMe? me;
  AssignmentOffer? offer;
  DateTime? serverTime;
  Future<DriverMe> Function()? goOnlineHandler;
  Future<DriverMe> Function()? goOfflineHandler;
  Future<void> Function(String id)? acceptHandler;
  Future<void> Function(String id)? rejectHandler;
  Future<DriverLocationPublishResult> Function(DriverLocationUpdate)?
  publishHandler;
  Future<({AssignmentOffer? offer, DateTime? serverTime})> Function()?
  offerHandler;

  int getMeCount = 0;
  int goOnlineCount = 0;
  int goOfflineCount = 0;
  int getOfferCount = 0;
  int acceptCount = 0;
  int rejectCount = 0;
  int publishCount = 0;
  String? lastAcceptId;
  String? lastRejectId;
  DriverLocationUpdate? lastLocation;

  @override
  Future<DriverMe> getMe() async {
    getMeCount += 1;
    final value = me;
    if (value == null) {
      throw StateError('FakeAvailabilityClient.me not set');
    }
    return value;
  }

  @override
  Future<DriverMe> goOnline() async {
    goOnlineCount += 1;
    if (goOnlineHandler != null) return goOnlineHandler!();
    throw StateError('goOnlineHandler not set');
  }

  @override
  Future<DriverMe> goOffline() async {
    goOfflineCount += 1;
    if (goOfflineHandler != null) return goOfflineHandler!();
    throw StateError('goOfflineHandler not set');
  }

  @override
  Future<({AssignmentOffer? offer, DateTime? serverTime})>
  getCurrentOffer() async {
    getOfferCount += 1;
    if (offerHandler != null) return offerHandler!();
    return (offer: offer, serverTime: serverTime);
  }

  @override
  Future<void> acceptOffer(String assignmentId) async {
    acceptCount += 1;
    lastAcceptId = assignmentId;
    if (acceptHandler != null) {
      await acceptHandler!(assignmentId);
      return;
    }
  }

  @override
  Future<void> rejectOffer(String assignmentId) async {
    rejectCount += 1;
    lastRejectId = assignmentId;
    if (rejectHandler != null) {
      await rejectHandler!(assignmentId);
      return;
    }
  }

  @override
  Future<DriverLocationPublishResult> publishLocation(
    DriverLocationUpdate update,
  ) async {
    publishCount += 1;
    lastLocation = update;
    if (publishHandler != null) return publishHandler!(update);
    return DriverLocationPublishResult(
      driverId: 'drv-1',
      recordedAt: DateTime.now().toUtc().toIso8601String(),
      applied: true,
    );
  }
}
