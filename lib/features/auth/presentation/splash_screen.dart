import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/constants/driver_assets.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/presentation/splash_backdrop.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loaderTurns;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _loaderTurns = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      _started = true;
      if (!MediaQuery.disableAnimationsOf(context)) {
        _loaderTurns.repeat();
      }
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final minHold = ref.read(splashMinDurationProvider);
    final startedAt = DateTime.now();
    await ref.read(localeControllerProvider.notifier).restore();
    await ref.read(sessionControllerProvider.notifier).restore();
    if (!mounted) return;
    final target = await ref
        .read(driverNavSnapshotProvider.notifier)
        .resolveAfterSession();
    if (!mounted) return;

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = minHold - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;
    context.go(target);
  }

  @override
  void dispose() {
    _loaderTurns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final logoSize = DriverSplashMetrics.logoAssetSize(size);
    final glowSize = 242 * DriverSplashMetrics.scale(size);
    final loaderBottom = DriverSplashMetrics.loaderBottom > padding.bottom + 24
        ? DriverSplashMetrics.loaderBottom
        : padding.bottom + 24;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: const Key('splash_screen'),
        backgroundColor: const Color(0xFF051944),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: DriverSplashMetrics.gradient),
            ),
            const CustomPaint(painter: DriverSplashBackdropPainter()),
            Positioned(
              top:
                  size.height * DriverSplashMetrics.logoVerticalFactor -
                  logoSize / 2,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: glowSize > logoSize ? glowSize : logoSize,
                    height: glowSize > logoSize ? glowSize : logoSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IgnorePointer(
                          child: Container(
                            width: glowSize,
                            height: glowSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Color.fromRGBO(56, 126, 245, 0.45),
                                  Color.fromRGBO(20, 75, 180, 0.15),
                                  Color(0x00000000),
                                ],
                                stops: [0.0, 0.55, 0.75],
                              ),
                            ),
                          ),
                        ),
                        Image.asset(
                          DriverAssets.logo,
                          key: const Key('splash-logo'),
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          semanticLabel: AppStrings.appName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      AppStrings.splashTagline,
                      key: const Key('splash-tagline'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: loaderBottom,
              child: Center(
                child: reduceMotion
                    ? const CustomPaint(
                        key: Key('splash-loader'),
                        size: Size.square(DriverSplashMetrics.loaderSize),
                        painter: DriverSplashLoaderPainter(),
                      )
                    : RotationTransition(
                        turns: _loaderTurns,
                        child: const CustomPaint(
                          key: Key('splash-loader'),
                          size: Size.square(DriverSplashMetrics.loaderSize),
                          painter: DriverSplashLoaderPainter(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
