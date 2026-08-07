import '../../domain/entities/evidence_object.dart';
import '../../domain/repositories/evidence_repository.dart';
import 'evidence_validator.dart';
import 'validation_result.dart';

/// Validator that checks for duplicate Evidence Object IDs or URLs in the repository.
class DuplicateValidator implements EvidenceValidator {
  final EvidenceRepository? repository;

  DuplicateValidator([this.repository]);

  @override
  String get name => 'DuplicateValidator';

  @override
  Future<ValidationResult> validate(EvidenceObject evidence) async {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    if (evidence.id.trim().isEmpty) {
      errors.add(const ValidationError(
        code: 'EMPTY_ID',
        field: 'id',
        message: 'Evidence ID cannot be empty.',
      ));
    }

    if (repository != null && evidence.id.isNotEmpty) {
      final existing = await repository!.findById(evidence.id);
      if (existing != null && existing.version == evidence.version) {
        warnings.add(ValidationWarning(
          code: 'DUPLICATE_ID_VERSION',
          field: 'id',
          message: 'Evidence object with ID ${evidence.id} and version ${evidence.version} already exists.',
        ));
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors: errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}
