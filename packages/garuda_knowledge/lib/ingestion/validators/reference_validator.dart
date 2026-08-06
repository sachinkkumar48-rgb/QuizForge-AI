import '../models/knowledge_document.dart';
import 'ingestion_document_validator.dart';

/// Validates broken references or missing target citations within document metadata.
class ReferenceValidator implements IngestionDocumentValidator {
  @override
  String get name => 'ReferenceValidator';

  @override
  Future<IngestionValidationResult> validate(KnowledgeDocument document) async {
    final issues = <IngestionValidationIssue>[];

    final refs = document.metadata['references'];
    if (refs is List) {
      for (int i = 0; i < refs.length; i++) {
        final ref = refs[i];
        if (ref == null || ref.toString().trim().isEmpty) {
          issues.add(IngestionValidationIssue(
            code: 'BROKEN_REFERENCE',
            message: 'Reference at index $i is null or empty in document "${document.documentId}".',
            isCritical: false,
          ));
        }
      }
    }

    return issues.isEmpty
        ? IngestionValidationResult.valid()
        : IngestionValidationResult.invalid(issues);
  }
}
