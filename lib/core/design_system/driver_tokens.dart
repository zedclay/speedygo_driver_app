import 'package:flutter/material.dart';

/// SpeedyGo Driver — Modern White design tokens (28-screen package).
///
/// White surfaces, navy headings, electric blue accents. Verification accents
/// (cobalt / cool-white) retained for pending / approved / corrections.
class DriverTokens {
  DriverTokens._();

  // Brand / surfaces (Modern White)
  static const Color primary = Color(0xFF2563EB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);

  /// Soft tint for chips / nav indicators.
  static const Color primaryFixed = Color(0xFFDBEAFE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerContainer = Color(0xFFFEE2E2);
  static const Color neutralContainer = Color(0xFFF1F5F9);

  /// Online accent (green status); offline uses outline.
  static const Color tertiary = Color(0xFF16A34A);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFDCFCE7);
  static const Color tertiaryFixed = Color(0xFFBBF7D0);
  static const Color onTertiaryFixed = Color(0xFF14532D);
  static const Color secondaryFixed = Color(0xFFDBEAFE);
  static const Color onSecondaryFixed = Color(0xFF1E3A8A);

  // Brand navy for headings / logo (not filled AppBar)
  static const Color navy = Color(0xFF0F172A);
  static const Color cobalt = Color(0xFF2563EB);
  static const Color coolWhite = Color(0xFFF8FAFC);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successGreenSoft = Color(0xFFDCFCE7);
  static const Color amber = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFEF3C7);

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
  static const double radiusPill = 999;

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: navy.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
