import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/document_status_card.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

/// Document metadata only. File bytes/URLs are never returned by the API.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeControllerProvider);
    final me = ref.watch(onboardingControllerProvider).me;
    final editable = me?.isOnboardingEditable ?? false;

    Widget card(String type, String title, String route) {
      final info = me?.documentOf(type);
      final present = info?.present == true;
      return Padding(
        padding: const EdgeInsets.only(bottom: DriverTokens.spaceMd),
        child: DocumentStatusCard(
          key: Key('document_$type'),
          title: title,
          statusLabel: present ? AppStrings.docPresent : AppStrings.docMissing,
          tone: present ? StatusTone.success : StatusTone.warning,
          detail: info?.expiryDate == null
              ? null
              : '${AppStrings.docExpiry}: ${info!.expiryDate}',
          actionLabel: editable ? AppStrings.uploadPick : null,
          onAction: editable ? () => context.push(route) : null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.documentsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DriverTokens.edgeMargin),
        children: [
          card(
            DriverDocumentTypes.identity,
            AppStrings.docIdentity,
            AppRoutes.onboardingIdentity,
          ),
          card(
            DriverDocumentTypes.drivingLicense,
            AppStrings.docLicense,
            AppRoutes.onboardingLicense,
          ),
          if (!editable) Text(AppStrings.docLockedNote),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            AppStrings.docNeverShown,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
