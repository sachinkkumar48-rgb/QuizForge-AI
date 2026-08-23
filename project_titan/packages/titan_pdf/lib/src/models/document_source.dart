import 'dart:typed_data';
import 'package:meta/meta.dart';

/// Represents the origin and binary descriptor of a document to be ingested.
@immutable
class DocumentSource {
  /// Unique identifier of the document.
  final String documentId;

  /// Full file system path to the document, if stored locally.
  final String? filePath;

  /// In-memory binary bytes of the document, if loaded into memory.
  final Uint8List? bytes;

  /// File name with extension (e.g. "upsc_polity_notes.pdf").
  final String fileName;

  /// User-facing display name or document title.
  final String displayName;

  /// File size in bytes.
  final int sizeBytes;

  /// Primary expected language code (e.g. 'en', 'hi'), if known beforehand.
  final String? languageCode;

  /// Custom application-specific metadata.
  final Map<String, dynamic> metadata;

  const DocumentSource({
    required this.documentId,
    this.filePath,
    this.bytes,
    required this.fileName,
    required this.displayName,
    required this.sizeBytes,
    this.languageCode,
    this.metadata = const {},
  });

  /// Creates a [DocumentSource] from a local file path.
  factory DocumentSource.fromFilePath({
    required String filePath,
    String? documentId,
    String? displayName,
    int? sizeBytes,
    String? languageCode,
    Map<String, dynamic>? metadata,
  }) {
    final name = filePath.split(RegExp(r'[/\\]')).last;
    return DocumentSource(
      documentId: documentId ?? 'doc_${DateTime.now().millisecondsSinceEpoch}',
      filePath: filePath,
      fileName: name,
      displayName: displayName ?? name,
      sizeBytes: sizeBytes ?? 0,
      languageCode: languageCode,
      metadata: metadata ?? const {},
    );
  }

  /// Creates a [DocumentSource] from in-memory bytes.
  factory DocumentSource.fromBytes({
    required Uint8List bytes,
    required String fileName,
    String? documentId,
    String? displayName,
    String? languageCode,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentSource(
      documentId: documentId ?? 'doc_${DateTime.now().millisecondsSinceEpoch}',
      bytes: bytes,
      fileName: fileName,
      displayName: displayName ?? fileName,
      sizeBytes: bytes.lengthInBytes,
      languageCode: languageCode,
      metadata: metadata ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentSource &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          filePath == other.filePath &&
          fileName == other.fileName &&
          displayName == other.displayName &&
          sizeBytes == other.sizeBytes &&
          languageCode == other.languageCode;

  @override
  int get hashCode =>
      documentId.hashCode ^
      filePath.hashCode ^
      fileName.hashCode ^
      displayName.hashCode ^
      sizeBytes.hashCode ^
      languageCode.hashCode;
}
