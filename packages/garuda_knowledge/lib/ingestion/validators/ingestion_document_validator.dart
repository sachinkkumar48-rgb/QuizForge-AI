import '../models/knowledge_document.dart';

/// Single validation issue found during document validation.
class IngestionValidationIssue {
  final String code;
  final String message;
  final bool isCritical;

  const IngestionValidationIssue({
    required this.code,
    required this.message,
    this.isCritical = true,
  });

  @override
  String toString() => '[$code] $message (Critical: $isCritical)';
}

/// Aggregated result of document validation.
class IngestionValidationResult {
  final bool isValid;
  final List<IngestionValidationIssue> issues;

  const IngestionValidationResult({
    required this.isValid,
    this.issues = const [],
  });

  factory IngestionValidationResult.valid() =>
      const IngestionValidationResult(isValid: true);

  factory IngestionValidationResult.invalid(List<IngestionValidationIssue> issues) =>
      IngestionValidationResult(isValid: false, issues: issues);
}

/// Abstract contract for individual document validation checks.
abstract class IngestionDocumentValidator {
  String get name;
  Future<IngestionValidationResult> validate(KnowledgeDocument document);
}
