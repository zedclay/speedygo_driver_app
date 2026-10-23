import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';

const _pair = TokenPair(
  accessToken: 'access-1',
  refreshToken: 'refresh-1-token-value',
  expiresIn: 900,
  tokenType: 'Bearer',
);

ProviderContainer containerOf({
  required FakeAuthClient auth,
  MemorySessionStore? store,
}) {
  final memory = store ?? MemorySessionStore();
  return ProviderContainer(
    overrides: [
      sessionStoreProvider.overrideWithValue(memory),
      authApiProvider.overrideWithValue(auth),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppStrings.bind('fr');

  test('missing credentials sign out', () async {
    final container = containerOf(auth: FakeAuthClient());
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedOut,
    );
  });

  test('successful restore reaches signed-in', () async {
    final store = MemorySessionStore()..value = _pair;
    final container = containerOf(auth: FakeAuthClient(), store: store);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedIn,
    );
    expect(store.value, isNotNull);
  });

  test('transient network failure keeps credentials', () async {
    final store = MemorySessionStore()..value = _pair;
    final auth = FakeAuthClient()
      ..meError = const NetworkException('offline', code: 'NETWORK');
    final container = containerOf(auth: auth, store: store);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.restoreRetryable);
    expect(state.errorMessage, AppStrings.restoreOffline);
    expect(store.value, isNotNull);
    expect(state.canRunDriverOps, isFalse);
  });

  test('backend 5xx keeps credentials and is retryable', () async {
    final store = MemorySessionStore()..value = _pair;
    final auth = FakeAuthClient()
      ..meError = const ApiException(
        'unavailable',
        code: 'INTERNAL_ERROR',
        statusCode: 503,
      );
    final container = containerOf(auth: auth, store: store);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.restoreRetryable,
    );
    expect(store.value, isNotNull);
  });

  test('successful retry after transient failure', () async {
    final store = MemorySessionStore()..value = _pair;
    final auth = FakeAuthClient()
      ..meError = const NetworkException('offline', code: 'NETWORK');
    final container = containerOf(auth: auth, store: store);
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.restore();
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.restoreRetryable,
    );
    auth.meError = null;
    await controller.retryRestore();
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedIn,
    );
    expect(store.value, isNotNull);
  });

  test('terminal auth rejection clears the local session', () async {
    final store = MemorySessionStore()..value = _pair;
    final auth = FakeAuthClient()
      ..meError = const ApiException(
        'revoked',
        code: 'AUTH_SESSION_REVOKED',
        statusCode: 401,
      );
    final container = containerOf(auth: auth, store: store);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedOut,
    );
    expect(store.value, isNull);
  });

  test('permission denial keeps credentials', () async {
    final store = MemorySessionStore()..value = _pair;
    final auth = FakeAuthClient()
      ..meError = const ApiException(
        'forbidden',
        code: 'AUTH_FORBIDDEN',
        statusCode: 403,
      );
    final container = containerOf(auth: auth, store: store);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.restoreRetryable);
    expect(state.errorMessage, AppStrings.restorePermissionDenied);
    expect(store.value, isNotNull);
    expect(state.canRunDriverOps, isFalse);
  });

  test('logout during outstanding restore cannot apply later', () async {
    final store = MemorySessionStore()..value = _pair;
    final held = Completer<AuthMe>();
    final auth = FakeAuthClient()..meHold = held.future;
    final container = containerOf(auth: auth, store: store);
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    final pending = controller.restore();
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.restoring,
    );
    await controller.logout();
    expect(store.value, isNull);
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedOut,
    );
    held.complete(
      const AuthMe(
        accountId: 'acc',
        status: 'ACTIVE',
        hasDriverProfile: true,
      ),
    );
    await pending;
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedOut,
    );
    expect(store.value, isNull);
  });

  test('overlapping restore calls share one in-flight request', () async {
    final store = MemorySessionStore()..value = _pair;
    final held = Completer<AuthMe>();
    final auth = FakeAuthClient()..meHold = held.future;
    final container = containerOf(auth: auth, store: store);
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    final first = controller.restore();
    final second = controller.retryRestore();
    expect(identical(first, second), isTrue);
    held.complete(
      const AuthMe(
        accountId: 'acc',
        status: 'ACTIVE',
        hasDriverProfile: true,
      ),
    );
    await first;
    expect(auth.meCount, 1);
    expect(
      container.read(sessionControllerProvider).status,
      SessionStatus.signedIn,
    );
  });
}
