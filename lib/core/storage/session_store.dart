import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speedygo_driver_app/features/auth/data/models.dart';

/// Driver-only session keys — never shared with Customer/Merchant storage.
abstract class SessionStore {
  Future<TokenPair?> read();
  Future<void> write(TokenPair pair);
  Future<void> clear();
  Future<bool> isRefreshPending();
  Future<void> markRefreshPending();
  Future<void> clearRefreshPending();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'speedygo.driver.session.v1';
  static const _pendingKey = 'speedygo.driver.refresh-pending.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<TokenPair?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        await clear();
        return null;
      }
      return TokenPair.fromJson(map);
    } on FormatException {
      await clear();
      return null;
    } on SessionParseException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(TokenPair pair) {
    return _storage.write(key: _key, value: jsonEncode(pair.toJson()));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _pendingKey);
  }

  @override
  Future<bool> isRefreshPending() async {
    return await _storage.read(key: _pendingKey) == '1';
  }

  @override
  Future<void> markRefreshPending() {
    return _storage.write(key: _pendingKey, value: '1');
  }

  @override
  Future<void> clearRefreshPending() {
    return _storage.delete(key: _pendingKey);
  }
}

class MemorySessionStore implements SessionStore {
  TokenPair? value;
  bool refreshPending = false;

  @override
  Future<TokenPair?> read() async => value;

  @override
  Future<void> write(TokenPair pair) async {
    value = pair;
  }

  @override
  Future<void> clear() async {
    value = null;
    refreshPending = false;
  }

  @override
  Future<bool> isRefreshPending() async => refreshPending;

  @override
  Future<void> markRefreshPending() async {
    refreshPending = true;
  }

  @override
  Future<void> clearRefreshPending() async {
    refreshPending = false;
  }
}

class TokenCache {
  TokenPair? current;
}
