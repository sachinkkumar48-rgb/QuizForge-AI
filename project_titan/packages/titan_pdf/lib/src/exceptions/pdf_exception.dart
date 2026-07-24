import 'package:titan_domain/titan_domain.dart';

/// Base exception class for all PDF domain operations in Project TITAN.
abstract class PdfException extends RepositoryException {
  const PdfException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when importing a PDF document fails.
class PdfImportException extends PdfException {
  const PdfImportException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when a PDF document fails pre-flight validation rules.
class PdfValidationException extends PdfException {
  final List<String> validationErrors;

  PdfValidationException(
    String message, {
    List<String>? validationErrors,
    Object? cause,
    StackTrace? stackTrace,
  })  : validationErrors =
            List<String>.unmodifiable(validationErrors ?? const []),
        super(message, cause, stackTrace);
}

/// Thrown when text extraction from a PDF document fails.
class PdfExtractionException extends PdfException {
  const PdfExtractionException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when segmentation or text chunking fails.
class PdfChunkException extends PdfException {
  const PdfChunkException(super.message, [super.cause, super.stackTrace]);
}
