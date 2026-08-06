import '../models/knowledge_document.dart';
import 'ingestion_document_validator.dart';

/// Validates semver formatting and version validity of incoming KnowledgeDocument.
class VersionValidator implements IngestionDocumentValidator {
  final RegExp _semverRegex = RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$');

  @override
  String get name => 'VersionValidator';

  @override
  Future<IngestionValidationResult> validate(KnowledgeDocument document) async {
    final issues = <IngestionValidationIssue>[];

    if (!_semverRegex.hasMatch(document.version)) {
      issues.add(IngestionValidationIssue(
        code: 'INVALID_VERSION_FORMAT',
        message: 'Document version "${document.version}" does not conform to semver format (X.Y.Z).',
        isCritical: true,
      ));
    }

    return issues.isEmpty
        ? IngestionValidationResult.valid()
        : IngestionValidationResult.invalid(issues);
  }
}
