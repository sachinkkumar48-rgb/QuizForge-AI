import 'package:meta/meta.dart';

/// Base exception for all PDF manipulation and page operations.
@immutable
class PdfManipulationException implements Exception {
  final String message;
  final Object? cause;

  const PdfManipulationException(this.message, [this.cause]);

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Thrown when a page range string fails parsing.
class PdfPageRangeParseException extends PdfManipulationException {
  const PdfPageRangeParseException(super.message, [super.cause]);
}

/// Thrown when a requested page is out of the document bounds.
class PdfPageRangeOutOfBoundsException extends PdfManipulationException {
  final int requestedPage;
  final int maxPages;

  const PdfPageRangeOutOfBoundsException(
    String message, {
    required this.requestedPage,
    required this.maxPages,
    Object? cause,
  }) : super(message, cause);
}

/// Thrown when a PDF document fails format or structural validation.
class PdfInvalidDocumentException extends PdfManipulationException {
  final String filePath;

  const PdfInvalidDocumentException(
    String message, {
    required this.filePath,
    Object? cause,
  }) : super(message, cause);
}

/// Thrown when an unsupported PDF feature is encountered (e.g. encrypted without key).
class PdfUnsupportedDocumentException extends PdfManipulationException {
  final String reason;

  const PdfUnsupportedDocumentException(
    String message, {
    required this.reason,
    Object? cause,
  }) : super(message, cause);
}

/// Thrown when page selection is empty for an operation requiring at least one page.
class PdfEmptyPageSelectionException extends PdfManipulationException {
  const PdfEmptyPageSelectionException(super.message, [super.cause]);
}

/// Thrown when an atomic file write or rename operation fails.
class PdfAtomicWriteException extends PdfManipulationException {
  final String targetPath;

  const PdfAtomicWriteException(
    String message, {
    required this.targetPath,
    Object? cause,
  }) : super(message, cause);
}

/// Thrown when an operation would produce an empty document with 0 pages.
class PdfEmptyDocumentResultException extends PdfManipulationException {
  const PdfEmptyDocumentResultException(super.message, [super.cause]);
}
