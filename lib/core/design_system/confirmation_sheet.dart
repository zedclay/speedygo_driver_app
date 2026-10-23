import 'package:flutter/material.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';

/// Centered dialog card confirmation (Stitch déconnexion). Returns true only
/// on explicit confirm.
Future<bool> showConfirmationSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  Key? confirmKey,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return Dialog(
        backgroundColor: DriverTokens.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DriverTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DriverTokens.spaceMd),
              Text(body, style: theme.textTheme.bodyMedium),
              if (destructive) ...[
                const SizedBox(height: DriverTokens.spaceMd),
                Container(
                  padding: const EdgeInsets.all(DriverTokens.spaceMd),
                  decoration: BoxDecoration(
                    color: DriverTokens.dangerContainer,
                    borderRadius: BorderRadius.circular(DriverTokens.radiusMd),
                    border: Border.all(
                      color: DriverTokens.danger.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: DriverTokens.spaceSm),
                      Expanded(
                        child: Text(
                          AppStrings.logoutConfirmWarning,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: DriverTokens.spaceXl),
              SizedBox(
                height: DriverTokens.actionHeight,
                child: FilledButton.icon(
                  key: confirmKey,
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: DriverTokens.danger,
                          foregroundColor: DriverTokens.onPrimary,
                        )
                      : null,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: destructive
                      ? const Icon(Icons.power_settings_new)
                      : const SizedBox.shrink(),
                  label: Text(confirmLabel),
                ),
              ),
              const SizedBox(height: DriverTokens.spaceSm),
              SizedBox(
                height: DriverTokens.actionHeight,
                child: OutlinedButton(
                  key: const Key('confirmation_cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DriverTokens.primary,
                    side: const BorderSide(
                      color: DriverTokens.primary,
                      width: 2,
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
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
