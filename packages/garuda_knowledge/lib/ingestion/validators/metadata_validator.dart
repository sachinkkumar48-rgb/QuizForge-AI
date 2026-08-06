import '../models/knowledge_document.dart';
import 'ingestion_document_validator.dart';

/// Validates required metadata fields on KnowledgeDocument.
class MetadataValidator implements IngestionDocumentValidator {
  @override
  String get name => 'MetadataValidator';

  @override
  Future<IngestionValidationResult> validate(KnowledgeDocument document) async {
    final issues = <IngestionValidationIssue>[];

    if (document.title.trim().isEmpty) {
      issues.add(const IngestionValidationIssue(
        code: 'MISSING_TITLE',
        message: 'Document title cannot be empty.',
        isCritical: true,
      ));
    }

    if (document.source.sourceId.trim().isEmpty) {
      issues.add(const IngestionValidationIssue(
        code: 'MISSING_SOURCE_ID',
        message: 'Document source identifier cannot be empty.',
        isCritical: true,
      ));
    }

    if (document.language.trim().isEmpty) {
      issues.add(const IngestionValidationIssue(
        code: 'MISSING_LANGUAGE',
        message: 'Document language must be specified.',
        isCritical: false,
      ));
    }

    return issues.isEmpty
        ? IngestionValidationResult.valid()
        : IngestionValidationResult.invalid(issues);
  }
}
