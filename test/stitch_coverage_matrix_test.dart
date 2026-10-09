import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> json;
  late String markdown;

  setUpAll(() {
    json = jsonDecode(
      File('docs/DRIVER_STITCH_SCREEN_COVERAGE.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    markdown = File('docs/DRIVER_STITCH_SCREEN_COVERAGE.md').readAsStringSync();
  });

  test('47 unique folders; unreviewed 0; summary sums to 47', () {
    final screens = (json['screens'] as List).cast<Map<String, dynamic>>();
    expect(screens, hasLength(47));
    final folders = screens.map((s) => s['source_folder'] as String).toList();
    expect(folders.toSet(), hasLength(47));
    expect(json['unreviewed'], 0);
    final summary = Map<String, int>.from(
      (json['summary'] as Map).map((k, v) => MapEntry(k as String, v as int)),
    );
    expect(summary['unreviewed'], 0);
    expect(summary.values.reduce((a, b) => a + b), 47);
    expect(json['summary_total'], 47);
  });

  test('exactly five blocked_contract rows with named missing contracts', () {
    final blocked = (json['blocked_contract_rows'] as List)
        .cast<Map<String, dynamic>>();
    expect(blocked, hasLength(5));
    final folders = blocked.map((b) => b['source_folder']).toSet();
    expect(folders, {
      'contact_marchand',
      'contact_client',
      'validation_du_code_de_livraison',
      'signalement_de_probl_me_de_livraison',
      'chec_de_livraison',
    });
    for (final row in blocked) {
      expect(row['missing_contract'], isNotEmpty);
      expect(row['blocker'], isNotEmpty);
    }
  });

  test('markdown summary counts match JSON', () {
    final summary = Map<String, int>.from(
      (json['summary'] as Map).map((k, v) => MapEntry(k as String, v as int)),
    );
    for (final entry in summary.entries) {
      final pattern = RegExp('\\| `${entry.key}` \\| ${entry.value} \\|');
      expect(markdown, contains(pattern), reason: entry.key);
    }
    expect(markdown, contains('| Total | 47 |'));
  });

  test('every screen has mocked capture mapping and provider_dependencies', () {
    for (final s in (json['screens'] as List).cast<Map<String, dynamic>>()) {
      expect(s['mocked_widget_captures'], isA<List>());
      expect((s['mocked_widget_captures'] as List), isNotEmpty);
      expect(s['provider_dependencies'], isA<Map>());
    }
    expect(json['deferred_provider_dependency_rows'], 9);
  });

  test('evidence directory has 16 FR and 16 AR mocked captures', () {
    final fr = Directory('docs/evidence/stitch_full_ui_2026-10-09/fr');
    final ar = Directory('docs/evidence/stitch_full_ui_2026-10-09/ar');
    expect(fr.listSync().whereType<File>().length, 16);
    expect(ar.listSync().whereType<File>().length, 16);
    final manifest = File('docs/evidence/stitch_full_ui_2026-10-09/MANIFEST.md')
        .readAsStringSync();
    expect(manifest, contains('mocked_widget_ui'));
    expect(manifest, contains('not: live_authenticated_ui'));
    expect(manifest, contains('not: live_ui_verified'));
  });
}
