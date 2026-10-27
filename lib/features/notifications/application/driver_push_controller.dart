import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_driver_app/features/notifications/data/push_registration.dart';

final pushMessagingGatewayProvider = Provider<PushMessagingGateway>(
  (ref) => const DisabledPushMessagingGateway(),
);

final pushRegistrationStoreProvider = Provider<DriverPushRegistration>(
  (ref) => DriverPushRegistration(),
);

enum PushRegistrationStatus {
  unavailable,
  idle,
  registered,
  permissionDenied,
  tokenUnavailable,
  failed,
}

@immutable
class DriverPushState {
  const DriverPushState({
    this.available = false,
    this.authorization = PushAuthorization.notDetermined,
    this.registration = PushRegistrationStatus.unavailable,
    this.pendingOpen,
  });

  final bool available;
  final PushAuthorization authorization;
  final PushRegistrationStatus registration;
  final PushMatchHint? pendingOpen;

  DriverPushState copyWith({
    bool? available,
    PushAuthorization? authorization,
    PushRegistrationStatus? registration,
    PushMatchHint? pendingOpen,
    bool clearPendingOpen = false,
  }) {
    return DriverPushState(
      available: available ?? this.available,
      authorization: authorization ?? this.authorization,
      registration: registration ?? this.registration,
      pendingOpen: clearPendingOpen ? null : (pendingOpen ?? this.pendingOpen),
    );
  }
}

class DriverPushController extends Notifier<DriverPushState> {
  final List<StreamSubscription<Object?>> _subs = [];
  Future<void>? _syncInFlight;
  bool _syncAgain = false;

  PushMessagingGateway get _gateway => ref.read(pushMessagingGatewayProvider);
  DriverPushRegistration get _store =>
      ref.read(pushRegistrationStoreProvider);

  @override
  DriverPushState build() {
    final gateway = ref.read(pushMessagingGatewayProvider);
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _subs.clear();
    });
    if (!gateway.isAvailable) {
      return const DriverPushState();
    }
    _subs
      ..add(gateway.onTokenRefresh.listen((t) => unawaited(_onTokenRefresh(t))))
      ..add(gateway.onForegroundHint.listen(_onForegroundHint))
      ..add(gateway.onOpenedHint.listen(_onOpened));
    unawaited(_captureInitialHint());
    if (ref.read(sessionControllerProvider).status == SessionStatus.signedIn) {
      Future.microtask(() => syncRegistration(prompt: true));
    }
    return const DriverPushState(
      available: true,
      registration: PushRegistrationStatus.idle,
    );
  }

  Future<void> _captureInitialHint() async {
    try {
      final hint = await _gateway.takeInitialHint();
      if (hint != null && ref.mounted) _onOpened(hint);
    } catch (e) {
      debugPrint('push initial message unavailable: $e');
    }
  }

  void _onOpened(PushMatchHint hint) {
    state = state.copyWith(pendingOpen: hint);
  }

  void _onForegroundHint(PushMatchHint hint) {
    ref.invalidate(unreadNotificationsProvider);
  }

  void onSessionChanged(SessionState? prev, SessionState next) {
    if (next.status == SessionStatus.signedIn &&
        (prev?.status != SessionStatus.signedIn ||
            prev?.me?.accountId != next.me?.accountId)) {
      unawaited(syncRegistration(prompt: true));
    }
  }

  PushMatchHint? takePendingOpen() {
    final hint = state.pendingOpen;
    if (hint != null) state = state.copyWith(clearPendingOpen: true);
    return hint;
  }

  @visibleForTesting
  void debugOpenFromPush(PushMatchHint hint) => _onOpened(hint);

  /// Read-only GET of the current offer. Never accepts, rejects, or
  /// changes availability / delivery from a push payload.
  Future<void> fetchAuthoritativeOffer() async {
    try {
      await ref.read(availabilityClientProvider).getCurrentOffer();
    } catch (e) {
      debugPrint('push offer reconcile failed: $e');
    }
  }

  Future<void> syncRegistration({bool prompt = false}) async {
    if (!_gateway.isAvailable) return;
    if (_syncInFlight != null) {
      _syncAgain = true;
      return _syncInFlight;
    }
    final run = _sync(prompt: prompt);
    _syncInFlight = run;
    try {
      await run;
    } finally {
      _syncInFlight = null;
      if (_syncAgain && ref.mounted) {
        _syncAgain = false;
        unawaited(syncRegistration());
      }
    }
  }

  Future<void> _sync({required bool prompt}) async {
    final session = ref.read(sessionControllerProvider);
    final accountId = session.me?.accountId;
    if (session.status != SessionStatus.signedIn ||
        accountId == null ||
        accountId.isEmpty) {
      return;
    }
    final generation = ref.read(sessionEpochProvider);
    bool current() =>
        ref.mounted &&
        ref.read(sessionEpochProvider) == generation &&
        ref.read(sessionControllerProvider).status == SessionStatus.signedIn &&
        ref.read(sessionControllerProvider).me?.accountId == accountId;

    try {
      var auth = await _gateway.authorizationStatus();
      if (auth == PushAuthorization.notDetermined && prompt) {
        auth = await _gateway.requestAuthorization();
      }
      if (!current()) return;
      state = state.copyWith(authorization: auth);

      var stored = await _store.loadStoredToken();
      if (!current()) return;

      if (!auth.allowsDisplay) {
        await _deactivateStored(stored, callServer: true);
        state = state.copyWith(
          registration: PushRegistrationStatus.permissionDenied,
        );
        return;
      }

      if (stored != null &&
          stored.accountId != null &&
          stored.accountId != accountId) {
        await _store.clearStoredToken();
        await _gateway.deleteToken();
        stored = null;
      }

      var token = await _gateway.getToken();
      if (!current()) return;
      if (token == null) {
        state = state.copyWith(
          registration: PushRegistrationStatus.tokenUnavailable,
        );
        return;
      }

      if (stored != null && stored.token != token) {
        await _deactivateServerToken(stored.token);
      }
      try {
        await ref
            .read(notificationsClientProvider)
            .registerDeviceToken(token: token, platform: _gateway.platform);
      } on ApiException catch (e) {
        if (e.statusCode != 409) rethrow;
        await _gateway.deleteToken();
        token = await _gateway.getToken();
        if (token == null || !current()) return;
        await ref
            .read(notificationsClientProvider)
            .registerDeviceToken(token: token, platform: _gateway.platform);
      }
      if (!current()) return;
      await _store.storeRegisteredToken(
        token: token,
        platform: _gateway.platform,
        accountId: accountId,
      );
      state = state.copyWith(registration: PushRegistrationStatus.registered);
    } catch (e) {
      debugPrint('push registration failed: $e');
      if (ref.mounted) {
        state = state.copyWith(registration: PushRegistrationStatus.failed);
      }
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    final session = ref.read(sessionControllerProvider);
    if (session.status != SessionStatus.signedIn) return;
    final stored = await _store.loadStoredToken();
    if (stored?.token == token) return;
    await syncRegistration();
  }

  Future<void> deactivateForSignOut({required bool callServer}) async {
    try {
      final stored = await _store.loadStoredToken();
      await _deactivateStored(stored, callServer: callServer);
      if (_gateway.isAvailable) {
        await _gateway.deleteToken();
      }
    } catch (e) {
      debugPrint('push sign-out cleanup failed: $e');
    }
    if (ref.mounted) {
      state = state.copyWith(
        registration: _gateway.isAvailable
            ? PushRegistrationStatus.idle
            : PushRegistrationStatus.unavailable,
        clearPendingOpen: callServer,
      );
    }
  }

  Future<void> _deactivateStored(
    StoredPushToken? stored, {
    required bool callServer,
  }) async {
    if (stored == null) return;
    if (callServer) {
      await _deactivateServerToken(stored.token);
    }
    await _store.clearStoredToken();
  }

  Future<void> _deactivateServerToken(String token) async {
    try {
      await ref
          .read(notificationsClientProvider)
          .deactivateDeviceToken(token: token);
    } catch (e) {
      debugPrint('push token deactivate failed: $e');
    }
  }
}

final driverPushControllerProvider =
    NotifierProvider<DriverPushController, DriverPushState>(
      DriverPushController.new,
    );
