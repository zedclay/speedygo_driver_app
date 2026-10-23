import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speedygo_driver_app/core/locale/locale_support.dart';

/// Persists Driver UI locale only — never tokens, OTP, or pickup codes.
abstract class LocaleStore {
  Future<String?> read();
  Future<void> write(String languageCode);
}

class SecureLocaleStore implements LocaleStore {
  SecureLocaleStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'speedygo.driver.locale.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    return sanitizeLanguageCode(raw);
  }

  @override
  Future<void> write(String languageCode) {
    return _storage.write(key: _key, value: sanitizeLanguageCode(languageCode));
  }
}

class MemoryLocaleStore implements LocaleStore {
  MemoryLocaleStore({String? locale}) : _locale = locale;

  String? _locale;

  @override
  Future<String?> read() async => _locale;

  @override
  Future<void> write(String languageCode) async {
    _locale = sanitizeLanguageCode(languageCode);
  }
}
