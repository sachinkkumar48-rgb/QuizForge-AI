import '../models/knowledge_document.dart';
import 'ingestion_document_validator.dart';

/// Validates duplicate document IDs or duplicate checksums against a store of ingested hashes.
class DuplicateDocumentValidator implements IngestionDocumentValidator {
  final Set<String> _seenChecksums;
  final Set<String> _seenDocumentIds;

  DuplicateDocumentValidator({
    Set<String>? seenChecksums,
    Set<String>? seenDocumentIds,
  })  : _seenChecksums = seenChecksums ?? {},
        _seenDocumentIds = seenDocumentIds ?? {};

  void registerDocument(KnowledgeDocument document) {
    _seenDocumentIds.add(document.documentId);
    _seenChecksums.add(document.checksum);
  }

  @override
  String get name => 'DuplicateDocumentValidator';

  @override
  Future<IngestionValidationResult> validate(KnowledgeDocument document) async {
    final issues = <IngestionValidationIssue>[];

    if (_seenDocumentIds.contains(document.documentId)) {
      issues.add(IngestionValidationIssue(
        code: 'DUPLICATE_DOCUMENT_ID',
        message: 'Document ID "${document.documentId}" has already been ingested in this session.',
        isCritical: true,
      ));
    }

    if (_seenChecksums.contains(document.checksum)) {
      issues.add(IngestionValidationIssue(
        code: 'DUPLICATE_CHECKSUM',
        message: 'Document content with checksum "${document.checksum}" has already been ingested.',
        isCritical: true,
      ));
    }

    return issues.isEmpty
        ? IngestionValidationResult.valid()
        : IngestionValidationResult.invalid(issues);
  }
}
