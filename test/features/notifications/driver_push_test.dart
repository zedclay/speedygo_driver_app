import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';
import 'package:speedygo_driver_app/features/availability/application/availability_providers.dart';
import 'package:speedygo_driver_app/features/availability/data/availability_api.dart';
import 'package:speedygo_driver_app/features/notifications/application/driver_push_controller.dart';
import 'package:speedygo_driver_app/features/notifications/application/notifications_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/notifications_api.dart';
import 'package:speedygo_driver_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_driver_app/features/notifications/data/push_registration.dart';

const _accountA = 'aaaaaaaa-aaaa-7aaa-8aaa-aaaaaaaaaaaa';
const _accountB = 'bbbbbbbb-bbbb-7bbb-8bbb-bbbbbbbbbbbb';
const _offer = '01a0d97f-9cbd-7b41-8dbf-ef8238661920';

class _FakeGateway implements PushMessagingGateway {
  PushAuthorization auth = PushAuthorization.authorized;
  PushAuthorization authAfterRequest = PushAuthorization.authorized;
  int requestCount = 0;
  int deleteCount = 0;
  int _serial = 2;
  String token = 'tok-1';
  PushMatchHint? initial;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMatchHint>.broadcast();
  final opened = StreamController<PushMatchHint>.broadcast();

  @override
  bool get isAvailable => true;
  @override
  String get platform => 'android';
  @override
  Future<PushAuthorization> authorizationStatus() async => auth;
  @override
  Future<PushAuthorization> requestAuthorization() async {
    requestCount++;
    auth = authAfterRequest;
    return auth;
  }

  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> deleteToken() async {
    deleteCount++;
    token = 'tok-${_serial++}';
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushMatchHint> get onForegroundHint => foreground.stream;
  @override
  Stream<PushMatchHint> get onOpenedHint => opened.stream;
  @override
  Future<PushMatchHint?> takeInitialHint() async {
    final h = initial;
    initial = null;
    return h;
  }
}

class _MemoryStore extends DriverPushRegistration {
  StoredPushToken? value;
  @override
  Future<void> storeRegisteredToken({
    required String token,
    required String platform,
    required String? accountId,
  }) async {
    value = (token: token, platform: platform, accountId: accountId);
  }

  @override
  Future<StoredPushToken?> loadStoredToken() async => value;
  @override
  Future<void> clearStoredToken() async => value = null;
}

class _FakeSession extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.signedOut);

  void signIn(String accountId) {
    state = SessionState(
      status: SessionStatus.signedIn,
      me: AuthMe(
        accountId: accountId,
        status: 'ACTIVE',
        hasDriverProfile: true,
      ),
    );
  }

  void signOut() {
    state = const SessionState(status: SessionStatus.signedOut);
  }

  Future<void> signOutLikeLogout() async {
    await ref
        .read(driverPushControllerProvider.notifier)
        .deactivateForSignOut(callServer: true);
    ref.read(sessionEpochProvider.notifier).bump();
    signOut();
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        pushMessagingGatewayProvider.overrideWithValue(gateway),
        pushRegistrationStoreProvider.overrideWithValue(store),
        notificationsClientProvider.overrideWithValue(api),
        availabilityClientProvider.overrideWithValue(availability),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    container.listen(driverPushControllerProvider, (_, _) {});
    container.listen(
      sessionControllerProvider,
      (prev, next) => container
          .read(driverPushControllerProvider.notifier)
          .onSessionChanged(prev, next),
    );
  }

  final gateway = _FakeGateway();
  final store = _MemoryStore();
  final api = FakeNotificationsClient();
  final availability = FakeAvailabilityClient();
  late final ProviderContainer container;

  _FakeSession get session =>
      container.read(sessionControllerProvider.notifier) as _FakeSession;
  DriverPushController get push =>
      container.read(driverPushControllerProvider.notifier);
  DriverPushState get state => container.read(driverPushControllerProvider);

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

void main() {
  group('PushMatchHint.fromData', () {
    test('accepts MATCH_OFFER and ignores other types', () {
      final hint = PushMatchHint.fromData({
        'type': 'MATCH_OFFER',
        'offerId': _offer.toUpperCase(),
      });
      expect(hint?.type, 'MATCH_OFFER');
      expect(hint?.sourceId, _offer);
      expect(
        PushMatchHint.fromData({
          'type': 'ORDER_READY',
          'orderId': _offer,
        }),
        isNull,
      );
    });
  });

  test('registers the token for the signed-in account after permission prompt',
      () async {
    final h = _Harness();
    h.gateway.auth = PushAuthorization.notDetermined;
    h.session.signIn(_accountA);
    await h.settle();

    expect(h.gateway.requestCount, 1);
    expect(h.api.registered, ['android:tok-1']);
    expect(h.store.value?.accountId, _accountA);
    expect(h.state.registration, PushRegistrationStatus.registered);
  });

  test('account change rotates the provider token without deleting A\'s token',
      () async {
    final h = _Harness();
    h.store.value = (token: 'tok-A', platform: 'android', accountId: _accountA);
    h.session.signIn(_accountB);
    await h.settle();

    expect(h.gateway.deleteCount, 1);
    expect(h.api.registered, ['android:tok-2']);
    expect(h.api.deactivated, isEmpty);
    expect(h.store.value?.accountId, _accountB);
  });

  test('409 rotates once and retries', () async {
    final h = _Harness();
    h.api.conflictTokens = {'tok-1'};
    h.session.signIn(_accountA);
    await h.settle();

    expect(h.gateway.deleteCount, 1);
    expect(h.api.registered, ['android:tok-2']);
    expect(h.state.registration, PushRegistrationStatus.registered);
  });

  test('logout deactivates the stored token then deletes it at provider',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();
    await h.session.signOutLikeLogout();
    expect(h.api.deactivated, ['tok-1']);
    expect(h.store.value, isNull);
    expect(h.gateway.deleteCount, 1);
  });

  test('stale epoch does not register to the previous session', () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.session.signOutLikeLogout();
    await h.settle();
    h.session.signIn(_accountB);
    await h.settle();
    expect(h.api.registered.last, 'android:tok-2');
    expect(h.store.value?.accountId, _accountB);
  });

  test('MATCH_OFFER tap is held as pendingOpen until consumed once', () async {
    final h = _Harness();
    h.gateway.initial = const PushMatchHint(type: 'MATCH_OFFER');
    h.container.invalidate(driverPushControllerProvider);
    h.container.read(driverPushControllerProvider);
    await h.settle();

    expect(h.state.pendingOpen?.type, 'MATCH_OFFER');
    expect(h.push.takePendingOpen()?.type, 'MATCH_OFFER');
    expect(h.push.takePendingOpen(), isNull);
  });

  test('MATCH_OFFER reconcile GETs the offer and never mutates assignment',
      () async {
    final h = _Harness();
    await h.push.fetchAuthoritativeOffer();
    expect(h.availability.getOfferCount, 1);
    expect(h.availability.acceptCount, 0);
    expect(h.availability.rejectCount, 0);
    expect(h.availability.goOnlineCount, 0);
    expect(h.availability.goOfflineCount, 0);
  });
}
