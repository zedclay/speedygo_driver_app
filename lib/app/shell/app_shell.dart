import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/features/auth/presentation/splash_screen.dart';

/// Retained for compatibility; splash now owns bootstrap.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
