import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_driver_app/features/auth/application/session_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.length < 4) return;
    try {
      await ref.read(sessionControllerProvider.notifier).verifyOtp(code);
      final status = ref.read(sessionControllerProvider).status;
      if (!mounted) return;
      if (status == SessionStatus.signedIn) {
        context.go(AppRoutes.currentDelivery);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.otpTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.phone),
        ),
        actions: [
          IconButton(
            key: const Key('otp_language'),
            tooltip: AppStrings.languageSettingsTitle,
            onPressed: () => context.push(AppRoutes.languageSettings),
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (session.pendingPhone != null)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    session.pendingPhone!,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              const SizedBox(height: 16),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  key: const Key('otp_field'),
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: AppStrings.otpHint,
                    errorText: session.errorMessage,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const Key('otp_verify'),
                  onPressed: session.busy ? null : _submit,
                  child: session.busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppStrings.otpVerify),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
