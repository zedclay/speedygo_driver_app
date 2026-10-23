import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/confirmation_sheet.dart';
import 'package:speedygo_driver_app/features/auth/application/auth_infrastructure.dart';

/// Confirmed logout from verification screens → Phone (stack replaced).
///
/// Cancel leaves session, route, and server dossier unchanged.
Future<void> confirmVerificationLogout(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showConfirmationSheet(
    context,
    title: AppStrings.logoutConfirmTitle,
    body: AppStrings.logoutConfirmBody,
    confirmLabel: AppStrings.logoutConfirmAction,
    cancelLabel: AppStrings.cancel,
    destructive: true,
    confirmKey: const Key('logout_confirm'),
  );
  if (!confirmed) return;
  await ref.read(sessionControllerProvider.notifier).logout();
  if (!context.mounted) return;
  context.go(AppRoutes.phone);
}
