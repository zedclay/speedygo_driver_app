import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryKey,
  });

  final String message;
  final VoidCallback onRetry;
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: DriverTokens.edgeMargin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: DriverTokens.danger),
          const SizedBox(height: DriverTokens.spaceLg),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: DriverTokens.spaceLg),
          SizedBox(
            height: DriverTokens.touchTarget,
            child: FilledButton(
              key: retryKey,
              onPressed: onRetry,
              child: Text(AppStrings.retry),
            ),
          ),
        ],
      ),
    );
  }
}
