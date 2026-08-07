import '../../domain/entities/evidence_object.dart';
import '../../domain/repositories/evidence_repository.dart';
import 'authority_validator.dart';
import 'date_validator.dart';
import 'duplicate_validator.dart';
import 'evidence_validator.dart';
import 'json_validator.dart';
import 'metadata_validator.dart';
import 'url_validator.dart';
import 'validation_result.dart';

/// Aggregator validator running all 6 core validators on an Evidence Object.
class CompositeEvidenceValidator {
  final List<EvidenceValidator> validators;

  CompositeEvidenceValidator(this.validators);

  factory CompositeEvidenceValidator.standard([EvidenceRepository? repository]) {
    return CompositeEvidenceValidator([
      DuplicateValidator(repository),
      MetadataValidator(),
      AuthorityValidator(),
      DateValidator(),
      URLValidator(),
      JSONValidator(),
    ]);
  }

  Future<ValidationResult> validate(EvidenceObject evidence) async {
    final allErrors = <ValidationError>[];
    final allWarnings = <ValidationWarning>[];

    for (final validator in validators) {
      final res = await validator.validate(evidence);
      if (!res.isValid) {
        allErrors.addAll(res.errors);
      }
      allWarnings.addAll(res.warnings);
    }

    if (allErrors.isNotEmpty) {
      return ValidationResult.failure(errors: allErrors, warnings: allWarnings);
    }

    return ValidationResult.success(warnings: allWarnings);
  }
}
