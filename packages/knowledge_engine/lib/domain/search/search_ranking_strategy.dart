import '../entities/knowledge_object.dart';
import 'knowledge_search_query.dart';

/// Abstract contract for deterministic ranking strategies evaluating [KnowledgeObject]
/// relevance against a [KnowledgeSearchQuery].
abstract class SearchRankingStrategy {
  /// Calculates a numerical relevance score for an individual [KnowledgeObject].
  double calculateScore(
    KnowledgeObject object,
    KnowledgeSearchQuery query, {
    Set<String>? connectedGraphNodeIds,
  });

  /// Ranks and sorts a candidate list of [KnowledgeObject] entities deterministically.
  List<KnowledgeObject> rank(
    List<KnowledgeObject> candidates,
    KnowledgeSearchQuery query, {
    Set<String>? connectedGraphNodeIds,
  });
}

/// Default deterministic, storage-independent ranking strategy implementation for TITAN.
///
/// Features:
/// - **Exact Title / ID Match**: Highest weight boost (+100.0 pts).
/// - **Title Keyword Matches**: High weight boost (+30.0 pts per term).
/// - **Subject & Topic Matches**: Medium weight boost (+20.0 pts per match).
/// - **Summary & Keyword Matches**: Contextual boost (+10.0 pts per match).
/// - **Graph Proximity Boost**: Proximity boost for graph-connected node IDs (+15.0 pts).
/// - **Deterministic Tie-Breaking**: Strict secondary sorting by ID to guarantee identical results across runs.
class DefaultSearchRankingStrategy implements SearchRankingStrategy {
  const DefaultSearchRankingStrategy();

  @override
  double calculateScore(
    KnowledgeObject object,
    KnowledgeSearchQuery query, {
    Set<String>? connectedGraphNodeIds,
  }) {
    double score = 0.0;
    final text = query.freeText?.trim().toLowerCase();

    if (text != null && text.isNotEmpty) {
      final titleLower = object.title.trim().toLowerCase();
      final idLower = object.id.trim().toLowerCase();

      // 1. Exact Match Boost
      if (titleLower == text || idLower == text) {
        score += 100.0;
      }

      // Tokenize search query terms
      final terms =
          text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

      for (final term in terms) {
        // 2. Title Keyword Match
        if (titleLower.contains(term)) {
          score += 30.0;
        }

        // 3. Summary Match
        if (object.summary.toLowerCase().contains(term)) {
          score += 10.0;
        }

        // 4. Keyword List Match
        for (final kw in object.keywords) {
          if (kw.toLowerCase().contains(term)) {
            score += 10.0;
          }
        }
      }
    }

    // 5. Subject Matches
    for (final qSubject in query.subjects) {
      final qSubLower = qSubject.trim().toLowerCase();
      for (final sSubject in object.subjects) {
        if (sSubject.toLowerCase() == qSubLower) {
          score += 20.0;
        }
      }
    }

    // 6. Topic Matches
    for (final qTopic in query.topics) {
      final qTopLower = qTopic.trim().toLowerCase();
      for (final sTopic in object.topics) {
        if (sTopic.toLowerCase() == qTopLower) {
          score += 20.0;
        }
      }
    }

    // 7. Graph Proximity Boost
    if (connectedGraphNodeIds != null &&
        connectedGraphNodeIds.contains(object.id)) {
      score += 15.0;
    }

    return score;
  }

  @override
  List<KnowledgeObject> rank(
    List<KnowledgeObject> candidates,
    KnowledgeSearchQuery query, {
    Set<String>? connectedGraphNodeIds,
  }) {
    if (candidates.isEmpty) return const [];

    final scoredItems = candidates.map((obj) {
      final score = calculateScore(
        obj,
        query,
        connectedGraphNodeIds: connectedGraphNodeIds,
      );
      return _ScoredObject(object: obj, score: score);
    }).toList();

    scoredItems.sort((a, b) {
      switch (query.sortOrder) {
        case SearchSortOrder.relevance:
          final cmpScore = b.score.compareTo(a.score);
          if (cmpScore != 0) return cmpScore;
          return a.object.id.compareTo(b.object.id);

        case SearchSortOrder.newestFirst:
          final cmpDate = b.object.createdAt.compareTo(a.object.createdAt);
          if (cmpDate != 0) return cmpDate;
          return a.object.id.compareTo(b.object.id);

        case SearchSortOrder.oldestFirst:
          final cmpDate = a.object.createdAt.compareTo(b.object.createdAt);
          if (cmpDate != 0) return cmpDate;
          return a.object.id.compareTo(b.object.id);

        case SearchSortOrder.titleAscending:
          final cmpTitle = a.object.title.compareTo(b.object.title);
          if (cmpTitle != 0) return cmpTitle;
          return a.object.id.compareTo(b.object.id);

        case SearchSortOrder.titleDescending:
          final cmpTitle = b.object.title.compareTo(a.object.title);
          if (cmpTitle != 0) return cmpTitle;
          return a.object.id.compareTo(b.object.id);
      }
    });

    return scoredItems.map((e) => e.object).toList();
  }
}

class _ScoredObject {
  final KnowledgeObject object;
  final double score;

  _ScoredObject({required this.object, required this.score});
}
