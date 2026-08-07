import '../../infrastructure/validators/composite_evidence_validator.dart';
import '../../infrastructure/validators/validation_result.dart';
import '../entities/evidence_object.dart';

/// Use case for executing complete validation of an [EvidenceObject].
class ValidateEvidenceUseCase {
  final CompositeEvidenceValidator validator;

  ValidateEvidenceUseCase(this.validator);

  Future<ValidationResult> call(EvidenceObject evidence) async {
    return await validator.validate(evidence);
  }
}
