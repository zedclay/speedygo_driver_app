import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/core/money/dzd_amount.dart';

void main() {
  group('formatCentimesAsDzdV2', () {
    test('65000 centimes is 650.00 DZD', () {
      expect(formatCentimesAsDzdV2(65000), '650.00');
      expect(formatCentimesAsDzdV2(15000), '150.00');
    });
  });

  group('parseDzdInputToMinor', () {
    test('650 DZD → 65000 minor', () {
      expect(parseDzdInputToMinor('650'), 65000);
    });

    test('650.50 DZD → 65050 minor', () {
      expect(parseDzdInputToMinor('650.50'), 65050);
    });

    test('FR comma decimal 650,50 → 65050', () {
      expect(parseDzdInputToMinor('650,50'), 65050);
    });

    test('Arabic-Indic digits ٦٥٠ → 65000', () {
      expect(parseDzdInputToMinor('٦٥٠'), 65000);
    });

    test('Arabic-Indic with decimal ٦٥٠٫٥٠ via ASCII sep', () {
      expect(parseDzdInputToMinor('٦٥٠.٥٠'), 65050);
    });

    test('rejects more than two fractional digits', () {
      expect(parseDzdInputToMinor('650.505'), isNull);
    });

    test('rejects empty and garbage', () {
      expect(parseDzdInputToMinor(''), isNull);
      expect(parseDzdInputToMinor('abc'), isNull);
      expect(parseDzdInputToMinor('12.3.4'), isNull);
      expect(parseDzdInputToMinor('1,2.3'), isNull);
      expect(parseDzdInputToMinor('.'), isNull);
    });

    test('single fractional digit pads to two minor places', () {
      expect(parseDzdInputToMinor('10.5'), 1050);
      expect(parseDzdInputToMinor('10,5'), 1050);
    });
  });

  group('sanitizeDzdInput', () {
    test('keeps one separator and caps two fractional digits', () {
      expect(sanitizeDzdInput('12a3,456'), '123,45');
      expect(sanitizeDzdInput('٩٩.٩٩٩'), '99.99');
    });
  });
}
