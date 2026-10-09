import 'package:flutter/material.dart';

/// Stitch "Vitesse System" tokens for the SpeedyGo Driver app.
///
/// Colors, spacing and radii only — no business logic. Primary blue #0A4096,
/// surface #FAF8FF, edge margin 16, minimum touch target 48, radii 8–16.
class DriverTokens {
  DriverTokens._();

  // Colors
  static const Color primary = Color(0xFF0A4096);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD9E2FF);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFC4C6D0);
  static const Color textPrimary = Color(0xFF1A1B22);
  static const Color textSecondary = Color(0xFF434652);
  static const Color success = Color(0xFF1B7F4B);
  static const Color successContainer = Color(0xFFD6F2E2);
  static const Color warning = Color(0xFF9A5B00);
  static const Color warningContainer = Color(0xFFFFE9C7);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color dangerContainer = Color(0xFFFFDAD6);
  static const Color neutralContainer = Color(0xFFE9E7F0);

  // Spacing
  static const double edgeMargin = 16;
  static const double touchTarget = 48;
  static const double actionHeight = 56;
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  // Radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
}
