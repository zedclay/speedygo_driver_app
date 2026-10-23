import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local-only first-launch intro completion. Never tokens, OTP, or Backend data.
abstract class FirstLaunchIntroStore {
  Future<bool> isCompleted();
  Future<void> markCompleted();

  /// Test / debug-harness only — must not be wired into release UI.
  Future<void> resetForTests();
}

class SecureFirstLaunchIntroStore implements FirstLaunchIntroStore {
  SecureFirstLaunchIntroStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'driver_first_launch_intro_v1_completed';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> isCompleted() async {
    final raw = await _storage.read(key: key);
    return raw == 'true';
  }

  @override
  Future<void> markCompleted() {
    return _storage.write(key: key, value: 'true');
  }

  @override
  Future<void> resetForTests() {
    return _storage.delete(key: key);
  }
}

class MemoryFirstLaunchIntroStore implements FirstLaunchIntroStore {
  MemoryFirstLaunchIntroStore({this.completed = false});

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }

  @override
  Future<void> resetForTests() async {
    completed = false;
  }
}

final firstLaunchIntroStoreProvider = Provider<FirstLaunchIntroStore>((ref) {
  return SecureFirstLaunchIntroStore();
});
