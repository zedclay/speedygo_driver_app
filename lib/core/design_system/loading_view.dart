import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: DriverTokens.spaceLg),
              Text(message!),
            ],
          ],
        ),
      ),
    );
  }
}
