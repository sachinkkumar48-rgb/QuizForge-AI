import 'package:meta/meta.dart';
import 'learning_document.dart';

/// Status of the document ingestion and normalization process.
enum DocumentIngestionStatus {
  /// Ingestion completed successfully with extracted text and chunks.
  success,

  /// Ingestion succeeded partially (e.g. some pages fell back to OCR or were blank).
  partialSuccess,

  /// Document was parsed but contained no readable digital text or images.
  emptyDocument,

  /// Document is encrypted / password-protected and requires authentication.
  encrypted,

  /// Document format is corrupted or unreadable.
  corrupted,

  /// Unexpected failure during processing.
  failed,
}

/// Result returned by [DocumentIntelligenceService] following document ingestion.
@immutable
class DocumentIngestionResult {
  /// The ingested [LearningDocument], if processing succeeded or partially succeeded.
  final LearningDocument? document;

  /// Ingestion status code.
  final DocumentIngestionStatus status;

  /// Non-fatal warnings encountered during extraction or chunking.
  final List<String> warnings;

  /// Error message if status is not success.
  final String? errorMessage;

  /// Total elapsed processing duration.
  final Duration processingTime;

  const DocumentIngestionResult({
    this.document,
    required this.status,
    this.warnings = const [],
    this.errorMessage,
    this.processingTime = Duration.zero,
  });

  /// Factory for a successful ingestion result.
  factory DocumentIngestionResult.success({
    required LearningDocument document,
    List<String> warnings = const [],
    Duration processingTime = Duration.zero,
  }) {
    return DocumentIngestionResult(
      document: document,
      status: DocumentIngestionStatus.success,
      warnings: warnings,
      processingTime: processingTime,
    );
  }

  /// Factory for an empty document result.
  factory DocumentIngestionResult.empty({
    String? message,
    Duration processingTime = Duration.zero,
  }) {
    return DocumentIngestionResult(
      status: DocumentIngestionStatus.emptyDocument,
      errorMessage:
          message ?? 'The document contains no readable text or pages.',
      processingTime: processingTime,
    );
  }

  /// Factory for a failed ingestion result.
  factory DocumentIngestionResult.failure({
    required DocumentIngestionStatus status,
    required String errorMessage,
    List<String> warnings = const [],
    Duration processingTime = Duration.zero,
  }) {
    return DocumentIngestionResult(
      status: status,
      errorMessage: errorMessage,
      warnings: warnings,
      processingTime: processingTime,
    );
  }

  /// Returns true if ingestion produced a usable [LearningDocument].
  bool get isSuccess =>
      (status == DocumentIngestionStatus.success ||
          status == DocumentIngestionStatus.partialSuccess) &&
      document != null;
}
