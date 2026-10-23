import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/network/api_client.dart';
import 'package:speedygo_driver_app/core/network/api_config.dart';
import 'package:speedygo_driver_app/core/network/token_refresher.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';

const _initial = TokenPair(
  accessToken: 'access-1',
  refreshToken: 'refresh-1-token-value',
  expiresIn: 900,
  tokenType: 'Bearer',
);

ResponseBody _json(int status, [Map<String, dynamic>? body]) {
  return ResponseBody.fromString(
    jsonEncode(body ?? {'ok': true}),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.script);

  final List<ResponseBody Function(RequestOptions)> script;
  int calls = 0;
  final authorizations = <String?>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorizations.add(options.headers['Authorization']?.toString());
    final index = calls;
    calls += 1;
    return script[index](options);
  }
}

({
  Dio dio,
  FakeAuthClient auth,
  MemorySessionStore store,
  TokenCache cache,
  int Function() invalidated,
})
_client({
  required HttpClientAdapter adapter,
  FakeAuthClient? auth,
  int Function()? generation,
}) {
  final store = MemorySessionStore()..value = _initial;
  final cache = TokenCache()..current = _initial;
  final fake = auth ?? FakeAuthClient();
  var epoch = 0;
  var invalidated = 0;
  final refresher = TokenRefresher(
    authApi: fake,
    store: store,
    cache: cache,
    currentGeneration: generation ?? () => epoch,
  );
  const config = ApiConfig(apiBaseUrl: 'http://127.0.0.1:3000/api/v1');
  final dio = createApiClient(
    config: config,
    readSession: () async => cache.current ?? await store.read(),
    refresher: refresher,
    onSessionInvalid: () async {
      invalidated += 1;
      cache.current = null;
      await store.clear();
      epoch += 1;
    },
  );
  dio.httpClientAdapter = adapter;
  return (
    dio: dio,
    auth: fake,
    store: store,
    cache: cache,
    invalidated: () => invalidated,
  );
}

void main() {
  test('expired access token refreshes then retries', () async {
    final adapter = _ScriptedAdapter([
      (_) => _json(401, {
        'error': {'code': 'AUTH_INVALID_TOKEN', 'message': 'expired'},
      }),
      (_) => _json(200, {'ok': true}),
    ]);
    final client = _client(adapter: adapter);
    final response = await client.dio.get<Map<String, dynamic>>('/auth/me');
    expect(response.statusCode, 200);
    expect(client.auth.refreshCount, 1);
    expect(adapter.authorizations[1], 'Bearer access-2');
    expect(client.store.value?.accessToken, 'access-2');
    expect(client.invalidated(), 0);
  });

  test('transient refresh failure does not delete credentials', () async {
    final auth = FakeAuthClient()
      ..refreshError = const NetworkException('offline', code: 'NETWORK');
    final adapter = _ScriptedAdapter([
      (_) => _json(401, {
        'error': {'code': 'AUTH_INVALID_TOKEN', 'message': 'expired'},
      }),
    ]);
    final client = _client(adapter: adapter, auth: auth);
    await expectLater(
      client.dio.get<Map<String, dynamic>>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(client.store.value, isNotNull);
    expect(client.invalidated(), 0);
  });

  test('confirmed invalid refresh clears the session', () async {
    final auth = FakeAuthClient()
      ..refreshError = const ApiException(
        'revoked',
        code: 'AUTH_SESSION_REVOKED',
        statusCode: 401,
      );
    final adapter = _ScriptedAdapter([
      (_) => _json(401, {
        'error': {'code': 'AUTH_INVALID_TOKEN', 'message': 'expired'},
      }),
    ]);
    final client = _client(adapter: adapter, auth: auth);
    await expectLater(
      client.dio.get<Map<String, dynamic>>('/auth/me'),
      throwsA(isA<DioException>()),
    );
    expect(client.store.value, isNull);
    expect(client.invalidated(), 1);
  });

  test('permission denial does not refresh or clear the session', () async {
    final adapter = _ScriptedAdapter([
      (_) => _json(403, {
        'error': {'code': 'AUTH_FORBIDDEN', 'message': 'forbidden'},
      }),
    ]);
    final client = _client(adapter: adapter);
    await expectLater(
      client.dio.get<Map<String, dynamic>>('/driver/me'),
      throwsA(isA<DioException>()),
    );
    expect(client.auth.refreshCount, 0);
    expect(client.store.value, isNotNull);
    expect(client.invalidated(), 0);
  });

  test('logout during refresh does not restore the previous session', () async {
    final adapter = _ScriptedAdapter([
      (_) => _json(401, {
        'error': {'code': 'AUTH_INVALID_TOKEN', 'message': 'expired'},
      }),
    ]);
    final store = MemorySessionStore()..value = _initial;
    final cache = TokenCache()..current = _initial;
    final auth = FakeAuthClient()
      ..refreshDelay = const Duration(milliseconds: 40);
    var generation = 1;
    final refresher = TokenRefresher(
      authApi: auth,
      store: store,
      cache: cache,
      currentGeneration: () => generation,
    );
    var invalidated = 0;
    const config = ApiConfig(apiBaseUrl: 'http://127.0.0.1:3000/api/v1');
    final dio = createApiClient(
      config: config,
      readSession: () async => cache.current ?? await store.read(),
      refresher: refresher,
      onSessionInvalid: () async {
        invalidated += 1;
        cache.current = null;
        await store.clear();
      },
    );
    dio.httpClientAdapter = adapter;

    final pending = dio.get<Map<String, dynamic>>('/auth/me');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    generation += 1;
    cache.current = const TokenPair(
      accessToken: 'access-new',
      refreshToken: 'refresh-new-token-value',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
    await store.write(cache.current!);

    await expectLater(pending, throwsA(isA<DioException>()));
    expect(store.value?.accessToken, 'access-new');
    expect(cache.current?.accessToken, 'access-new');
    expect(invalidated, 0);
    expect(auth.refreshCount, 1);
  });
}
