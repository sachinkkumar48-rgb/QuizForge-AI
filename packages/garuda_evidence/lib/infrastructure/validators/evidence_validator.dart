import '../../domain/entities/evidence_object.dart';
import 'validation_result.dart';

/// Base abstract interface for an Evidence Object validator.
abstract class EvidenceValidator {
  String get name;
  Future<ValidationResult> validate(EvidenceObject evidence);
}
