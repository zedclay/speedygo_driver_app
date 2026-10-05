import 'package:speedygo_driver_app/core/errors/app_exception.dart';
import 'package:speedygo_driver_app/core/storage/session_store.dart';
import 'package:speedygo_driver_app/features/auth/data/auth_api.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';

typedef SessionGeneration = int Function();

class TokenRefresher {
  TokenRefresher({
    required this._authApi,
    required this._store,
    required this._cache,
    required this._currentGeneration,
  });

  final AuthClient _authApi;
  final SessionStore _store;
  final TokenCache _cache;
  final SessionGeneration _currentGeneration;

  Future<TokenPair>? _inFlight;

  Future<TokenPair> ensureFresh({String? failedAccessToken}) {
    final cached = _cache.current;
    if (_alreadyRotated(cached, failedAccessToken)) {
      return Future<TokenPair>.value(cached);
    }
    return _inFlight ??= _run();
  }

  Future<TokenPair> _run() async {
    final generation = _currentGeneration();
    try {
      if (await _store.isRefreshPending()) {
        await _dropLocalPair();
        throw const RefreshAmbiguousException();
      }
      final session = _cache.current ?? await _store.read();
      final refreshToken = session?.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_INVALID_TOKEN',
        );
      }
      await _store.markRefreshPending();
      final pair = await _authApi.refresh(refreshToken);
      if (_currentGeneration() != generation) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_STALE_REFRESH',
        );
      }
      await _store.write(pair);
      await _store.clearRefreshPending();
      if (_currentGeneration() != generation) {
        throw const ApiException(
          'Session remplacée.',
          code: 'AUTH_STALE_REFRESH',
        );
      }
      _cache.current = pair;
      return pair;
    } on RefreshAmbiguousException {
      await _dropLocalPair();
      rethrow;
    } on ApiException catch (error) {
      if (error.isAuthFailure) {
        await _dropLocalPair();
      } else {
        await _store.clearRefreshPending();
      }
      rethrow;
    } catch (_) {
      await _store.clearRefreshPending();
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  bool _alreadyRotated(TokenPair? current, String? failedAccessToken) {
    if (current == null ||
        failedAccessToken == null ||
        failedAccessToken.isEmpty) {
      return false;
    }
    return current.accessToken != failedAccessToken;
  }

  Future<void> _dropLocalPair() async {
    _cache.current = null;
    await _store.clear();
  }
}
