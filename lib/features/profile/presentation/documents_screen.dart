import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/operational_card.dart';
import 'package:speedygo_driver_app/core/design_system/info_banner.dart';
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
        child: _DocumentCard(
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
      appBar: DriverNestedAppBar(title: AppStrings.documentsTitle),
      body: ListView(
        padding: const EdgeInsets.all(DriverTokens.edgeMargin),
        children: [
          Text(
            AppStrings.documentsTitle,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (me?.profileFullName != null) ...[
            const SizedBox(height: DriverTokens.spaceXs),
            Text(
              me!.profileFullName!,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: DriverTokens.textSecondary),
            ),
          ],
          const SizedBox(height: DriverTokens.spaceLg),
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
          if (!editable)
            InfoBanner(
              message: AppStrings.docLockedNote,
              icon: Icons.lock_outline,
            ),
          const SizedBox(height: DriverTokens.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: DriverTokens.outline,
              ),
              const SizedBox(width: DriverTokens.spaceSm),
              Expanded(
                child: Text(
                  AppStrings.docNeverShown,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: DriverTokens.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stitch "Mes documents" card: tinted glyph, title, expiry, status pill and a
/// full-width correction action (only when the profile is editable). There is
/// deliberately no "Voir" action: files are never re-displayed.
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.tone,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String statusLabel;
  final StatusTone tone;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warn = tone == StatusTone.warning || tone == StatusTone.danger;
    final accent = warn ? DriverTokens.warning : DriverTokens.primary;
    final accentBg = warn
        ? DriverTokens.warningContainer
        : DriverTokens.primaryContainer;
    return OperationalCard(
      borderColor: warn ? DriverTokens.warning.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.badge_outlined, color: accent),
              ),
              const SizedBox(width: DriverTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          detail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DriverTokens.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DriverTokens.spaceSm),
              StatusBadge(label: statusLabel, tone: tone),
            ],
          ),
          if (onAction != null && actionLabel != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: DriverTokens.spaceMd),
              child: Divider(height: 1, color: DriverTokens.outlineVariant),
            ),
            SizedBox(
              height: DriverTokens.actionHeight,
              child: FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.upload_file),
                label: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
