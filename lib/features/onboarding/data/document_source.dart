import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PickedDocument {
  const PickedDocument({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;

  /// `application/pdf`, `image/jpeg` or `image/png` (backend allow-list).
  final String mimeType;
}

class DocumentPickerUnavailable implements Exception {
  const DocumentPickerUnavailable();
}

/// Abstraction over the platform file / camera picker.
///
/// No picker package (`image_picker` / `file_picker`) is in pubspec yet, so the
/// production default honestly reports "unavailable" instead of faking an
/// upload. Wire a real implementation by overriding [documentSourceProvider]
/// once a picker dependency is approved.
abstract class DocumentSource {
  Future<PickedDocument?> pick();
}

class UnavailableDocumentSource implements DocumentSource {
  const UnavailableDocumentSource();

  @override
  Future<PickedDocument?> pick() async =>
      throw const DocumentPickerUnavailable();
}

class FakeDocumentSource implements DocumentSource {
  FakeDocumentSource(this.document);

  PickedDocument? document;
  int pickCount = 0;

  @override
  Future<PickedDocument?> pick() async {
    pickCount += 1;
    return document;
  }
}

final documentSourceProvider = Provider<DocumentSource>(
  (ref) => const UnavailableDocumentSource(),
);
