import 'dart:ui' as ui;

/// Supported Driver UI locales.
const supportedLanguageCodes = ['fr', 'ar'];

String sanitizeLanguageCode(String? code) => code == 'ar' ? 'ar' : 'fr';

/// Prefer stored locale; otherwise a supported platform language; else French.
String resolveInitialLanguageCode({String? stored, ui.Locale? platform}) {
  if (stored == 'ar' || stored == 'fr') return stored!;
  final device = platform ?? ui.PlatformDispatcher.instance.locale;
  final code = device.languageCode.toLowerCase();
  if (code == 'ar' || code == 'fr') return code;
  return 'fr';
}
