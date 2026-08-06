library;

import 'dart:convert';
import 'package:crypto/crypto.dart';

enum PaperInputType {
  pdf,
  answerKeyPdf,
  json,
  csv,
  ocrImage,
}

class PaperDocumentBuffer {
  final String id;
  final String filename;
  final PaperInputType inputType;
  final String rawText;
  final List<int> rawBytes;
  final String checksum;
  final Map<String, dynamic> metadata;

  const PaperDocumentBuffer({
    required this.id,
    required this.filename,
    required this.inputType,
    required this.rawText,
    required this.rawBytes,
    required this.checksum,
    this.metadata = const {},
  });
}

class OfficialPaperLoader {
  /// Loads raw input into a verified PaperDocumentBuffer.
  static PaperDocumentBuffer loadFromBytes({
    required String filename,
    required List<int> bytes,
    required PaperInputType inputType,
    Map<String, dynamic> metadata = const {},
  }) {
    if (bytes.isEmpty) {
      throw ArgumentError('Input document buffer cannot be empty for file: $filename');
    }

    final checksum = sha256.convert(bytes).toString();
    String textContent = '';

    if (inputType == PaperInputType.json || inputType == PaperInputType.csv) {
      try {
        textContent = utf8.decode(bytes);
      } catch (_) {
        textContent = String.fromCharCodes(bytes);
      }
    } else {
      // PDF or Image text extraction representation
      textContent = utf8.decode(bytes, allowMalformed: true);
    }

    return PaperDocumentBuffer(
      id: 'DOC_${checksum.substring(0, 12).toUpperCase()}',
      filename: filename,
      inputType: inputType,
      rawText: textContent,
      rawBytes: bytes,
      checksum: checksum,
      metadata: metadata,
    );
  }

  /// Loads text content directly (e.g. for structured text/JSON).
  static PaperDocumentBuffer loadFromText({
    required String filename,
    required String textContent,
    required PaperInputType inputType,
    Map<String, dynamic> metadata = const {},
  }) {
    final bytes = utf8.encode(textContent);
    final checksum = sha256.convert(bytes).toString();

    return PaperDocumentBuffer(
      id: 'DOC_${checksum.substring(0, 12).toUpperCase()}',
      filename: filename,
      inputType: inputType,
      rawText: textContent,
      rawBytes: bytes,
      checksum: checksum,
      metadata: metadata,
    );
  }
}
