import '../../domain/entities/evidence_object.dart';
import 'evidence_validator.dart';
import 'validation_result.dart';

/// Validator for mandatory metadata fields of an Evidence Object.
class MetadataValidator implements EvidenceValidator {
  @override
  String get name => 'MetadataValidator';

  @override
  Future<ValidationResult> validate(EvidenceObject evidence) async {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    if (evidence.title.trim().isEmpty) {
      errors.add(const ValidationError(
        code: 'MISSING_TITLE',
        field: 'title',
        message: 'Title is mandatory and cannot be empty.',
      ));
    }

    if (evidence.sourceName.trim().isEmpty) {
      errors.add(const ValidationError(
        code: 'MISSING_SOURCE_NAME',
        field: 'sourceName',
        message: 'Source Name is mandatory.',
      ));
    }

    if (evidence.summary.trim().isEmpty) {
      warnings.add(const ValidationWarning(
        code: 'MISSING_SUMMARY',
        field: 'summary',
        message: 'Evidence object summary is recommended for indexing.',
      ));
    }

    if (evidence.keywords.isEmpty) {
      warnings.add(const ValidationWarning(
        code: 'MISSING_KEYWORDS',
        field: 'keywords',
        message: 'At least one keyword is recommended for search optimization.',
      ));
    }

    if (evidence.confidenceScore < 0.0 || evidence.confidenceScore > 1.0) {
      errors.add(const ValidationError(
        code: 'INVALID_CONFIDENCE_SCORE',
        field: 'confidenceScore',
        message: 'Confidence score must be between 0.0 and 1.0.',
      ));
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors: errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}
