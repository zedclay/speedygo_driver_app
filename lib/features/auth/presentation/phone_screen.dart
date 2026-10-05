import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _controller.text.trim();
    if (phone.length < 8) {
      setState(() => _localError = AppStrings.phoneInvalid);
      return;
    }
    setState(() => _localError = null);
    try {
      await ref.read(sessionControllerProvider.notifier).requestOtp(phone);
      if (mounted) context.go(AppRoutes.otp);
    } catch (_) {
      // Error surfaced via session state.
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.phoneTitle),
        actions: [
          IconButton(
            key: const Key('phone_language'),
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
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  key: const Key('phone_field'),
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    labelText: AppStrings.phoneHint,
                    errorText: _localError ?? session.errorMessage,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => session.busy ? null : _submit(),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const Key('phone_continue'),
                  onPressed: session.busy ? null : _submit,
                  child: session.busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppStrings.phoneContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
