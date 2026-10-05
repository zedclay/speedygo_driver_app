import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';

final appNameProvider = Provider<String>((ref) {
  ref.watch(localeControllerProvider);
  return AppStrings.appName;
});
