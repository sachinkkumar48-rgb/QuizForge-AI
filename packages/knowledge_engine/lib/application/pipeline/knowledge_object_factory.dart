import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../domain/entities/knowledge_object.dart';
import '../../domain/value_objects/knowledge_type.dart';

/// Factory responsible for instantiating immutable [KnowledgeObject] entities
/// from text chunks produced by the ingestion pipeline.
class KnowledgeObjectFactory {
  /// Creates a single [KnowledgeObject] from a text chunk.
  KnowledgeObject createFromChunk({
    required String chunkText,
    required int chunkIndex,
    required int totalChunks,
    required String sourceTitle,
    required KnowledgeType type,
    String source = '',
    String language = 'en',
    List<String> subjects = const [],
    List<String> topics = const [],
    List<String> keywords = const [],
    Map<String, dynamic> metadata = const {},
    String? baseId,
  }) {
    final wordCount = _calculateWordCount(chunkText);
    final charCount = chunkText.length;
    final generatedSummary = _generateSummarySnippet(chunkText);

    // Compute deterministic ID
    final rootId =
        baseId ?? _generateDeterministicHash(sourceTitle, source, chunkIndex);
    final objectId =
        totalChunks == 1 ? rootId : '$rootId-chunk-${chunkIndex + 1}';

    final mergedMetadata = Map<String, dynamic>.from(metadata)
      ..addAll({
        'chunkIndex': chunkIndex,
        'totalChunks': totalChunks,
        'wordCount': wordCount,
        'charCount': charCount,
        'fullChunkText': chunkText,
      });

    final chunkTitle = totalChunks == 1
        ? sourceTitle
        : '$sourceTitle (Part ${chunkIndex + 1}/$totalChunks)';

    return KnowledgeObject(
      id: objectId,
      type: type,
      title: chunkTitle,
      summary: generatedSummary,
      source: source,
      language: language,
      subjects: subjects,
      topics: topics,
      keywords: keywords,
      metadata: mergedMetadata,
    );
  }

  int _calculateWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  String _generateSummarySnippet(String chunkText, {int maxLen = 150}) {
    final trimmed = chunkText.trim();
    if (trimmed.length <= maxLen) {
      return trimmed;
    }

    // Try to cut at first sentence end
    final firstSentenceEnd = trimmed.indexOf(RegExp(r'[.!?]'));
    if (firstSentenceEnd > 20 && firstSentenceEnd <= maxLen) {
      return trimmed.substring(0, firstSentenceEnd + 1);
    }

    // Fallback cut on space boundary
    final spaceIndex = trimmed.lastIndexOf(' ', maxLen);
    if (spaceIndex > 0) {
      return '${trimmed.substring(0, spaceIndex)}...';
    }

    return '${trimmed.substring(0, maxLen)}...';
  }

  String _generateDeterministicHash(String title, String source, int index) {
    final rawKey = '$title::$source::$index';
    final bytes = utf8.encode(rawKey);
    final hash = sha256.convert(bytes);
    return 'cko_${hash.toString().substring(0, 16)}';
  }
}
