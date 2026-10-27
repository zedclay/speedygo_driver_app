import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/core/utils/phone_input.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';
import 'package:speedygo_driver_app/features/notifications/application/driver_push_controller.dart';

enum SessionStatus {
  unknown,
  restoring,
  restoreRetryable,
  signedOut,
  signedIn,
  needsDriverProfile,
}

enum RestoreIssue { none, offline, permission }

class SessionState {
  const SessionState({
    required this.status,
    this.me,
    this.errorMessage,
    this.restoreIssue = RestoreIssue.none,
    this.busy = false,
    this.pendingPhone,
    this.otpResendAvailableAt,
  });

  final SessionStatus status;
  final AuthMe? me;
  final String? errorMessage;
  final RestoreIssue restoreIssue;
  final bool busy;
  final String? pendingPhone;
  final DateTime? otpResendAvailableAt;

  /// Live FR/AR copy. Do not snapshot translated strings across locale changes.
  String? get restoreBanner {
    switch (restoreIssue) {
      case RestoreIssue.offline:
        return AppStrings.restoreOffline;
      case RestoreIssue.permission:
        return AppStrings.restorePermissionDenied;
      case RestoreIssue.none:
        return errorMessage;
    }
  }

  /// Availability, delivery, and location mutations require a validated session.
  bool get canRunDriverOps => status == SessionStatus.signedIn;

  bool get canRunOnboarding =>
      status == SessionStatus.signedIn ||
      status == SessionStatus.needsDriverProfile;

  bool get canRequestOtp {
    final at = otpResendAvailableAt;
    if (at == null) return true;
    return !DateTime.now().isBefore(at);
  }

  int get otpResendSecondsRemaining {
    final at = otpResendAvailableAt;
    if (at == null) return 0;
    final seconds = at.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  SessionState copyWith({
    SessionStatus? status,
    AuthMe? me,
    String? errorMessage,
    bool clearError = false,
    RestoreIssue? restoreIssue,
    bool? busy,
    String? pendingPhone,
    bool clearPendingPhone = false,
    DateTime? otpResendAvailableAt,
  }) {
    return SessionState(
      status: status ?? this.status,
      me: me ?? this.me,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      restoreIssue: clearError
          ? RestoreIssue.none
          : (restoreIssue ?? this.restoreIssue),
      busy: busy ?? this.busy,
      pendingPhone: clearPendingPhone
          ? null
          : (pendingPhone ?? this.pendingPhone),
      otpResendAvailableAt: otpResendAvailableAt ?? this.otpResendAvailableAt,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  Future<void>? _restoreInFlight;

  @override
  SessionState build() => const SessionState(status: SessionStatus.unknown);

  SessionStore get _store => ref.read(sessionStoreProvider);
  TokenCache get _cache => ref.read(tokenCacheProvider);
  AuthClient get _auth => ref.read(authApiProvider);

  Future<void> restore() {
    return _restoreInFlight ??= _restoreBody().whenComplete(() {
      _restoreInFlight = null;
    });
  }

  Future<void> retryRestore() => restore();

  Future<void> _restoreBody() async {
    final generation = ref.read(sessionEpochProvider);
    state = state.copyWith(
      status: SessionStatus.restoring,
      busy: true,
      clearError: true,
    );
    try {
      final pair = await _store.read();
      if (!_isCurrent(generation)) return;
      if (pair == null) {
        state = const SessionState(status: SessionStatus.signedOut);
        return;
      }
      _cache.current = pair;
      final me = await _auth.me();
      if (!_isCurrent(generation)) return;
      if (!me.hasDriverProfile) {
        state = SessionState(
          status: SessionStatus.needsDriverProfile,
          me: me,
        );
        return;
      }
      state = SessionState(status: SessionStatus.signedIn, me: me);
    } on RefreshAmbiguousException {
      if (!_isCurrent(generation)) return;
      await _clearLocal();
      state = SessionState(
        status: SessionStatus.signedOut,
        errorMessage: AppStrings.sessionExpired,
      );
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) return;
      if (error.code == 'AUTH_STALE_REFRESH') {
        return;
      }
      if (error.isAuthFailure) {
        await _clearLocal();
        state = SessionState(
          status: SessionStatus.signedOut,
          errorMessage: AppStrings.sessionExpired,
        );
        return;
      }
      if (error.isPermissionDenied) {
        state = SessionState(
          status: SessionStatus.restoreRetryable,
          restoreIssue: RestoreIssue.permission,
          errorMessage: AppStrings.restorePermissionDenied,
        );
        return;
      }
      final offline = (error.statusCode ?? 0) >= 500;
      state = SessionState(
        status: SessionStatus.restoreRetryable,
        restoreIssue: offline ? RestoreIssue.offline : RestoreIssue.none,
        errorMessage: offline ? AppStrings.restoreOffline : error.message,
      );
    } on NetworkException {
      if (!_isCurrent(generation)) return;
      state = SessionState(
        status: SessionStatus.restoreRetryable,
        restoreIssue: RestoreIssue.offline,
        errorMessage: AppStrings.restoreOffline,
      );
    } on AppException catch (error) {
      if (!_isCurrent(generation)) return;
      state = SessionState(
        status: SessionStatus.restoreRetryable,
        restoreIssue: RestoreIssue.offline,
        errorMessage: error.message,
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      state = SessionState(
        status: SessionStatus.restoreRetryable,
        restoreIssue: RestoreIssue.offline,
        errorMessage: AppStrings.restoreOffline,
      );
    }
  }

  Future<void> markTransientRestoreFailure({
    RestoreIssue issue = RestoreIssue.offline,
    String? message,
  }) async {
    state = SessionState(
      status: SessionStatus.restoreRetryable,
      me: state.me,
      restoreIssue: issue,
      errorMessage: message ??
          (issue == RestoreIssue.permission
              ? AppStrings.restorePermissionDenied
              : AppStrings.restoreOffline),
    );
  }

  Future<void> requestOtp(String rawPhone) async {
    if (state.busy) return;
    if (!PhoneInput.isValid(rawPhone)) {
      state = state.copyWith(errorMessage: AppStrings.phoneInvalid);
      return;
    }
    if (!state.canRequestOtp) {
      state = state.copyWith(
        errorMessage: AppStrings.errorForCode('AUTH_RATE_LIMITED'),
      );
      return;
    }
    final identifier = PhoneInput.toIdentifier(rawPhone);
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _auth.requestOtp(identifier);
      const cooldown = AppConstants.otpResendCooldownSeconds;
      state = state.copyWith(
        busy: false,
        pendingPhone: identifier,
        clearError: true,
        otpResendAvailableAt: DateTime.now().add(
          const Duration(seconds: cooldown),
        ),
      );
    } on ApiException catch (error) {
      final retry =
          error.retryAfterSeconds ?? AppConstants.otpResendCooldownSeconds;
      state = state.copyWith(
        busy: false,
        errorMessage: error.message,
        otpResendAvailableAt: error.code == 'AUTH_RATE_LIMITED'
            ? DateTime.now().add(Duration(seconds: retry))
            : state.otpResendAvailableAt,
      );
    } on AppException catch (error) {
      state = state.copyWith(busy: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.networkError,
      );
    }
  }

  Future<void> verifyOtp(String code) async {
    if (state.busy) return;
    final phone = state.pendingPhone;
    if (phone == null || phone.isEmpty) {
      state = state.copyWith(errorMessage: AppStrings.unexpectedError);
      return;
    }
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if (digits.length != AppConstants.otpLength) {
      state = state.copyWith(
        errorMessage: AppStrings.errorForCode('AUTH_INVALID_OTP'),
      );
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      ref.read(sessionEpochProvider.notifier).bump();
      final pair = await _auth.verifyOtp(
        OtpVerifyBody(identifier: phone, code: digits),
      );
      await _store.write(pair);
      _cache.current = pair;
      final me = await _auth.me();
      if (!me.hasDriverProfile) {
        state = SessionState(
          status: SessionStatus.needsDriverProfile,
          me: me,
          busy: false,
          errorMessage: AppStrings.noDriverProfile,
        );
        return;
      }
      state = SessionState(status: SessionStatus.signedIn, me: me, busy: false);
    } on AppException catch (error) {
      state = state.copyWith(busy: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.networkError,
      );
    }
  }

  void dismissError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }

  Future<void> logout() async {
    ref.read(sessionEpochProvider.notifier).bump();
    try {
      await ref
          .read(driverPushControllerProvider.notifier)
          .deactivateForSignOut(callServer: true);
    } catch (_) {}
    try {
      await _auth.logout();
    } catch (_) {
      // Local clear still required.
    }
    await _clearLocal();
    state = const SessionState(status: SessionStatus.signedOut);
  }

  void markSignedOut() {
    ref.read(sessionEpochProvider.notifier).bump();
    unawaited(
      ref
          .read(driverPushControllerProvider.notifier)
          .deactivateForSignOut(callServer: false),
    );
    state = const SessionState(status: SessionStatus.signedOut);
  }

  bool _isCurrent(int generation) =>
      ref.read(sessionEpochProvider) == generation;

  Future<void> _clearLocal() async {
    _cache.current = null;
    await _store.clear();
    ref.read(sessionEpochProvider.notifier).bump();
  }
}
