import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/network/api_client.dart';
import 'package:speedygo_driver_app/core/network/api_config.dart';
import 'package:speedygo_driver_app/core/network/token_refresher.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});

/// Brand hold on splash before cold-start navigation. Tests override to zero.
final splashMinDurationProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 2500);
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SecureSessionStore();
});

final tokenCacheProvider = Provider<TokenCache>((ref) => TokenCache());

class SessionEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final sessionEpochProvider = NotifierProvider<SessionEpoch, int>(
  SessionEpoch.new,
);

final refreshDioProvider = Provider<Dio>((ref) {
  return createRefreshClient(config: ref.watch(apiConfigProvider));
});

final authApiProvider = Provider<AuthClient>((ref) {
  final dio = ref.watch(apiClientProvider);
  final refreshDio = ref.watch(refreshDioProvider);
  return AuthApi(dio: dio, refreshDio: refreshDio);
});

final tokenRefresherProvider = Provider<TokenRefresher>((ref) {
  return TokenRefresher(
    authApi: AuthApi(
      dio: ref.watch(refreshDioProvider),
      refreshDio: ref.watch(refreshDioProvider),
    ),
    store: ref.watch(sessionStoreProvider),
    cache: ref.watch(tokenCacheProvider),
    currentGeneration: () => ref.read(sessionEpochProvider),
  );
});

final apiClientProvider = Provider<Dio>((ref) {
  final store = ref.watch(sessionStoreProvider);
  final cache = ref.watch(tokenCacheProvider);
  final refresher = ref.watch(tokenRefresherProvider);
  return createApiClient(
    config: ref.watch(apiConfigProvider),
    readSession: () async => cache.current ?? await store.read(),
    refresher: refresher,
    onSessionInvalid: () async {
      cache.current = null;
      await store.clear();
      ref.read(sessionEpochProvider.notifier).bump();
      ref.read(sessionControllerProvider.notifier).markSignedOut();
    },
  );
});

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
