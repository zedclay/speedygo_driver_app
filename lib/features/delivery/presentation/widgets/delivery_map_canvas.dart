import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Static map placeholder — no live map provider is configured in this app.
class DeliveryMapCanvas extends StatelessWidget {
  const DeliveryMapCanvas({super.key, required this.toMerchant});

  final bool toMerchant;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DriverTokens.surfaceContainer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _MapGridPainter()),
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 72,
              color: DriverTokens.primary.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 48,
            child: _Marker(
              icon: Icons.local_shipping,
              label: AppStrings.deliveryMapYou,
              filled: true,
            ),
          ),
          Positioned(
            right: 32,
            top: 56,
            child: _Marker(
              icon: toMerchant ? Icons.storefront_outlined : Icons.place,
              label: toMerchant
                  ? AppStrings.deliveryMapMerchant
                  : AppStrings.deliveryMapCustomer,
              filled: false,
            ),
          ),
          Positioned(
            right: DriverTokens.edgeMargin,
            bottom: 32,
            child: Column(
              children: [
                _MapFab(icon: Icons.my_location),
                const SizedBox(height: DriverTokens.spaceSm),
                _MapFab(icon: Icons.near_me),
              ],
            ),
          ),
          Positioned(
            left: DriverTokens.edgeMargin,
            right: DriverTokens.edgeMargin,
            bottom: DriverTokens.spaceMd,
            child: Text(
              AppStrings.navUnavailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: DriverTokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DriverTokens.card,
      elevation: 3,
      shape: const CircleBorder(
        side: BorderSide(color: DriverTokens.outlineVariant),
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, color: DriverTokens.primary),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.icon,
    required this.label,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: DriverTokens.card,
            borderRadius: BorderRadius.circular(DriverTokens.radiusSm),
            boxShadow: DriverTokens.cardShadow,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: DriverTokens.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 18,
          backgroundColor: filled ? DriverTokens.primary : DriverTokens.card,
          child: Icon(
            icon,
            size: 20,
            color: filled ? DriverTokens.onPrimary : DriverTokens.primary,
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DriverTokens.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final route = Paint()
      ..color = DriverTokens.primary.withValues(alpha: 0.55)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.35, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.45,
        size.width * 0.62,
        size.height * 0.22,
      );
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
