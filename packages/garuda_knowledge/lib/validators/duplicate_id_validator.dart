import '../domain/entities/knowledge_object.dart';
import 'validation_result.dart';

class DuplicateIdValidator {
  ValidationResult validate(List<KnowledgeObject> objects) {
    final seen = <String>{};
    final issues = <ValidationIssue>[];

    for (final obj in objects) {
      if (seen.contains(obj.id.value)) {
        issues.add(ValidationIssue(
          code: 'DUPLICATE_ID',
          message: 'Duplicate KnowledgeObject ID detected: ${obj.id.value}',
          objectId: obj.id.value,
          severity: ValidationSeverity.error,
        ));
      } else {
        seen.add(obj.id.value);
      }
    }

    return ValidationResult(issues: issues);
  }
}
