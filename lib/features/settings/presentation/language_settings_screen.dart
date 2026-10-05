import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_driver_app/core/constants/app_strings.dart';
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
      appBar: AppBar(title: Text(AppStrings.languageSettingsTitle)),
      body: SafeArea(
        child: ListView(
          key: const Key('language-settings-screen'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Text(
              AppStrings.languageSettingsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _LanguageCard(
              key: const Key('language-option-fr'),
              title: AppStrings.languageOptionFrench,
              selected: selected == 'fr',
              onTap: () => setState(() => _pending = 'fr'),
            ),
            const SizedBox(height: 12),
            _LanguageCard(
              key: const Key('language-option-ar'),
              title: AppStrings.languageOptionArabic,
              selected: selected == 'ar',
              onTap: () => setState(() => _pending = 'ar'),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.languagePreviewNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 4,
        color: theme.colorScheme.surface,
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
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
