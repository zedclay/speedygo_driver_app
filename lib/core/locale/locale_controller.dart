import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_store.dart';
import 'package:speedygo_driver_app/core/locale/locale_support.dart';

final localeStoreProvider = Provider<LocaleStore>((ref) {
  return SecureLocaleStore();
});

class LocaleController extends Notifier<String> {
  @override
  String build() {
    AppStrings.bind('fr');
    return 'fr';
  }

  Future<void> restore() async {
    final stored = await ref.read(localeStoreProvider).read();
    final code = resolveInitialLanguageCode(stored: stored);
    AppStrings.bind(code);
    state = code;
  }

  Future<void> setLocale(String languageCode) async {
    final code = sanitizeLanguageCode(languageCode);
    await ref.read(localeStoreProvider).write(code);
    AppStrings.bind(code);
    state = code;
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, String>(
  LocaleController.new,
);
