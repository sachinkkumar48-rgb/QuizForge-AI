import '../domain/entities/knowledge_object.dart';
import 'validation_result.dart';

class InvalidRelationshipValidator {
  ValidationResult validate(List<KnowledgeObject> objects) {
    final issues = <ValidationIssue>[];

    for (final obj in objects) {
      for (final rel in obj.relationships) {
        if (rel.sourceId == rel.targetId) {
          issues.add(ValidationIssue(
            code: 'INVALID_SELF_RELATIONSHIP',
            message: 'Self-referencing relationship ${rel.id} on object ${obj.id.value}',
            objectId: obj.id.value,
            severity: ValidationSeverity.error,
          ));
        }
        if (rel.weight <= 0.0) {
          issues.add(ValidationIssue(
            code: 'INVALID_RELATIONSHIP_WEIGHT',
            message: 'Relationship ${rel.id} has invalid non-positive weight: ${rel.weight}',
            objectId: obj.id.value,
            severity: ValidationSeverity.warning,
          ));
        }
      }
    }

    return ValidationResult(issues: issues);
  }
}
