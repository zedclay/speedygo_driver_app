import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
import 'package:speedygo_driver_app/core/design_system/driver_nested_app_bar.dart';
import 'package:speedygo_driver_app/core/design_system/driver_tokens.dart';
import 'package:speedygo_driver_app/core/locale/locale_controller.dart';

/// Language selector available before and after authentication.
/// Applies immediately; session tokens and in-memory pickup draft are preserved.
class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  String? _pending;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(localeControllerProvider);
    final selected = _pending ?? current;
    final dirty = selected != current;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: DriverTokens.surface,
      appBar: DriverNestedAppBar(title: AppStrings.languageSettingsTitle),
      body: SafeArea(
        child: ListView(
          key: const Key('language-settings-screen'),
          padding: const EdgeInsets.fromLTRB(
            DriverTokens.edgeMargin,
            DriverTokens.edgeMargin,
            DriverTokens.edgeMargin,
            120,
          ),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.language,
                  size: 22,
                  color: DriverTokens.textSecondary,
                ),
                const SizedBox(width: DriverTokens.spaceSm),
                Expanded(
                  child: Text(
                    AppStrings.languageSettingsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DriverTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DriverTokens.spaceSm),
            Text(
              AppStrings.languageSettingsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DriverTokens.textSecondary,
              ),
            ),
            const SizedBox(height: DriverTokens.spaceLg),
            Material(
              color: DriverTokens.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusLg),
                side: const BorderSide(color: DriverTokens.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _LanguageCard(
                    key: const Key('language-option-fr'),
                    badge: 'FR',
                    title: AppStrings.languageOptionFrench,
                    selected: selected == 'fr',
                    onTap: () => setState(() => _pending = 'fr'),
                  ),
                  const Divider(height: 1, color: DriverTokens.outlineVariant),
                  _LanguageCard(
                    key: const Key('language-option-ar'),
                    badge: 'ع',
                    title: AppStrings.languageOptionArabic,
                    selected: selected == 'ar',
                    onTap: () => setState(() => _pending = 'ar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DriverTokens.spaceLg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: DriverTokens.outline,
                ),
                const SizedBox(width: DriverTokens.spaceSm),
                Expanded(
                  child: Text(
                    AppStrings.languagePreviewNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DriverTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: DriverTokens.card,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + bottomInset.clamp(0, 24),
            ),
            child: SizedBox(
              height: 56,
              child: FilledButton(
                key: const Key('language-apply'),
                onPressed: !dirty
                    ? null
                    : () async {
                        await ref
                            .read(localeControllerProvider.notifier)
                            .setLocale(selected);
                        if (context.mounted) Navigator.of(context).maybePop();
                      },
                child: Text(AppStrings.languageApply),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    super.key,
    required this.badge,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String badge;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DriverTokens.spaceLg,
              vertical: DriverTokens.spaceMd,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: selected
                      ? DriverTokens.primaryContainer
                      : DriverTokens.neutralContainer,
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: selected
                          ? DriverTokens.primary
                          : DriverTokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: DriverTokens.spaceMd),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                selected
                    ? Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: DriverTokens.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 18,
                          color: DriverTokens.onPrimary,
                        ),
                      )
                    : Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DriverTokens.outline,
                            width: 1.5,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
