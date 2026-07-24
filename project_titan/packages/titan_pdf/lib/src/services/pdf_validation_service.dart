import '../exceptions/pdf_exception.dart';

/// Domain service responsible for enforcing pre-flight validation rules on PDF documents.
class PdfValidationService {
  static const int minSizeBytes = 100;
  static const int maxSizeBytes = 52428800; // 50 MB

  const PdfValidationService();

  /// Validates a PDF file against architectural and format integrity constraints.
  /// Throws [PdfValidationException] if validation fails.
  void validatePdf({
    required String filePath,
    int? sizeBytes,
    List<int>? headerBytes,
    bool isEncrypted = false,
    bool isCorrupted = false,
    bool isEmpty = false,
  }) {
    final errors = <String>[];

    if (filePath.trim().isEmpty) {
      errors.add('File path cannot be empty.');
    } else if (!filePath.toLowerCase().endsWith('.pdf')) {
      errors.add('File extension must be .pdf.');
    }

    if (isEmpty || (sizeBytes != null && sizeBytes == 0)) {
      errors.add('PDF document is empty.');
    } else if (sizeBytes != null) {
      if (sizeBytes < minSizeBytes) {
        errors.add(
            'PDF size ($sizeBytes bytes) is below minimum threshold ($minSizeBytes bytes).');
      }
      if (sizeBytes > maxSizeBytes) {
        errors.add(
            'PDF size ($sizeBytes bytes) exceeds maximum limit ($maxSizeBytes bytes).');
      }
    }

    if (isEncrypted) {
      errors.add('Encrypted PDFs are not supported.');
    }

    if (isCorrupted) {
      errors.add('PDF file structure is corrupted.');
    }

    if (headerBytes != null && headerBytes.isNotEmpty) {
      final headerString = String.fromCharCodes(headerBytes.take(10));
      if (!headerString.startsWith('%PDF-')) {
        errors.add('Invalid or corrupted PDF header (missing %PDF- marker).');
      }
      final fullHeader = String.fromCharCodes(headerBytes);
      if (fullHeader.contains('/Encrypt')) {
        errors.add('Encrypted PDFs are not supported.');
      }
    }

    if (errors.isNotEmpty) {
      throw PdfValidationException(
        'PDF validation failed with ${errors.length} error(s).',
        validationErrors: errors,
      );
    }
  }
}
