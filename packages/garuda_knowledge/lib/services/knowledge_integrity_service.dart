import '../repositories/knowledge_repository.dart';
import '../validators/broken_reference_validator.dart';
import '../validators/circular_reference_validator.dart';
import '../validators/duplicate_id_validator.dart';
import '../validators/duplicate_relationship_validator.dart';
import '../validators/invalid_relationship_validator.dart';
import '../validators/invalid_version_validator.dart';
import '../validators/missing_evidence_validator.dart';
import '../validators/validation_result.dart';

class KnowledgeIntegrityReport {
  final bool isValid;
  final List<ValidationIssue> allIssues;

  const KnowledgeIntegrityReport({
    required this.isValid,
    required this.allIssues,
  });
}

class KnowledgeIntegrityService {
  final KnowledgeRepository _repository;

  final _dupIdVal = DuplicateIdValidator();
  final _circRefVal = CircularReferenceValidator();
  final _brokenRefVal = BrokenReferenceValidator();
  final _missingEvVal = MissingEvidenceValidator();
  final _invalidRelVal = InvalidRelationshipValidator();
  final _invalidVerVal = InvalidVersionValidator();
  final _dupRelVal = DuplicateRelationshipValidator();

  KnowledgeIntegrityService(this._repository);

  Future<KnowledgeIntegrityReport> checkIntegrity() async {
    final objects = await _repository.bulkExport();
    final issues = <ValidationIssue>[];

    issues.addAll(_dupIdVal.validate(objects).issues);
    issues.addAll(_circRefVal.validate(objects).issues);
    issues.addAll(_brokenRefVal.validate(objects).issues);
    issues.addAll(_missingEvVal.validate(objects).issues);
    issues.addAll(_invalidRelVal.validate(objects).issues);
    issues.addAll(_invalidVerVal.validate(objects).issues);
    issues.addAll(_dupRelVal.validate(objects).issues);

    final isValid = issues.every((i) => i.severity != ValidationSeverity.error);
    return KnowledgeIntegrityReport(isValid: isValid, allIssues: issues);
  }
}
