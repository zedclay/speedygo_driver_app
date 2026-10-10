import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/constants/driver_assets.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/first_launch_intro/application/first_launch_intro_controller.dart';

class FirstLaunchIntroScreen extends ConsumerStatefulWidget {
  const FirstLaunchIntroScreen({super.key});

  @override
  ConsumerState<FirstLaunchIntroScreen> createState() =>
      _FirstLaunchIntroScreenState();
}

class _FirstLaunchIntroScreenState
    extends ConsumerState<FirstLaunchIntroScreen> {
  static const _pageCount = 3;

  late final PageController _pageController;
  var _page = 0;
  var _completing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int page) async {
    if (_completing || page < 0 || page >= _pageCount) return;
    setState(() => _page = page);
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onPrimary() async {
    if (_completing) return;
    if (_page < _pageCount - 1) {
      await _goTo(_page + 1);
      return;
    }
    await _finishIntro();
  }

  Future<void> _onSkip() async {
    if (_completing || _page >= _pageCount - 1) return;
    await _finishIntro();
  }

  Future<void> _finishIntro() async {
    if (_completing) return;
    setState(() {
      _completing = true;
      _error = null;
    });
    try {
      await ref.read(firstLaunchIntroCompletedProvider.notifier).complete();
      if (!mounted) return;
      final target = await ref
          .read(driverNavSnapshotProvider.notifier)
          .resolveAfterSession();
      if (!mounted) return;
      context.go(target);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completing = false;
        _error = AppStrings.unexpectedError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final textScale = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final forwardIcon = isRtl ? Icons.arrow_back : Icons.arrow_forward;

    return PopScope(
      canPop: _page == 0 && !_completing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _completing) return;
        if (_page > 0) {
          _goTo(_page - 1);
        }
      },
      child: Scaffold(
        key: const Key('first_launch_intro_screen'),
        backgroundColor: Colors.white,
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScale),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    DriverTokens.edgeMargin,
                    8,
                    DriverTokens.edgeMargin,
                    0,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        DriverAssets.logo,
                        key: const Key('first_launch_intro_logo'),
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: AppStrings.appName,
                      ),
                      const Spacer(),
                      if (_page < _pageCount - 1)
                        TextButton(
                          key: const Key('first_launch_intro_skip'),
                          onPressed: _completing ? null : _onSkip,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(
                              DriverTokens.touchTarget,
                              DriverTokens.touchTarget,
                            ),
                            foregroundColor: DriverTokens.primary,
                          ),
                          child: Text(AppStrings.firstLaunchIntroSkip),
                        )
                      else
                        const SizedBox(
                          width: DriverTokens.touchTarget,
                          height: DriverTokens.touchTarget,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    key: const Key('first_launch_intro_pager'),
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (_completing) return;
                      setState(() => _page = index);
                    },
                    children: [
                      _IntroPage(
                        key: const Key('first_launch_intro_page_0'),
                        illustration: DriverAssets.firstLaunchIntro1,
                        title: AppStrings.firstLaunchIntroPage1Title,
                        body: AppStrings.firstLaunchIntroPage1Body,
                        pageIndex: 0,
                      ),
                      _IntroPage(
                        key: const Key('first_launch_intro_page_1'),
                        illustration: DriverAssets.firstLaunchIntro2,
                        title: AppStrings.firstLaunchIntroPage2Title,
                        body: AppStrings.firstLaunchIntroPage2Body,
                        pageIndex: 1,
                      ),
                      _IntroPage(
                        key: const Key('first_launch_intro_page_2'),
                        illustration: DriverAssets.firstLaunchIntro3,
                        title: AppStrings.firstLaunchIntroPage3Title,
                        body: AppStrings.firstLaunchIntroPage3Body,
                        pageIndex: 2,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    DriverTokens.edgeMargin,
                    8,
                    DriverTokens.edgeMargin,
                    16,
                  ),
                  child: Column(
                    children: [
                      Semantics(
                        label: AppStrings.firstLaunchIntroPageSemantics(
                          _page + 1,
                          _pageCount,
                        ),
                        child: _PageIndicator(
                          key: const Key('first_launch_intro_indicator'),
                          page: _page,
                          count: _pageCount,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          key: const Key('first_launch_intro_error'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: DriverTokens.danger,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: DriverTokens.actionHeight,
                        child: FilledButton(
                          key: const Key('first_launch_intro_primary'),
                          onPressed: _completing ? null : _onPrimary,
                          style: FilledButton.styleFrom(
                            backgroundColor: DriverTokens.primary,
                            foregroundColor: DriverTokens.onPrimary,
                            disabledBackgroundColor: DriverTokens.primary
                                .withValues(alpha: 0.55),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: _completing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: DriverTokens.onPrimary,
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _page == _pageCount - 1
                                            ? AppStrings.firstLaunchIntroStart
                                            : AppStrings.firstLaunchIntroNext,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Icon(forwardIcon, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    super.key,
    required this.illustration,
    required this.title,
    required this.body,
    required this.pageIndex,
  });

  final String illustration;
  final String title;
  final String body;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DriverTokens.edgeMargin),
      child: Column(
        children: [
          Expanded(
            flex: 11,
            child: ExcludeSemantics(
              child: Image.asset(
                illustration,
                key: Key('first_launch_intro_illustration_$pageIndex'),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            key: Key('first_launch_intro_title_$pageIndex'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0A3078),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            key: Key('first_launch_intro_body_$pageIndex'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: DriverTokens.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({super.key, required this.page, required this.count});

  final int page;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            key: Key('first_launch_intro_dot_$i'),
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == page ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == page ? DriverTokens.primary : const Color(0xFFB8C7E8),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}
