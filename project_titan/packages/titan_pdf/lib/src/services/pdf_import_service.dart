import '../exceptions/pdf_exception.dart';
import '../models/pdf_document.dart';
import '../models/pdf_import_result.dart';
import '../models/pdf_metadata.dart';
import '../models/pdf_status.dart';
import 'pdf_validation_service.dart';

/// Domain service coordinating PDF import processing and document metadata construction.
class PdfImportService {
  final PdfValidationService _validationService;

  const PdfImportService({
    PdfValidationService validationService = const PdfValidationService(),
  }) : _validationService = validationService;

  /// Validates and constructs a [PdfImportResult] for an imported PDF file.
  PdfImportResult importPdf({
    required String filePath,
    required String documentId,
    required String fileName,
    required String displayName,
    required int sizeBytes,
    required int pageCount,
    PdfMetadata metadata = const PdfMetadata.empty(),
    List<int>? headerBytes,
    bool isEncrypted = false,
    bool isCorrupted = false,
    bool isEmpty = false,
  }) {
    final warnings = <String>[];
    final errors = <String>[];

    try {
      _validationService.validatePdf(
        filePath: filePath,
        sizeBytes: sizeBytes,
        headerBytes: headerBytes,
        isEncrypted: isEncrypted,
        isCorrupted: isCorrupted,
        isEmpty: isEmpty,
      );
    } on PdfValidationException catch (e) {
      errors.addAll(
          e.validationErrors.isNotEmpty ? e.validationErrors : [e.message]);
    } catch (e) {
      errors.add(e.toString());
    }

    if (pageCount > 500) {
      warnings.add(
          'PDF document has a high page count ($pageCount pages). Processing may take longer.');
    }

    final status = errors.isNotEmpty ? PdfStatus.failed : PdfStatus.ready;

    final document = PdfDocument(
      id: documentId,
      fileName: fileName,
      displayName: displayName,
      sizeBytes: sizeBytes,
      pageCount: pageCount,
      metadata: metadata,
      status: status,
    );

    return PdfImportResult(
      document: document,
      warnings: warnings,
      errors: errors,
    );
  }
}
