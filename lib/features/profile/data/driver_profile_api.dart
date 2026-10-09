import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/core/utils/json_helpers.dart';
import 'package:speedygo_driver_app/features/availability/data/driver_me_models.dart';

/// Document types accepted by the backend.
class DriverDocumentTypes {
  DriverDocumentTypes._();

  static const identity = 'IDENTITY';
  static const drivingLicense = 'DRIVING_LICENSE';
}

/// Vehicle types accepted by the backend (no bicycle).
const driverVehicleTypes = <String>['MOTORCYCLE', 'SCOOTER', 'CAR'];

class DriverRatingSummary {
  const DriverRatingSummary({required this.count, required this.average});

  final int count;
  final double? average;

  factory DriverRatingSummary.fromJson(Map<String, dynamic> json) {
    final avg = json['average'];
    return DriverRatingSummary(
      count: jsonInt(json['count']),
      average: avg is num ? avg.toDouble() : double.tryParse('$avg'),
    );
  }
}

/// Profile / onboarding / ratings contract (backend `DriverController`).
abstract class DriverProfileClient {
  Future<DriverMe> getMe();
  Future<void> createProfile(String fullName);
  Future<void> updateProfile(String fullName);

  /// Multipart `file` → returns the opaque `uploadReference`.
  Future<String> uploadDocumentContent({
    required String type,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });

  /// Registers metadata (binding [uploadReference]); returns refreshed me.
  Future<DriverMe> upsertDocument({
    required String type,
    String? expiryDate,
    String? uploadReference,
  });

  Future<void> createVehicle({
    required String type,
    required String plateNumber,
    required String model,
    String? color,
  });
  Future<void> updateVehicle(
    String id, {
    String? type,
    String? plateNumber,
    String? model,
    String? color,
  });
  Future<DriverMe> submitVerification();
  Future<DriverRatingSummary> ratingsSummary();
}

class DriverProfileApi implements DriverProfileClient {
  DriverProfileApi({required this._dio});

  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<DriverMe> getMe() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.driverMePath,
    );
    return DriverMe.fromJson(asJsonMap(response.data));
  });

  @override
  Future<void> createProfile(String fullName) => _guard(() async {
    await _dio.post<dynamic>(
      ApiEndpoints.driverProfilePath,
      data: {'fullName': fullName},
    );
  });

  @override
  Future<void> updateProfile(String fullName) => _guard(() async {
    await _dio.patch<dynamic>(
      ApiEndpoints.driverProfilePath,
      data: {'fullName': fullName},
    );
  });

  @override
  Future<String> uploadDocumentContent({
    required String type,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) => _guard(() async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.driverDocumentsContentPath(type),
      data: form,
    );
    return jsonStr(asJsonMap(response.data)['uploadReference']);
  });

  @override
  Future<DriverMe> upsertDocument({
    required String type,
    String? expiryDate,
    String? uploadReference,
  }) => _guard(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.driverDocumentsPath(type),
      data: {'expiryDate': ?expiryDate, 'uploadReference': ?uploadReference},
    );
    return DriverMe.fromJson(asJsonMap(response.data));
  });

  @override
  Future<void> createVehicle({
    required String type,
    required String plateNumber,
    required String model,
    String? color,
  }) => _guard(() async {
    await _dio.post<dynamic>(
      ApiEndpoints.driverVehiclesPath,
      data: {
        'type': type,
        'plateNumber': plateNumber,
        'model': model,
        if (color != null && color.isNotEmpty) 'color': color,
      },
    );
  });

  @override
  Future<void> updateVehicle(
    String id, {
    String? type,
    String? plateNumber,
    String? model,
    String? color,
  }) => _guard(() async {
    await _dio.patch<dynamic>(
      ApiEndpoints.driverVehiclePath(id),
      data: {
        'type': ?type,
        'plateNumber': ?plateNumber,
        'model': ?model,
        if (color != null && color.isNotEmpty) 'color': color,
      },
    );
  });

  @override
  Future<DriverMe> submitVerification() => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.driverVerificationSubmitPath,
    );
    return DriverMe.fromJson(asJsonMap(response.data));
  });

  @override
  Future<DriverRatingSummary> ratingsSummary() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.driverRatingsSummaryPath,
    );
    return DriverRatingSummary.fromJson(asJsonMap(response.data));
  });
}

/// In-memory fake: mutates a local [DriverMe] like the server would.
class FakeDriverProfileClient implements DriverProfileClient {
  FakeDriverProfileClient({required this.me, this.rating});

  DriverMe me;
  DriverRatingSummary? rating;
  int submitCount = 0;
  String? lastFullName;
  String? lastUploadType;
  String? lastExpiry;
  String? lastUploadReference;
  Map<String, String>? lastVehicle;
  Object? submitError;

  @override
  Future<DriverMe> getMe() async => me;

  @override
  Future<void> createProfile(String fullName) async {
    lastFullName = fullName;
  }

  @override
  Future<void> updateProfile(String fullName) async {
    lastFullName = fullName;
  }

  @override
  Future<String> uploadDocumentContent({
    required String type,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    lastUploadType = type;
    return 'sg-upload:v1:fake-$type';
  }

  @override
  Future<DriverMe> upsertDocument({
    required String type,
    String? expiryDate,
    String? uploadReference,
  }) async {
    lastExpiry = expiryDate;
    lastUploadReference = uploadReference;
    return me;
  }

  @override
  Future<void> createVehicle({
    required String type,
    required String plateNumber,
    required String model,
    String? color,
  }) async {
    lastVehicle = {'type': type, 'plateNumber': plateNumber, 'model': model};
  }

  @override
  Future<void> updateVehicle(
    String id, {
    String? type,
    String? plateNumber,
    String? model,
    String? color,
  }) async {
    lastVehicle = {'id': id, 'plateNumber': plateNumber ?? ''};
  }

  @override
  Future<DriverMe> submitVerification() async {
    submitCount += 1;
    if (submitError != null) throw submitError!;
    return me;
  }

  @override
  Future<DriverRatingSummary> ratingsSummary() async =>
      rating ?? const DriverRatingSummary(count: 0, average: null);
}
