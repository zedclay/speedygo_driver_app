import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef StoredPushToken = ({String token, String platform, String? accountId});

/// Widget-test bindings have no secure-storage plugin. The platform channel
/// can hang until the test timeout instead of throwing MissingPluginException.
bool _automatedWidgetTest() {
  try {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'AutomatedTestWidgets',
    );
  } catch (_) {
    return false;
  }
}

class DriverPushRegistration {
  DriverPushRegistration({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'driver_device_push_token';
  static const _platformKey = 'driver_device_push_platform';
  static const _accountKey = 'driver_device_push_account';

  Future<void> storeRegisteredToken({
    required String token,
    required String platform,
    required String? accountId,
  }) async {
    if (_automatedWidgetTest()) return;
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _platformKey, value: platform);
      if (accountId == null) {
        await _storage.delete(key: _accountKey);
      } else {
        await _storage.write(key: _accountKey, value: accountId);
      }
    } catch (e) {
      debugPrint('push token store failed: $e');
    }
  }

  Future<StoredPushToken?> loadStoredToken() async {
    if (_automatedWidgetTest()) return null;
    try {
      final token = await _storage.read(key: _tokenKey);
      final platform = await _storage.read(key: _platformKey);
      if (token == null ||
          token.isEmpty ||
          platform == null ||
          platform.isEmpty) {
        return null;
      }
      final accountId = await _storage.read(key: _accountKey);
      return (token: token, platform: platform, accountId: accountId);
    } catch (e) {
      debugPrint('push token load failed: $e');
      return null;
    }
  }

  Future<void> clearStoredToken() async {
    if (_automatedWidgetTest()) return;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _platformKey);
      await _storage.delete(key: _accountKey);
    } catch (e) {
      debugPrint('push token clear failed: $e');
    }
  }
}
