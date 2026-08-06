import '../models/knowledge_document.dart';
import 'ingestion_document_validator.dart';

/// Validates supported document formats and MIME types.
class FormatValidator implements IngestionDocumentValidator {
  final List<String> supportedFormats;

  FormatValidator({
    this.supportedFormats = const ['txt', 'md', 'json', 'pdf', 'html', 'text'],
  });

  @override
  String get name => 'FormatValidator';

  @override
  Future<IngestionValidationResult> validate(KnowledgeDocument document) async {
    final issues = <IngestionValidationIssue>[];

    final format = (document.metadata['format'] ?? document.metadata['extension'] ?? 'txt')
        .toString()
        .toLowerCase()
        .replaceAll('.', '');

    if (!supportedFormats.contains(format)) {
      issues.add(IngestionValidationIssue(
        code: 'UNSUPPORTED_FORMAT',
        message: 'Document format "$format" is not in supported formats ($supportedFormats).',
        isCritical: true,
      ));
    }

    return issues.isEmpty
        ? IngestionValidationResult.valid()
        : IngestionValidationResult.invalid(issues);
  }
}
