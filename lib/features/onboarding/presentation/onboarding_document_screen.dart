import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_driver_app/core/constants/app_constants.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/document_status_card.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/design_system/status_badge.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_controller.dart';
import 'package:speedygo_driver_app/features/onboarding/application/onboarding_flow.dart';
import 'package:speedygo_driver_app/features/onboarding/presentation/onboarding_scaffold.dart';
import 'package:speedygo_driver_app/features/profile/data/driver_profile_api.dart';

/// Steps 2 & 3 — identity (optional expiry) and driving license (mandatory,
/// future expiry). Upload = multipart content, then PUT metadata.
class OnboardingDocumentScreen extends ConsumerStatefulWidget {
  const OnboardingDocumentScreen({super.key, required this.type});

  final String type;

  @override
  ConsumerState<OnboardingDocumentScreen> createState() =>
      _OnboardingDocumentScreenState();
}

class _OnboardingDocumentScreenState
    extends ConsumerState<OnboardingDocumentScreen>
    with OnboardingLoader {
  final _expiry = TextEditingController();
  String? _expiryError;

  bool get _isLicense => widget.type == DriverDocumentTypes.drivingLicense;

  @override
  void dispose() {
    _expiry.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final expiry = _expiry.text.trim();
    if (_isLicense && !isFutureIsoDate(expiry)) {
      setState(() => _expiryError = AppStrings.licenseExpiryInvalid);
      return;
    }
    if (!_isLicense && expiry.isNotEmpty && !isFutureIsoDate(expiry)) {
      setState(() => _expiryError = AppStrings.licenseExpiryInvalid);
      return;
    }
    setState(() => _expiryError = null);
    await ref
        .read(onboardingControllerProvider.notifier)
        .uploadDocument(
          widget.type,
          expiryDate: expiry.isEmpty ? null : expiry,
        );
  }

  void _next() {
    final me = ref.read(onboardingControllerProvider).me;
    context.go(
      me == null ? AppRoutes.onboardingReview : nextIncompleteStepRoute(me),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final me = state.me;
    final info = me?.documentOf(widget.type);
    final present = info?.present == true;
    final locked = me != null && !me.isOnboardingEditable;
    return OnboardingScaffold(
      step: _isLicense ? 3 : 2,
      title: _isLicense ? AppStrings.licenseTitle : AppStrings.identityTitle,
      actionLabel: present ? AppStrings.onboardingNext : null,
      actionKey: const Key('onboarding_document_next'),
      onAction: _next,
      children: [
        DocumentStatusCard(
          title: _isLicense ? AppStrings.docLicense : AppStrings.docIdentity,
          statusLabel: present ? AppStrings.docPresent : AppStrings.docMissing,
          tone: present ? StatusTone.success : StatusTone.warning,
          detail: info?.expiryDate == null
              ? null
              : '${AppStrings.docExpiry}: ${info!.expiryDate}',
        ),
        const SizedBox(height: DriverTokens.spaceLg),
        if (locked)
          Text(AppStrings.onboardingLocked)
        else ...[
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: const Key('onboarding_expiry'),
              controller: _expiry,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: AppStrings.licenseExpiryLabel,
                helperText: _isLicense ? AppStrings.licenseExpiryHint : null,
                errorText: _expiryError,
                helperMaxLines: 2,
              ),
            ),
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            AppStrings.uploadFormats,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: DriverTokens.spaceMd),
          SizedBox(
            height: DriverTokens.touchTarget,
            child: OutlinedButton.icon(
              key: const Key('onboarding_upload_button'),
              onPressed: state.busy ? null : _upload,
              icon: const Icon(Icons.upload_file),
              label: Text(AppStrings.uploadPick),
            ),
          ),
          const SizedBox(height: DriverTokens.spaceSm),
          Text(
            AppStrings.docNeverShown,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
