library;

import 'package:garuda_evidence/garuda_evidence.dart';

/// Deduplication engine evaluating evidence uniqueness using checksums, URLs, dates, and title similarity.
class EvidenceDeduplicator {
  /// Calculate title similarity ratio (Jaccard word similarity between 0.0 and 1.0).
  static double titleSimilarity(String titleA, String titleB) {
    final wordsA = titleA.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final wordsB = titleB.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    return intersection / union;
  }

  /// Check whether candidate EvidenceObject is a duplicate of an existing object.
  static bool isDuplicate(EvidenceObject candidate, EvidenceObject existing) {
    // 1. Exact ID match
    if (candidate.id == existing.id) return true;

    // 2. Exact Original URL match
    if (candidate.originalUrl.isNotEmpty &&
        EvidenceURLUtils.normalizeUrl(candidate.originalUrl) ==
            EvidenceURLUtils.normalizeUrl(existing.originalUrl)) {
      return true;
    }

    // 3. Exact Title + Same Publication Date
    if (candidate.title.toLowerCase().trim() == existing.title.toLowerCase().trim() &&
        candidate.publicationDate.year == existing.publicationDate.year &&
        candidate.publicationDate.month == existing.publicationDate.month &&
        candidate.publicationDate.day == existing.publicationDate.day) {
      return true;
    }

    // 4. High Title Similarity (> 0.85) + Same Source
    if (candidate.sourceName.toLowerCase() == existing.sourceName.toLowerCase()) {
      final sim = titleSimilarity(candidate.title, existing.title);
      if (sim >= 0.85) return true;
    }

    return false;
  }
}
