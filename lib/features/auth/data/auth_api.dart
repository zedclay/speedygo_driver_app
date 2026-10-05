import 'package:dio/dio.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/network/api_error_parser.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';

abstract class AuthClient {
  Future<void> requestOtp(String identifier);
  Future<TokenPair> verifyOtp(OtpVerifyBody body);
  Future<TokenPair> refresh(String refreshToken);
  Future<void> logout();
  Future<AuthMe> me();
}

class AuthApi implements AuthClient {
  AuthApi({required this._dio, required this._refreshDio});

  final Dio _dio;
  final Dio _refreshDio;

  @override
  Future<void> requestOtp(String identifier) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.otpRequestPath,
        data: OtpRequestBody(identifier: identifier).toJson(),
      );
      if (response.data?['accepted'] != true) {
        throw const ApiException(
          'La demande n’a pas été acceptée.',
          code: 'OTP_NOT_ACCEPTED',
        );
      }
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<TokenPair> verifyOtp(OtpVerifyBody body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.otpVerifyPath,
        data: body.toJson(),
      );
      return TokenPair.fromJson(response.data ?? {});
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<TokenPair> refresh(String refreshToken) async {
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshPath,
        data: {'refreshToken': refreshToken},
      );
      return TokenPair.fromJson(response.data ?? {});
    } on DioException catch (error) {
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const RefreshAmbiguousException();
      }
      throw mapDioError(error);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>(ApiEndpoints.logoutPath);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<AuthMe> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mePath,
      );
      return AuthMe.fromJson(response.data ?? {});
    } catch (error) {
      throw mapDioError(error);
    }
  }
}

/// Test double for unit/widget tests.
class FakeAuthClient implements AuthClient {
  FakeAuthClient({
    this.meResult,
    this.verifyResult,
    this.requestError,
    this.verifyError,
  });

  AuthMe? meResult;
  TokenPair? verifyResult;
  AppException? requestError;
  AppException? verifyError;
  int requestCount = 0;
  int verifyCount = 0;

  @override
  Future<void> requestOtp(String identifier) async {
    requestCount += 1;
    if (requestError != null) throw requestError!;
  }

  @override
  Future<TokenPair> verifyOtp(OtpVerifyBody body) async {
    verifyCount += 1;
    if (verifyError != null) throw verifyError!;
    return verifyResult ??
        const TokenPair(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresIn: 3600,
          tokenType: 'Bearer',
        );
  }

  @override
  Future<TokenPair> refresh(String refreshToken) async {
    throw ApiException(
      AppStrings.sessionExpired,
      code: 'AUTH_INVALID_TOKEN',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthMe> me() async {
    return meResult ??
        const AuthMe(
          accountId: 'acc',
          status: 'ACTIVE',
          hasDriverProfile: true,
        );
  }
}
