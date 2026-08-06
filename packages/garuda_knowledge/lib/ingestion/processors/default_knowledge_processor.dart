import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/knowledge_document.dart';
import 'knowledge_processor.dart';

/// Default Document Processor for content normalization and checksum calculation.
class DefaultKnowledgeProcessor implements KnowledgeProcessor {
  @override
  ProcessingResult process(KnowledgeDocument document) {
    try {
      // Clean up whitespace & line endings
      final normalizedContent = document.content
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .trim();

      if (normalizedContent.isEmpty) {
        return ProcessingResult(
          isSuccess: false,
          processedDocument: document,
          errorMessage: 'Normalized content is empty',
        );
      }

      // Recompute SHA-256 checksum if missing or mismatch
      final bytes = utf8.encode(normalizedContent);
      final computedChecksum = sha256.convert(bytes).toString();

      final updatedDoc = document.copyWith(
        content: normalizedContent,
        checksum: computedChecksum,
      );

      return ProcessingResult(
        isSuccess: true,
        processedDocument: updatedDoc,
      );
    } catch (e) {
      return ProcessingResult(
        isSuccess: false,
        processedDocument: document,
        errorMessage: 'Failed to process document: $e',
      );
    }
  }
}
