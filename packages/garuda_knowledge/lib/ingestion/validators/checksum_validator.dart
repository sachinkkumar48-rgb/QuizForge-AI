import '../models/knowledge_document.dart';
import 'ingestion_document_validator.dart';

/// Validates SHA-256 integrity of incoming KnowledgeDocument.
class ChecksumValidator implements IngestionDocumentValidator {
  @override
  String get name => 'ChecksumValidator';

  @override
  Future<IngestionValidationResult> validate(KnowledgeDocument document) async {
    final issues = <IngestionValidationIssue>[];

    if (document.checksum.isEmpty) {
      issues.add(const IngestionValidationIssue(
        code: 'CHECKSUM_MISSING',
        message: 'Document checksum (SHA-256) is missing.',
        isCritical: true,
      ));
    } else if (!document.verifyChecksum()) {
      issues.add(const IngestionValidationIssue(
        code: 'CHECKSUM_MISMATCH',
        message: 'Document content does not match the provided SHA-256 checksum.',
        isCritical: true,
      ));
    }

    return issues.isEmpty
        ? IngestionValidationResult.valid()
        : IngestionValidationResult.invalid(issues);
  }
}
