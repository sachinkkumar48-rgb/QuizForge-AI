import '../domain/entities/knowledge_object.dart';
import 'validation_result.dart';

class InvalidVersionValidator {
  ValidationResult validate(List<KnowledgeObject> objects) {
    final issues = <ValidationIssue>[];

    for (final obj in objects) {
      if (obj.currentVersion.versionNumber <= 0) {
        issues.add(ValidationIssue(
          code: 'INVALID_VERSION_NUMBER',
          message: 'Current version number must be positive: ${obj.currentVersion.versionNumber}',
          objectId: obj.id.value,
          severity: ValidationSeverity.error,
        ));
      }

      int prev = 0;
      for (final v in obj.versionHistory) {
        if (v.versionNumber <= prev) {
          issues.add(ValidationIssue(
            code: 'NON_MONOTONIC_VERSION_HISTORY',
            message: 'Version history out of sequence: ${v.versionNumber} after $prev',
            objectId: obj.id.value,
            severity: ValidationSeverity.error,
          ));
        }
        prev = v.versionNumber;
      }

      if (obj.versionHistory.isNotEmpty && obj.currentVersion.versionNumber <= prev) {
        issues.add(ValidationIssue(
          code: 'CURRENT_VERSION_REGRESSION',
          message: 'Current version (${obj.currentVersion.versionNumber}) must be greater than history version ($prev)',
          objectId: obj.id.value,
          severity: ValidationSeverity.error,
        ));
      }
    }

    return ValidationResult(issues: issues);
  }
}
