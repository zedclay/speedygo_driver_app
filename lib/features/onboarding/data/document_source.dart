import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

/// Abstraction over the platform file picker.
abstract class DocumentSource {
  Future<PickedDocument?> pick();
}

/// Production picker — gallery photo first, then Files (PDF / JPEG / PNG).
///
/// Requires a **full app rebuild** after adding the native plugins (hot restart
/// is not enough — otherwise [MissingPluginException] surfaces as unavailable).
class PlatformDocumentSource implements DocumentSource {
  PlatformDocumentSource({ImagePicker? imagePicker})
    : _images = imagePicker ?? ImagePicker();

  final ImagePicker _images;

  static const _allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];

  @override
  Future<PickedDocument?> pick() async {
    // 1) Photo library — most common for identity / license on phone.
    try {
      final shot = await _images.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (shot != null) {
        final bytes = await shot.readAsBytes();
        if (bytes.isNotEmpty) {
          final name = shot.name.isNotEmpty
              ? shot.name
              : 'document_${DateTime.now().millisecondsSinceEpoch}.jpg';
          return PickedDocument(
            bytes: bytes,
            filename: name,
            mimeType: _mimeForFilename(name),
          );
        }
      }
      // User cancelled gallery — still offer Files for PDF.
    } on MissingPluginException catch (e) {
      developer.log('image_picker missing: $e', name: 'DocumentSource');
    } catch (e, st) {
      developer.log(
        'image_picker failed: $e',
        name: 'DocumentSource',
        stackTrace: st,
      );
    }

    // 2) System Files sheet (PDF + images).
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );
      if (files.isEmpty) return null;
      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      final filename = file.name.isNotEmpty
          ? file.name
          : 'document_${DateTime.now().millisecondsSinceEpoch}.bin';
      return PickedDocument(
        bytes: bytes,
        filename: filename,
        mimeType: _mimeForFilename(filename),
      );
    } on MissingPluginException catch (e) {
      developer.log('file_picker missing: $e', name: 'DocumentSource');
      throw const DocumentPickerUnavailable();
    } catch (e, st) {
      developer.log(
        'file_picker failed: $e',
        name: 'DocumentSource',
        stackTrace: st,
      );
      throw const DocumentPickerUnavailable();
    }
  }

  static String _mimeForFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/jpeg';
  }
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
  (ref) => PlatformDocumentSource(),
);
