import 'package:meta/meta.dart';
import 'pdf_metadata.dart';
import 'pdf_status.dart';

/// Immutable domain model representing an imported PDF document in Project TITAN.
@immutable
class PdfDocument {
  final String id;
  final String fileName;
  final String displayName;
  final int sizeBytes;
  final int pageCount;
  final DateTime createdAt;
  final DateTime lastModified;
  final String language;
  final PdfMetadata metadata;
  final PdfStatus status;

  PdfDocument({
    required this.id,
    required this.fileName,
    required this.displayName,
    required this.sizeBytes,
    required this.pageCount,
    DateTime? createdAt,
    DateTime? lastModified,
    this.language = 'en',
    this.metadata = const PdfMetadata.empty(),
    this.status = PdfStatus.ready,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  const PdfDocument.constDocument({
    required this.id,
    required this.fileName,
    required this.displayName,
    required this.sizeBytes,
    required this.pageCount,
    required this.createdAt,
    required this.lastModified,
    required this.language,
    required this.metadata,
    required this.status,
  });

  /// Creates a copy of this [PdfDocument] with modified values.
  PdfDocument copyWith({
    String? id,
    String? fileName,
    String? displayName,
    int? sizeBytes,
    int? pageCount,
    DateTime? createdAt,
    DateTime? lastModified,
    String? language,
    PdfMetadata? metadata,
    PdfStatus? status,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      displayName: displayName ?? this.displayName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      language: language ?? this.language,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfDocument &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fileName == other.fileName &&
          displayName == other.displayName &&
          sizeBytes == other.sizeBytes &&
          pageCount == other.pageCount &&
          createdAt == other.createdAt &&
          lastModified == other.lastModified &&
          language == other.language &&
          metadata == other.metadata &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      fileName.hashCode ^
      displayName.hashCode ^
      sizeBytes.hashCode ^
      pageCount.hashCode ^
      createdAt.hashCode ^
      lastModified.hashCode ^
      language.hashCode ^
      metadata.hashCode ^
      status.hashCode;

  @override
  String toString() =>
      'PdfDocument($id - $displayName, pages: $pageCount, status: ${status.name})';
}
