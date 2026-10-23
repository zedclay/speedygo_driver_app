import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/core/utils/phone_input.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    final pending = ref.read(sessionControllerProvider).pendingPhone;
    if (pending != null && pending.isNotEmpty) {
      _controller.text = PhoneInput.formatLocal(pending);
    }
    _syncCooldownTicker(ref.read(sessionControllerProvider));
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncCooldownTicker(SessionState session) {
    if (session.otpResendSecondsRemaining > 0) {
      _cooldownTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final left = ref
            .read(sessionControllerProvider)
            .otpResendSecondsRemaining;
        setState(() {});
        if (left <= 0) {
          _cooldownTicker?.cancel();
          _cooldownTicker = null;
        }
      });
    } else {
      _cooldownTicker?.cancel();
      _cooldownTicker = null;
    }
  }

  Future<void> _submit() async {
    final current = ref.read(sessionControllerProvider);
    if (!current.canRequestOtp || current.busy) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .requestOtp(_controller.text);
    if (!mounted) return;
    final next = ref.read(sessionControllerProvider);
    _syncCooldownTicker(next);
    if (next.pendingPhone != null && next.errorMessage == null) {
      context.go(AppRoutes.otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final valid = PhoneInput.isValid(_controller.text);
    final canSubmit = valid && !session.busy && session.canRequestOtp;
    final cooldown = session.otpResendSecondsRemaining;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasError = session.errorMessage != null;
    final focused = _focus.hasFocus;

    ref.listen(sessionControllerProvider, (_, next) {
      _syncCooldownTicker(next);
    });

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
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: session.pendingPhone != null
                          ? IconButton(
                              tooltip: AppStrings.back,
                              padding: EdgeInsets.zero,
                              onPressed: () => context.go(AppRoutes.otp),
                              icon: const Icon(Icons.arrow_back),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.appNameShort,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: DriverTokens.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              height: 32 / 24,
                            ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        key: const Key('phone_language'),
                        tooltip: AppStrings.languageSettingsTitle,
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            context.push(AppRoutes.languageSettingsAuth),
                        icon: const Icon(Icons.language),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                children: [
                  Text(
                    AppStrings.phoneTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      height: 32 / 24,
                      color: DriverTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.phoneSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: DriverTokens.onSurfaceVariant,
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Semantics(
                      label: AppStrings.phoneTitle,
                      textField: true,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 64,
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
                            width: focused || hasError ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const _AlgeriaFlag(),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.phonePrefix,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 24 / 16,
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 28,
                              color: DriverTokens.outlineVariant,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                key: const Key('phone_field'),
                                controller: _controller,
                                focusNode: _focus,
                                autofocus: true,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      height: 24 / 16,
                                      letterSpacing: 0.4,
                                      color: DriverTokens.onSurface,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: InputDecoration(
                                  hintText: AppStrings.phoneHint,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  ref
                                      .read(sessionControllerProvider.notifier)
                                      .dismissError();
                                  final formatted = PhoneInput.formatLocal(
                                    value,
                                  );
                                  if (formatted != value) {
                                    _controller.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(
                                        offset: formatted.length,
                                      ),
                                    );
                                  }
                                  setState(() {});
                                },
                                onSubmitted: (_) {
                                  if (canSubmit) _submit();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      AppStrings.phoneSmsNote,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DriverTokens.onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (cooldown > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${AppStrings.otpCooldownHint} ($cooldown s)',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: DriverTokens.onSurfaceVariant),
                    ),
                  ],
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      session.errorMessage!,
                      style: const TextStyle(color: DriverTokens.danger),
                    ),
                  ],
                  const SizedBox(height: 32),
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.2,
                      child: Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00000000),
                              DriverTokens.primaryContainer,
                              Color(0x00000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: DriverTokens.coolWhite.withValues(alpha: 0.8),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      bottomInset > 0 ? 8 : 16,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: DriverTokens.actionHeight,
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('phone_continue'),
                            onPressed: canSubmit ? _submit : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: DriverTokens.primary,
                              foregroundColor: DriverTokens.onPrimary,
                              disabledBackgroundColor:
                                  DriverTokens.outlineVariant,
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
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(AppStrings.continueLabel),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.helpUnavailable),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: DriverTokens.primary,
                            textStyle: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: DriverTokens.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                          ),
                          child: Text(AppStrings.needHelp),
                        ),
                      ],
                    ),
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

class _AlgeriaFlag extends StatelessWidget {
  const _AlgeriaFlag();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 24,
        height: 16,
        child: Row(
          children: [
            const Expanded(child: ColoredBox(color: Color(0xFF006233))),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD21034)),
                      shape: BoxShape.circle,
                    ),
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
