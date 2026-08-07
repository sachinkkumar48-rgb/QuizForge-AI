import '../../domain/entities/evidence_object.dart';
import 'evidence_validator.dart';
import 'validation_result.dart';

/// Validator that checks authority attributes of an Evidence Object.
class AuthorityValidator implements EvidenceValidator {
  @override
  String get name => 'AuthorityValidator';

  @override
  Future<ValidationResult> validate(EvidenceObject evidence) async {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    final authority = evidence.authority;
    if (authority.id.trim().isEmpty) {
      errors.add(const ValidationError(
        code: 'MISSING_AUTHORITY_ID',
        field: 'authority.id',
        message: 'Authority ID cannot be empty.',
      ));
    }

    if (authority.name.trim().isEmpty) {
      errors.add(const ValidationError(
        code: 'MISSING_AUTHORITY_NAME',
        field: 'authority.name',
        message: 'Authority Name cannot be empty.',
      ));
    }

    if (authority.jurisdiction.trim().isEmpty) {
      warnings.add(const ValidationWarning(
        code: 'MISSING_JURISDICTION',
        field: 'authority.jurisdiction',
        message: 'Jurisdiction should be explicitly defined.',
      ));
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors: errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}
