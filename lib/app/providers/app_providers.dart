import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/network/api_client.dart';

final appNameProvider = Provider<String>((ref) => AppConstants.appName);

final dioProvider = Provider<Dio>((ref) => createApiClient());
