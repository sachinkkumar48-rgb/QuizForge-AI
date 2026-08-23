import 'package:meta/meta.dart';
import 'learning_document_chunk.dart';
import 'learning_page.dart';
import 'pdf_document.dart';
import 'pdf_metadata.dart';
import 'pdf_status.dart';
import 'text_provenance.dart';

/// Immutable domain model representing a completely ingested, normalized,
/// and AI-ready document in Project TITAN.
@immutable
class LearningDocument {
  /// Unique identifier of the document.
  final String id;

  /// Source file name with extension.
  final String fileName;

  /// Human-readable title or display name.
  final String displayName;

  /// Total page count in document.
  final int totalPages;

  /// Document file size in bytes.
  final int sizeBytes;

  /// Primary dominant language (e.g. 'en', 'hi', 'bilingual').
  final String primaryLanguage;

  /// Ingestion timestamp.
  final DateTime createdAt;

  /// Individual processed pages with provenance and layout structure.
  final List<LearningPage> pages;

  /// Deterministic segmented chunks ready for AI prompt context.
  final List<LearningDocumentChunk> chunks;

  /// Custom document metadata (author, title, creation date, keywords).
  final Map<String, dynamic> metadata;

  const LearningDocument({
    required this.id,
    required this.fileName,
    required this.displayName,
    required this.totalPages,
    required this.sizeBytes,
    this.primaryLanguage = 'en',
    required this.createdAt,
    this.pages = const [],
    this.chunks = const [],
    this.metadata = const {},
  });

  /// Complete concatenated raw text across all pages in reading order.
  String get rawText => pages.map((p) => p.text).join('\n\n');

  /// Overall document text provenance (native, OCR, or mixed).
  TextProvenance get provenance {
    if (pages.isEmpty) return TextProvenance.nativePdf;
    final hasNative =
        pages.any((p) => p.provenance == TextProvenance.nativePdf);
    final hasOcr = pages.any((p) => p.provenance == TextProvenance.ocr);
    if (hasNative && hasOcr) return TextProvenance.mixed;
    if (hasOcr) return TextProvenance.ocr;
    return TextProvenance.nativePdf;
  }

  /// Adapts this [LearningDocument] into a legacy [PdfDocument] for backward compatibility.
  PdfDocument toPdfDocument() {
    return PdfDocument(
      id: id,
      fileName: fileName,
      displayName: displayName,
      sizeBytes: sizeBytes,
      pageCount: totalPages,
      createdAt: createdAt,
      lastModified: createdAt,
      language: primaryLanguage,
      metadata: PdfMetadata(
        title: displayName,
        author: metadata['author'] as String?,
        creator: metadata['creator'] as String?,
      ),
      status: PdfStatus.ready,
    );
  }

  /// Creates a copy of this [LearningDocument] with modified values.
  LearningDocument copyWith({
    String? id,
    String? fileName,
    String? displayName,
    int? totalPages,
    int? sizeBytes,
    String? primaryLanguage,
    DateTime? createdAt,
    List<LearningPage>? pages,
    List<LearningDocumentChunk>? chunks,
    Map<String, dynamic>? metadata,
  }) {
    return LearningDocument(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      displayName: displayName ?? this.displayName,
      totalPages: totalPages ?? this.totalPages,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      createdAt: createdAt ?? this.createdAt,
      pages: pages ?? this.pages,
      chunks: chunks ?? this.chunks,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningDocument &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fileName == other.fileName &&
          displayName == other.displayName &&
          totalPages == other.totalPages &&
          sizeBytes == other.sizeBytes &&
          primaryLanguage == other.primaryLanguage &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      fileName.hashCode ^
      displayName.hashCode ^
      totalPages.hashCode ^
      sizeBytes.hashCode ^
      primaryLanguage.hashCode ^
      createdAt.hashCode;
}
