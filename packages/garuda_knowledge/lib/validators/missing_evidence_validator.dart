import '../domain/entities/knowledge_object.dart';
import '../domain/enums/knowledge_object_type.dart';
import 'validation_result.dart';

class MissingEvidenceValidator {
  ValidationResult validate(List<KnowledgeObject> objects) {
    final issues = <ValidationIssue>[];

    final evidenceRequiredTypes = {
      KnowledgeObjectType.caseLaw,
      KnowledgeObjectType.currentAffair,
      KnowledgeObjectType.report,
    };

    for (final obj in objects) {
      if (evidenceRequiredTypes.contains(obj.type)) {
        if (obj.evidenceReferences.isEmpty && obj.citations.isEmpty && obj.sources.isEmpty) {
          issues.add(ValidationIssue(
            code: 'MISSING_EVIDENCE',
            message: 'KnowledgeObject ${obj.id.value} of type ${obj.type.name} has no evidence, sources, or citations.',
            objectId: obj.id.value,
            severity: ValidationSeverity.warning,
          ));
        }
      }
    }

    return ValidationResult(issues: issues);
  }
}
