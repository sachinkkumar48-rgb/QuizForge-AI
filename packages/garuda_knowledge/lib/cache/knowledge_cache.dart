import '../query/knowledge_query.dart';
import '../query/knowledge_search_result.dart';

/// Four-tier in-memory caching engine supporting automatic pipeline invalidation.
class KnowledgeCache {
  final Map<String, KnowledgeSearchResult> _queryCache = {};
  final Map<String, List<String>> _suggestionCache = {};
  final Map<String, Set<String>> _indexCache = {};

  int _queryHits = 0;
  int _queryMisses = 0;

  double get cacheHitRate {
    final total = _queryHits + _queryMisses;
    if (total == 0) return 0.0;
    return _queryHits / total;
  }

  int get totalCachedQueries => _queryCache.length;
  int get totalCachedSuggestions => _suggestionCache.length;

  /// Retrieves cached search result if available.
  KnowledgeSearchResult? getQueryResult(KnowledgeQuery query) {
    final key = _computeQueryKey(query);
    final cached = _queryCache[key];
    if (cached != null) {
      _queryHits++;
      return KnowledgeSearchResult(
        hits: cached.hits,
        totalHits: cached.totalHits,
        latencyMs: 0.1,
        isCacheHit: true,
        query: query,
      );
    }
    _queryMisses++;
    return null;
  }

  /// Stores a search result in the query cache.
  void putQueryResult(KnowledgeQuery query, KnowledgeSearchResult result) {
    final key = _computeQueryKey(query);
    _queryCache[key] = result;
  }

  /// Retrieves cached suggestions.
  List<String>? getSuggestions(String prefix) {
    return _suggestionCache[prefix.toLowerCase().trim()];
  }

  /// Stores suggestions.
  void putSuggestions(String prefix, List<String> suggestions) {
    _suggestionCache[prefix.toLowerCase().trim()] = suggestions;
  }

  /// Retrieves cached index token set.
  Set<String>? getIndexSet(String token) {
    return _indexCache[token.toLowerCase().trim()];
  }

  /// Stores index token set.
  void putIndexSet(String token, Set<String> ids) {
    _indexCache[token.toLowerCase().trim()] = Set.from(ids);
  }

  /// Automatic invalidation trigger after registration pipeline completes or index changes.
  void invalidateAll() {
    _queryCache.clear();
    _suggestionCache.clear();
    _indexCache.clear();
  }

  /// Clears hit stats.
  void resetMetrics() {
    _queryHits = 0;
    _queryMisses = 0;
  }

  String _computeQueryKey(KnowledgeQuery query) {
    return '${query.rawQuery}:${query.queryType}:${query.limit}:${query.offset}:${query.targetType}:${query.targetTag}:${query.relationshipType}:${query.minScore}';
  }
}
