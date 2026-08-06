import '../models/knowledge_document.dart';

/// Result of preprocessing / cleaning a document payload.
class ProcessingResult {
  final bool isSuccess;
  final KnowledgeDocument processedDocument;
  final String? errorMessage;

  const ProcessingResult({
    required this.isSuccess,
    required this.processedDocument,
    this.errorMessage,
  });
}

/// Abstract contract for document preprocessing, sanitization, and SHA-256 verification.
abstract class KnowledgeProcessor {
  ProcessingResult process(KnowledgeDocument document);
}
