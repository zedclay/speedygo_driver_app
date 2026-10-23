import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/app/router/driver_bootstrap_controller.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/phone_input.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    await ref.read(sessionControllerProvider.notifier).verifyOtp(code);
    if (!mounted) return;
    final status = ref.read(sessionControllerProvider).status;
    if (status == SessionStatus.signedOut || status == SessionStatus.unknown) {
      return;
    }
    if (status == SessionStatus.signedIn ||
        status == SessionStatus.needsDriverProfile) {
      final target = await ref
          .read(driverNavSnapshotProvider.notifier)
          .resolveAfterSession();
      if (!mounted) return;
      context.go(target);
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(sessionControllerProvider).pendingPhone;
    if (phone == null || phone.isEmpty) return;
    await ref.read(sessionControllerProvider.notifier).requestOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final phone = session.pendingPhone ?? '';
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    final seconds = session.otpResendSecondsRemaining;
    final clock = '00:${seconds.toString().padLeft(2, '0')}';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final masked = PhoneInput.maskInternational(phone);

    return Scaffold(
      backgroundColor: DriverTokens.coolWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: AppStrings.back,
                      onPressed: () => context.go(AppRoutes.phone),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const Key('otp_language'),
                      tooltip: AppStrings.languageSettingsTitle,
                      onPressed: () =>
                          context.push(AppRoutes.languageSettingsAuth),
                      icon: const Icon(
                        Icons.language,
                        color: DriverTokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  Text(
                    AppStrings.otpTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      height: 32 / 24,
                      letterSpacing: -0.2,
                      color: DriverTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          AppStrings.otpSentTo(masked),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: DriverTokens.onSurfaceVariant,
                                fontSize: 16,
                                height: 24 / 16,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.phone),
                        style: TextButton.styleFrom(
                          foregroundColor: DriverTokens.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: DriverTokens.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                height: 24 / 16,
                              ),
                        ),
                        child: Text(AppStrings.editNumber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: _OtpBoxes(
                      code: code,
                      hasError: session.errorMessage != null,
                      onTap: () => _focus.requestFocus(),
                      child: TextField(
                        key: const Key('otp_field'),
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                            AppConstants.otpLength,
                          ),
                        ],
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 1,
                        ),
                        cursorColor: Colors.transparent,
                        showCursor: false,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) {
                          ref
                              .read(sessionControllerProvider.notifier)
                              .dismissError();
                          setState(() {});
                        },
                        onSubmitted: (_) {
                          if (code.length == AppConstants.otpLength) {
                            _verify();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  seconds > 0
                      ? Builder(
                          builder: (context) {
                            final label = AppStrings.resendIn(clock);
                            final prefixLen = label.length - clock.length;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: DriverTokens.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text.rich(
                                    TextSpan(
                                      text: label.substring(0, prefixLen),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color:
                                                DriverTokens.onSurfaceVariant,
                                            fontSize: 14,
                                            height: 20 / 14,
                                          ),
                                      children: [
                                        TextSpan(
                                          text: clock,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: DriverTokens.onSurface,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                height: 20 / 14,
                                              ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : Center(
                          child: TextButton(
                            onPressed: session.busy ? null : _resend,
                            style: TextButton.styleFrom(
                              foregroundColor: DriverTokens.primary,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(AppStrings.resend),
                          ),
                        ),
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      session.errorMessage!,
                      style: const TextStyle(color: DriverTokens.danger),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                bottomInset > 0 ? 8 : 32,
              ),
              child: SizedBox(
                height: DriverTokens.actionHeight,
                width: double.infinity,
                child: FilledButton(
                  key: const Key('otp_verify'),
                  onPressed:
                      code.length == AppConstants.otpLength && !session.busy
                      ? _verify
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: DriverTokens.primary,
                    foregroundColor: DriverTokens.onPrimary,
                    disabledBackgroundColor: DriverTokens.outlineVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusMd,
                      ),
                    ),
                  ),
                  child: session.busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DriverTokens.onPrimary,
                          ),
                        )
                      : Text(AppStrings.verify),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.code,
    required this.onTap,
    required this.child,
    this.hasError = false,
  });

  final String code;
  final bool hasError;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: List.generate(AppConstants.otpLength, (index) {
              final filled = index < code.length;
              final focused =
                  index == code.length ||
                  (code.length == AppConstants.otpLength &&
                      index == AppConstants.otpLength - 1);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == AppConstants.otpLength - 1 ? 0 : 12,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DriverTokens.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusMd,
                      ),
                      border: Border.all(
                        color: hasError
                            ? DriverTokens.danger
                            : focused
                            ? DriverTokens.primaryContainer
                            : DriverTokens.outlineVariant,
                        width: hasError || focused ? 2 : 1,
                      ),
                      boxShadow: focused && !hasError
                          ? const [
                              BoxShadow(
                                color: Color(0x140A4096),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filled ? code[index] : '',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            height: 32 / 24,
                            color: DriverTokens.onSurface,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(child: Opacity(opacity: 0.01, child: child)),
        ],
      ),
    );
  }
}
