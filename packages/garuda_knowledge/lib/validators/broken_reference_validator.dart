import '../domain/entities/knowledge_object.dart';
import 'validation_result.dart';

class BrokenReferenceValidator {
  ValidationResult validate(List<KnowledgeObject> objects) {
    final issues = <ValidationIssue>[];
    final validIds = objects.map((o) => o.id.value).toSet();

    for (final obj in objects) {
      for (final ref in obj.references) {
        if (!validIds.contains(ref.targetId.value)) {
          issues.add(ValidationIssue(
            code: 'BROKEN_REFERENCE',
            message: 'Object ${obj.id.value} references non-existent ID: ${ref.targetId.value}',
            objectId: obj.id.value,
            severity: ValidationSeverity.error,
          ));
        }
      }

      for (final rel in obj.relationships) {
        if (!validIds.contains(rel.targetId.value)) {
          issues.add(ValidationIssue(
            code: 'BROKEN_RELATIONSHIP_TARGET',
            message: 'Relationship ${rel.id} points to non-existent target ID: ${rel.targetId.value}',
            objectId: obj.id.value,
            severity: ValidationSeverity.error,
          ));
        }
      }
    }

    return ValidationResult(issues: issues);
  }
}
