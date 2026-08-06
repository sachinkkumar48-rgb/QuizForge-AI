import '../models/knowledge_document.dart';
import 'ingestion_document_validator.dart';

/// Validates document content for malformed structures or missing payload.
class ContentValidator implements IngestionDocumentValidator {
  final int minContentLength;

  ContentValidator({this.minContentLength = 5});

  @override
  String get name => 'ContentValidator';

  @override
  Future<IngestionValidationResult> validate(KnowledgeDocument document) async {
    final issues = <IngestionValidationIssue>[];

    if (document.content.trim().length < minContentLength) {
      issues.add(IngestionValidationIssue(
        code: 'MALFORMED_CONTENT',
        message: 'Document content is too short or malformed (length < $minContentLength).',
        isCritical: true,
      ));
    }

    return issues.isEmpty
        ? IngestionValidationResult.valid()
        : IngestionValidationResult.invalid(issues);
  }
}
