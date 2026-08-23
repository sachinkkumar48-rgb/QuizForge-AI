import '../models/generated_question.dart';

/// Service performing deterministic local deduplication of generated questions across batches.
class QuestionDeduplicator {
  final double similarityThreshold;

  const QuestionDeduplicator({this.similarityThreshold = 0.85});

  /// Deduplicates [questions] and returns a unique subset preserving original order.
  List<GeneratedQuestion> deduplicate(List<GeneratedQuestion> questions) {
    if (questions.length <= 1) return questions;

    final result = <GeneratedQuestion>[];
    final normalizedSeen = <String>[];

    for (final q in questions) {
      final norm = _normalizeText(q.questionText);
      if (norm.isEmpty) continue;

      var isDuplicate = false;
      for (final seen in normalizedSeen) {
        if (norm == seen ||
            _calculateJaccardSimilarity(norm, seen) >= similarityThreshold) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        result.add(q);
        normalizedSeen.add(norm);
      }
    }

    return List.unmodifiable(result);
  }

  /// Normalizes question text for robust comparison.
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculates token-based Jaccard similarity coefficient between two normalized strings.
  double _calculateJaccardSimilarity(String s1, String s2) {
    final tokens1 = s1.split(' ').where((t) => t.isNotEmpty).toSet();
    final tokens2 = s2.split(' ').where((t) => t.isNotEmpty).toSet();

    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;

    final intersection = tokens1.intersection(tokens2).length;
    final union = tokens1.union(tokens2).length;

    if (union == 0) return 0.0;
    return intersection / union;
  }
}
