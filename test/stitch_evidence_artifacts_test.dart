import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Documentation-artifact check, not a product widget/golden test.
///
/// `docs/evidence/stitch_full_ui_2026-10-09` is review evidence
/// (`mocked_widget_ui`, explicitly not live UI). The coverage matrix JSON/MD
/// contract lives in `stitch_coverage_matrix_test.dart` and does not depend
/// on these PNGs. This file only asserts the versioned evidence set is
/// present — it does not invent images or change coverage statuses.
void main() {
  test('versioned stitch evidence has 16 FR and 16 AR mocked captures', () {
    final root = Directory('docs/evidence/stitch_full_ui_2026-10-09');
    expect(root.existsSync(), isTrue, reason: 'evidence root missing');
    final fr = Directory('${root.path}/fr');
    final ar = Directory('${root.path}/ar');
    expect(fr.listSync().whereType<File>().length, 16);
    expect(ar.listSync().whereType<File>().length, 16);
    final manifest = File('${root.path}/MANIFEST.md').readAsStringSync();
    expect(manifest, contains('mocked_widget_ui'));
    expect(manifest, contains('not: live_authenticated_ui'));
    expect(manifest, contains('not: live_ui_verified'));
  });
}
