/// Exact DZD ↔ integer-minor conversion at the UI boundary only.
/// Uses integer arithmetic only — never [double] for authoritative money.
library;

const _arabicIndicDigits = {
  '٠': '0',
  '١': '1',
  '٢': '2',
  '٣': '3',
  '٤': '4',
  '٥': '5',
  '٦': '6',
  '٧': '7',
  '٨': '8',
  '٩': '9',
  '۰': '0',
  '۱': '1',
  '۲': '2',
  '۳': '3',
  '۴': '4',
  '۵': '5',
  '۶': '6',
  '۷': '7',
  '۸': '8',
  '۹': '9',
};

/// Maps Arabic-Indic / Eastern Arabic digits to ASCII; strips spaces and
/// narrow no-break spaces used as thousand separators in FR/AR entry.
String normalizeDzdDigits(String raw) {
  final buffer = StringBuffer();
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == ' ' || ch == '\u00A0' || ch == '\u202F') {
      continue;
    }
    // Arabic decimal separator (U+066B) / Arabic comma (U+060C) → ASCII '.' / ','.
    if (ch == '\u066B') {
      buffer.write('.');
      continue;
    }
    if (ch == '\u060C') {
      buffer.write(',');
      continue;
    }
    buffer.write(_arabicIndicDigits[ch] ?? ch);
  }
  return buffer.toString().trim();
}

/// Keeps only characters valid while typing a DZD amount (digits + one sep).
String sanitizeDzdInput(String raw) {
  final normalized = normalizeDzdDigits(raw);
  final buffer = StringBuffer();
  var seenSep = false;
  var fracDigits = 0;
  for (final rune in normalized.runes) {
    final ch = String.fromCharCode(rune);
    if (ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0) {
      if (seenSep) {
        if (fracDigits >= 2) continue;
        fracDigits += 1;
      }
      buffer.write(ch);
      continue;
    }
    if ((ch == '.' || ch == ',') && !seenSep) {
      seenSep = true;
      buffer.write(ch);
    }
  }
  return buffer.toString();
}

/// Parses a driver-entered DZD amount into integer minor units (centimes).
/// Accepts `.` or `,` as decimal separator and at most two fractional digits.
/// Returns null for empty or invalid input.
int? parseDzdInputToMinor(String raw) {
  final s = normalizeDzdDigits(raw);
  if (s.isEmpty) return null;
  if (s.contains(',') && s.contains('.')) return null;

  final unified = s.replaceAll(',', '.');
  if (unified == '.' || unified.startsWith('.') || unified.endsWith('.')) {
    return null;
  }
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(unified)) {
    return null;
  }

  final parts = unified.split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null || whole < 0) return null;
  if (parts.length == 1) {
    return whole * 100;
  }
  final frac = parts[1].padRight(2, '0');
  final cents = int.tryParse(frac);
  if (cents == null || cents < 0 || cents > 99) return null;
  return whole * 100 + cents;
}

/// dzd-v2 JSON amount: integer centimes → `"650.00"`.
String formatCentimesAsDzdV2(int centimes) {
  final neg = centimes < 0;
  final abs = neg ? -centimes : centimes;
  final whole = abs ~/ 100;
  final frac = abs % 100;
  final body = '$whole.${frac.toString().padLeft(2, '0')}';
  return neg ? '-$body' : body;
}
