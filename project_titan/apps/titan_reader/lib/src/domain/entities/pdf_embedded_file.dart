import 'package:meta/meta.dart';

/// Indicates where an embedded file was declared in the PDF document structure.
enum PdfAttachmentSourceLocation {
  /// Document-level embedded file (from Catalog `/Names /EmbeddedFiles` or `/AF`).
  documentLevel,

  /// Page-level file attachment annotation (from Page `/Annots` with `/Subtype /FileAttachment`).
  annotation;

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case PdfAttachmentSourceLocation.documentLevel:
        return 'Document Level';
      case PdfAttachmentSourceLocation.annotation:
        return 'Page Annotation';
    }
  }
}

/// Immutable domain entity representing a file embedded within a PDF document (ISO 32000-1 §7.11 & §12.5.6.15).
@immutable
class PdfEmbeddedFile {
  /// Unique identifier or key for this attachment (e.g. object number reference).
  final String id;

  /// Clean, sanitized filename suitable for display and filesystem operations.
  final String filename;

  /// Original raw filename extracted from the PDF `/F` entry.
  final String? originalFilename;

  /// Original Unicode filename extracted from the PDF `/UF` entry.
  final String? unicodeFilename;

  /// Description of the embedded file from `/Desc`.
  final String? description;

  /// MIME content type / Subtype from the embedded stream (e.g. `application/pdf`, `image/png`, `text/plain`).
  final String? mimeType;

  /// Declared uncompressed byte size from `/Params /Size`.
  final int? declaredSize;

  /// Actual byte size of the stream payload if known/decoded.
  final int? actualSize;

  /// Creation date string from `/Params /CreationDate`.
  final String? creationDate;

  /// Modification date string from `/Params /ModDate`.
  final String? modificationDate;

  /// Relationship to the parent document or object from `/AFRelationship` (e.g. `Source`, `Data`, `Supplement`, `Alternative`, `Unspecified`).
  final String? relationship;

  /// Source location of the attachment within the PDF document hierarchy.
  final PdfAttachmentSourceLocation sourceLocation;

  /// 1-based page number if this attachment is from a page-level annotation.
  final int? pageNumber;

  /// PDF Indirect Object Number containing the stream payload.
  final int streamObjectNumber;

  /// PDF Generation Number for the stream object.
  final int streamGeneration;

  const PdfEmbeddedFile({
    required this.id,
    required this.filename,
    this.originalFilename,
    this.unicodeFilename,
    this.description,
    this.mimeType,
    this.declaredSize,
    this.actualSize,
    this.creationDate,
    this.modificationDate,
    this.relationship,
    this.sourceLocation = PdfAttachmentSourceLocation.documentLevel,
    this.pageNumber,
    required this.streamObjectNumber,
    this.streamGeneration = 0,
  });

  /// Best-effort display size in bytes (prefers actualSize over declaredSize).
  int? get displaySize => actualSize ?? declaredSize;

  /// Formatted human-readable file size string (e.g. `14.2 KB`, `1.5 MB`).
  String get formattedSize {
    final size = displaySize;
    if (size == null || size < 0) return 'Unknown size';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// File extension in lowercase without leading dot (e.g. `pdf`, `png`, `txt`, `bin`).
  String get fileExtension {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < filename.length - 1) {
      return filename.substring(dotIndex + 1).toLowerCase();
    }
    return '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfEmbeddedFile &&
          other.id == id &&
          other.filename == filename &&
          other.originalFilename == originalFilename &&
          other.unicodeFilename == unicodeFilename &&
          other.description == description &&
          other.mimeType == mimeType &&
          other.declaredSize == declaredSize &&
          other.actualSize == actualSize &&
          other.creationDate == creationDate &&
          other.modificationDate == modificationDate &&
          other.relationship == relationship &&
          other.sourceLocation == sourceLocation &&
          other.pageNumber == pageNumber &&
          other.streamObjectNumber == streamObjectNumber &&
          other.streamGeneration == streamGeneration;

  @override
  int get hashCode => Object.hash(
        id,
        filename,
        originalFilename,
        unicodeFilename,
        description,
        mimeType,
        declaredSize,
        actualSize,
        creationDate,
        modificationDate,
        relationship,
        sourceLocation,
        pageNumber,
        streamObjectNumber,
        streamGeneration,
      );

  @override
  String toString() =>
      'PdfEmbeddedFile(id: $id, filename: $filename, size: $formattedSize, location: ${sourceLocation.name})';
}

/// Status enum for attachment extraction operations.
enum PdfAttachmentExtractionStatus {
  completed,
  failed,
  cancelled,
}

/// Result of an attachment extraction operation.
@immutable
class PdfAttachmentExtractionResult {
  final PdfAttachmentExtractionStatus status;
  final String? outputPath;
  final int? extractedBytesCount;
  final String? errorMessage;
  final DateTime timestamp;

  const PdfAttachmentExtractionResult({
    required this.status,
    this.outputPath,
    this.extractedBytesCount,
    this.errorMessage,
    required this.timestamp,
  });

  factory PdfAttachmentExtractionResult.completed({
    required String outputPath,
    required int extractedBytesCount,
    DateTime? timestamp,
  }) {
    return PdfAttachmentExtractionResult(
      status: PdfAttachmentExtractionStatus.completed,
      outputPath: outputPath,
      extractedBytesCount: extractedBytesCount,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory PdfAttachmentExtractionResult.failed(
    String errorMessage, {
    DateTime? timestamp,
  }) {
    return PdfAttachmentExtractionResult(
      status: PdfAttachmentExtractionStatus.failed,
      errorMessage: errorMessage,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory PdfAttachmentExtractionResult.cancelled({
    DateTime? timestamp,
  }) {
    return PdfAttachmentExtractionResult(
      status: PdfAttachmentExtractionStatus.cancelled,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  bool get isSuccess => status == PdfAttachmentExtractionStatus.completed;
  bool get isFailure => status == PdfAttachmentExtractionStatus.failed;
  bool get isCancelled => status == PdfAttachmentExtractionStatus.cancelled;

  @override
  String toString() =>
      'PdfAttachmentExtractionResult(status: ${status.name}, path: $outputPath, bytes: $extractedBytesCount, error: $errorMessage)';
}
