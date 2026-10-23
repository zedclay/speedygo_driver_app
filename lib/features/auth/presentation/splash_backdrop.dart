import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Brand metrics for the Driver splash composition.
class DriverSplashMetrics {
  const DriverSplashMetrics._();

  static const designWidth = 390.0;
  static const logoBox = 146.0;
  static const assetVisibleFraction = 394 / 500;
  static const loaderSize = 28.0;
  static const loaderBottom = 98.0;
  static const logoVerticalFactor = 0.42;

  static const gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF135BC9),
      Color(0xFF0A4096),
      Color(0xFF08307D),
      Color(0xFF06225B),
      Color(0xFF051944),
    ],
    stops: [0.0, 0.28, 0.58, 0.82, 1.0],
  );

  static double scale(Size size) => size.width / designWidth;

  static double logoAssetSize(Size size) {
    return logoBox / assetVisibleFraction * scale(size);
  }
}

/// Subtle route curves + glows on the Driver primary blue field.
class DriverSplashBackdropPainter extends CustomPainter {
  const DriverSplashBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = DriverSplashMetrics.scale(size);

    final topSweep = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.08, h * 0.02),
        w * 0.85,
        const [
          Color.fromRGBO(96, 165, 250, 0.28),
          Color.fromRGBO(37, 99, 235, 0.08),
          Color(0x00000000),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(Offset(w * 0.05, -h * 0.02), w * 0.7, topSweep);

    final bottomGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.9, h * 0.92),
        w * 0.75,
        [
          DriverTokens.primaryContainer.withValues(alpha: 0.22),
          const Color(0x00000000),
        ],
        const [0.0, 1.0],
      );
    canvas.drawCircle(Offset(w * 0.95, h * 1.02), w * 0.65, bottomGlow);

    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s.clamp(0.85, 1.2)
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.14);

    final softPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * s.clamp(0.85, 1.2)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = Colors.white.withValues(alpha: 0.08);

    final upper = Path()
      ..moveTo(-w * 0.1, h * 0.22)
      ..cubicTo(w * 0.2, h * 0.05, w * 0.55, h * 0.28, w * 1.05, h * 0.12);
    canvas.drawPath(upper, softPaint);
    canvas.drawPath(upper, curvePaint);

    final mid = Path()
      ..moveTo(-w * 0.08, h * 0.48)
      ..cubicTo(w * 0.25, h * 0.38, w * 0.65, h * 0.58, w * 1.08, h * 0.44);
    canvas.drawPath(mid, softPaint);
    canvas.drawPath(mid, curvePaint);

    final lower = Path()
      ..moveTo(-w * 0.05, h * 0.82)
      ..cubicTo(w * 0.3, h * 0.68, w * 0.7, h * 0.92, w * 1.1, h * 0.74);
    canvas.drawPath(lower, softPaint);
    canvas.drawPath(lower, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DriverSplashLoaderPainter extends CustomPainter {
  const DriverSplashLoaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = Colors.white.withValues(alpha: 0.22);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.2,
      1.8,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
