import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';

enum SessionStatus { unknown, signedOut, signedIn, needsDriverProfile }

class SessionState {
  const SessionState({
    required this.status,
    this.me,
    this.errorMessage,
    this.busy = false,
    this.pendingPhone,
  });

  final SessionStatus status;
  final AuthMe? me;
  final String? errorMessage;
  final bool busy;
  final String? pendingPhone;

  SessionState copyWith({
    SessionStatus? status,
    AuthMe? me,
    String? errorMessage,
    bool clearError = false,
    bool? busy,
    String? pendingPhone,
    bool clearPendingPhone = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      me: me ?? this.me,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      pendingPhone: clearPendingPhone
          ? null
          : (pendingPhone ?? this.pendingPhone),
    );
  }
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState(status: SessionStatus.unknown);

  SessionStore get _store => ref.read(sessionStoreProvider);
  TokenCache get _cache => ref.read(tokenCacheProvider);
  AuthClient get _auth => ref.read(authApiProvider);

  Future<void> restore() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final pair = await _store.read();
      if (pair == null) {
        state = const SessionState(status: SessionStatus.signedOut);
        return;
      }
      _cache.current = pair;
      final me = await _auth.me();
      if (!me.hasDriverProfile) {
        state = SessionState(
          status: SessionStatus.needsDriverProfile,
          me: me,
          errorMessage: AppStrings.noDriverProfile,
        );
        return;
      }
      state = SessionState(status: SessionStatus.signedIn, me: me);
    } on AppException catch (error) {
      await _clearLocal();
      state = SessionState(
        status: SessionStatus.signedOut,
        errorMessage: error.message,
      );
    } catch (_) {
      await _clearLocal();
      state = const SessionState(status: SessionStatus.signedOut);
    }
  }

  Future<void> requestOtp(String phone) async {
    state = state.copyWith(busy: true, clearError: true, pendingPhone: phone);
    try {
      await _auth.requestOtp(phone);
      state = state.copyWith(busy: false, pendingPhone: phone);
    } on AppException catch (error) {
      state = state.copyWith(busy: false, errorMessage: error.message);
      rethrow;
    }
  }

  Future<void> verifyOtp(String code) async {
    final phone = state.pendingPhone;
    if (phone == null || phone.isEmpty) {
      state = state.copyWith(errorMessage: AppStrings.unexpectedError);
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final pair = await _auth.verifyOtp(
        OtpVerifyBody(identifier: phone, code: code),
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
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } catch (_) {
      // Local clear still required.
    }
    await _clearLocal();
    state = const SessionState(status: SessionStatus.signedOut);
  }

  void markSignedOut() {
    state = const SessionState(status: SessionStatus.signedOut);
  }

  Future<void> _clearLocal() async {
    _cache.current = null;
    await _store.clear();
    ref.read(sessionEpochProvider.notifier).bump();
  }
}
