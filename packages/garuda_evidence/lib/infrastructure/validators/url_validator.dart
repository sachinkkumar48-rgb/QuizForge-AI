import '../../domain/entities/evidence_object.dart';
import 'evidence_validator.dart';
import 'validation_result.dart';

/// Validator that checks URL format validity for originalUrl and pdfUrl.
class URLValidator implements EvidenceValidator {
  @override
  String get name => 'URLValidator';

  @override
  Future<ValidationResult> validate(EvidenceObject evidence) async {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    if (evidence.originalUrl.trim().isEmpty) {
      errors.add(const ValidationError(
        code: 'MISSING_ORIGINAL_URL',
        field: 'originalUrl',
        message: 'Original URL cannot be empty.',
      ));
    } else {
      final uri = Uri.tryParse(evidence.originalUrl);
      if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https') && !uri.scheme.startsWith('file'))) {
        errors.add(ValidationError(
          code: 'INVALID_ORIGINAL_URL',
          field: 'originalUrl',
          message: 'Invalid original URL format: ${evidence.originalUrl}',
        ));
      }
    }

    if (evidence.pdfUrl != null && evidence.pdfUrl!.isNotEmpty) {
      final pdfUri = Uri.tryParse(evidence.pdfUrl!);
      if (pdfUri == null || !pdfUri.hasScheme) {
        warnings.add(ValidationWarning(
          code: 'INVALID_PDF_URL',
          field: 'pdfUrl',
          message: 'Malformed PDF URL format: ${evidence.pdfUrl}',
        ));
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors: errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}
