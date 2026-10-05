import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(localeControllerProvider.notifier).restore();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SpeedyGoApp(),
    ),
  );
}
