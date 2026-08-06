import '../domain/entities/knowledge_object.dart';
import 'validation_result.dart';

class DuplicateRelationshipValidator {
  ValidationResult validate(List<KnowledgeObject> objects) {
    final issues = <ValidationIssue>[];

    for (final obj in objects) {
      final seen = <String>{};
      for (final rel in obj.relationships) {
        final key = '${rel.sourceId.value}:${rel.targetId.value}:${rel.type.name}';
        if (seen.contains(key)) {
          issues.add(ValidationIssue(
            code: 'DUPLICATE_RELATIONSHIP',
            message: 'Duplicate relationship detected: $key',
            objectId: obj.id.value,
            severity: ValidationSeverity.warning,
          ));
        } else {
          seen.add(key);
        }
      }
    }

    return ValidationResult(issues: issues);
  }
}
