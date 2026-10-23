import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Light theme aligned with Stitch Vitesse System / DriverTokens.
///
/// Replaces the previous teal seed (0xFF0F766E) with SpeedyGo primary blue
/// so shell, availability, and delivery screens share one brand surface.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: DriverTokens.primary,
      brightness: Brightness.light,
      primary: DriverTokens.primary,
      onPrimary: DriverTokens.onPrimary,
      primaryContainer: DriverTokens.primaryContainer,
      surface: DriverTokens.surface,
      error: DriverTokens.danger,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: DriverTokens.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: DriverTokens.card,
        foregroundColor: DriverTokens.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: DriverTokens.card,
        indicatorColor: DriverTokens.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DriverTokens.textSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            DriverTokens.touchTarget,
            DriverTokens.actionHeight,
          ),
          backgroundColor: DriverTokens.primary,
          foregroundColor: DriverTokens.onPrimary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            DriverTokens.touchTarget,
            DriverTokens.actionHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DriverTokens.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
        ),
      ),
      cardTheme: CardThemeData(
        color: DriverTokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
          side: const BorderSide(color: DriverTokens.outline),
        ),
      ),
    );
  }
}
