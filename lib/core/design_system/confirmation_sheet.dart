import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Modal bottom sheet confirmation. Returns true only on explicit confirm.
Future<bool> showConfirmationSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  Key? confirmKey,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: DriverTokens.card,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DriverTokens.edgeMargin,
            0,
            DriverTokens.edgeMargin,
            DriverTokens.edgeMargin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              Text(body, style: theme.textTheme.bodyMedium),
              const SizedBox(height: DriverTokens.spaceXl),
              SizedBox(
                height: DriverTokens.actionHeight,
                child: FilledButton(
                  key: confirmKey,
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: DriverTokens.danger,
                        )
                      : null,
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              SizedBox(
                height: DriverTokens.touchTarget,
                child: TextButton(
                  key: const Key('confirmation_cancel'),
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: Text(cancelLabel ?? AppStrings.cancel),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}
