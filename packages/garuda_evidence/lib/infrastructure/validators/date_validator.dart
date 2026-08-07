import '../../domain/entities/evidence_object.dart';
import 'evidence_validator.dart';
import 'validation_result.dart';

/// Validator for date fields (publication date, retrieved date, created at, updated at).
class DateValidator implements EvidenceValidator {
  @override
  String get name => 'DateValidator';

  @override
  Future<ValidationResult> validate(EvidenceObject evidence) async {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    final now = DateTime.now().add(const Duration(days: 1)); // allow minor clock skew

    if (evidence.publicationDate.isAfter(now)) {
      errors.add(ValidationError(
        code: 'FUTURE_PUBLICATION_DATE',
        field: 'publicationDate',
        message: 'Publication date ${evidence.publicationDate} cannot be in the future.',
      ));
    }

    if (evidence.publicationDate.isAfter(evidence.retrievedDate)) {
      warnings.add(const ValidationWarning(
        code: 'PUBLICATION_AFTER_RETRIEVAL',
        field: 'publicationDate',
        message: 'Publication date is set after retrieval date.',
      ));
    }

    if (evidence.createdAt.isAfter(evidence.updatedAt)) {
      errors.add(const ValidationError(
        code: 'CREATED_AFTER_UPDATED',
        field: 'createdAt',
        message: 'Created timestamp cannot be after updated timestamp.',
      ));
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors: errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}
