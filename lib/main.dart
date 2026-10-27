import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/app/app.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/notifications/application/driver_push_controller.dart';
import 'package:speedygo_driver_app/features/notifications/data/push_messaging_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final push = await FirebasePushMessagingGateway.bootstrap();
  final container = ProviderContainer(
    overrides: [pushMessagingGatewayProvider.overrideWithValue(push)],
  );
  await container.read(localeControllerProvider.notifier).restore();
  runApp(
    UncontrolledProviderScope(container: container, child: const SpeedyGoApp()),
  );
}
