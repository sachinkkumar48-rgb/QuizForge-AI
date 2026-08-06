import '../models/knowledge_document.dart';
import 'checksum_validator.dart';
import 'content_validator.dart';
import 'duplicate_document_validator.dart';
import 'format_validator.dart';
import 'ingestion_document_validator.dart';
import 'metadata_validator.dart';
import 'reference_validator.dart';
import 'version_validator.dart';

/// Master Composite Validator running all 7 validation rules.
class CompositeIngestionValidator {
  final List<IngestionDocumentValidator> validators;

  CompositeIngestionValidator({
    List<IngestionDocumentValidator>? validators,
    DuplicateDocumentValidator? duplicateValidator,
  }) : validators = validators ??
            [
              ChecksumValidator(),
              duplicateValidator ?? DuplicateDocumentValidator(),
              MetadataValidator(),
              FormatValidator(),
              ReferenceValidator(),
              VersionValidator(),
              ContentValidator(),
            ];

  Future<IngestionValidationResult> validate(KnowledgeDocument document) async {
    final allIssues = <IngestionValidationIssue>[];

    for (final validator in validators) {
      final result = await validator.validate(document);
      if (!result.isValid) {
        allIssues.addAll(result.issues);
      }
    }

    return allIssues.isEmpty
        ? IngestionValidationResult.valid()
        : IngestionValidationResult.invalid(allIssues);
  }
}
