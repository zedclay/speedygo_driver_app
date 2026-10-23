import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_store.dart';

/// `null` until [restore]; then whether first-launch intro was completed/skipped.
final firstLaunchIntroCompletedProvider =
    NotifierProvider<FirstLaunchIntroController, bool?>(
      FirstLaunchIntroController.new,
    );

class FirstLaunchIntroController extends Notifier<bool?> {
  @override
  bool? build() => null;

  FirstLaunchIntroStore get _store => ref.read(firstLaunchIntroStoreProvider);

  Future<void> restore() async {
    state = await _store.isCompleted();
  }

  Future<void> complete() async {
    await _store.markCompleted();
    state = true;
  }

  /// Test / debug harness only.
  Future<void> resetForTests() async {
    await _store.resetForTests();
    state = false;
  }
}
