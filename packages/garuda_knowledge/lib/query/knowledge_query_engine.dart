import '../analytics/knowledge_search_analytics.dart';
import '../autocomplete/knowledge_autocomplete.dart';
import '../autocomplete/knowledge_suggestion_engine.dart';
import '../cache/knowledge_cache.dart';
import '../domain/entities/knowledge_object.dart';
import '../domain/enums/knowledge_object_type.dart';
import '../domain/enums/relationship_type.dart';
import '../filters/knowledge_filter.dart';
import '../indexing/knowledge_index.dart';
import '../indexing/knowledge_indexer.dart';
import '../ranking/knowledge_ranking_engine.dart';
import '../text/knowledge_normalizer.dart';
import '../text/knowledge_synonym_dictionary.dart';
import '../text/knowledge_tokenizer.dart';
import 'knowledge_query.dart';
import 'knowledge_query_builder.dart';
import 'knowledge_search_hit.dart';
import 'knowledge_search_result.dart';

/// Universal Knowledge Query Engine - Single Search Layer for all GARUDA Applications.
class KnowledgeQueryEngine {
  final KnowledgeIndex index;
  final KnowledgeIndexer indexer;
  final KnowledgeRankingEngine rankingEngine;
  final KnowledgeCache cache;
  final KnowledgeAutocomplete autocompleteEngine;
  final KnowledgeSuggestionEngine suggestionEngine;
  final KnowledgeSearchAnalytics analytics;
  final KnowledgeTokenizer tokenizer;
  final KnowledgeNormalizer normalizer;
  final KnowledgeSynonymDictionary synonyms;

  factory KnowledgeQueryEngine({
    KnowledgeIndex? index,
    KnowledgeIndexer? indexer,
    KnowledgeRankingEngine? rankingEngine,
    KnowledgeCache? cache,
    KnowledgeAutocomplete? autocompleteEngine,
    KnowledgeSuggestionEngine? suggestionEngine,
    KnowledgeTokenizer? tokenizer,
    KnowledgeNormalizer? normalizer,
    KnowledgeSynonymDictionary? synonyms,
  }) {
    final idx = index ?? KnowledgeIndex();
    final idxr = indexer ?? KnowledgeIndexer(idx);
    final tok = tokenizer ?? KnowledgeTokenizer();
    final norm = normalizer ?? KnowledgeNormalizer();
    final syn = synonyms ?? KnowledgeSynonymDictionary();
    final cch = cache ?? KnowledgeCache();

    return KnowledgeQueryEngine._(
      index: idx,
      indexer: idxr,
      rankingEngine: rankingEngine ??
          KnowledgeRankingEngine(
            tokenizer: tok,
            normalizer: norm,
            synonyms: syn,
          ),
      cache: cch,
      autocompleteEngine: autocompleteEngine ??
          KnowledgeAutocomplete(index: idx, normalizer: norm),
      suggestionEngine: suggestionEngine ??
          KnowledgeSuggestionEngine(
            index: idx,
            synonyms: syn,
            tokenizer: tok,
          ),
      analytics: KnowledgeSearchAnalytics(index: idx, cache: cch),
      tokenizer: tok,
      normalizer: norm,
      synonyms: syn,
    );
  }

  const KnowledgeQueryEngine._({
    required this.index,
    required this.indexer,
    required this.rankingEngine,
    required this.cache,
    required this.autocompleteEngine,
    required this.suggestionEngine,
    required this.analytics,
    required this.tokenizer,
    required this.normalizer,
    required this.synonyms,
  });

  /// Primary search entry point handling all KnowledgeQuery parameters.
  Future<KnowledgeSearchResult> search(KnowledgeQuery query) async {
    final stopwatch = Stopwatch()..start();

    // Check cache first
    final cachedResult = cache.getQueryResult(query);
    if (cachedResult != null) {
      return cachedResult;
    }

    final candidates = _resolveCandidates(query);
    final terms = tokenizer.tokenize(query.rawQuery).toSet();

    final hits = <KnowledgeSearchHit>[];
    for (final obj in candidates) {
      if (!query.filter.matches(obj)) continue;

      final hit = rankingEngine.rank(
        object: obj,
        query: query,
        queryTerms: terms,
      );

      if (hit.score >= query.minScore) {
        hits.add(hit);
      }
    }

    // Sort hits descending by relevance score
    hits.sort((a, b) => b.score.compareTo(a.score));

    // Pagination
    final paginatedHits = hits.skip(query.offset).take(query.limit).toList();

    stopwatch.stop();
    final latencyMs = stopwatch.elapsedMicroseconds / 1000.0;

    final result = KnowledgeSearchResult(
      hits: paginatedHits,
      totalHits: hits.length,
      latencyMs: double.parse(latencyMs.toStringAsFixed(2)),
      isCacheHit: false,
      query: query,
    );

    // Save into query cache & record telemetry
    cache.putQueryResult(query, result);
    analytics.recordSearch(latencyMs, paginatedHits.isNotEmpty);

    return result;
  }

  /// Search by unique Knowledge Object ID.
  Future<KnowledgeSearchResult> searchById(String id) async {
    final query = KnowledgeQueryBuilder()
        .query(id)
        .type(KnowledgeQueryType.exactMatch)
        .build();
    return search(query);
  }

  /// Search by KnowledgeObjectType.
  Future<KnowledgeSearchResult> searchByType(KnowledgeObjectType type) async {
    final query = KnowledgeQueryBuilder()
        .targetObjectType(type)
        .type(KnowledgeQueryType.filteredSearch)
        .filter(KnowledgeFilter(type: type))
        .build();
    return search(query);
  }

  /// Search by Tag.
  Future<KnowledgeSearchResult> searchByTag(String tag) async {
    final query = KnowledgeQueryBuilder()
        .tag(tag)
        .type(KnowledgeQueryType.tagSearch)
        .build();
    return search(query);
  }

  /// Search by Article Number.
  Future<KnowledgeSearchResult> searchByArticle(String articleNumber) async {
    final query = KnowledgeQueryBuilder()
        .query(articleNumber)
        .filter(KnowledgeFilter(article: articleNumber))
        .type(KnowledgeQueryType.filteredSearch)
        .build();
    return search(query);
  }

  /// Search by Case Law Name.
  Future<KnowledgeSearchResult> searchByCase(String caseName) async {
    final query = KnowledgeQueryBuilder()
        .query(caseName)
        .filter(KnowledgeFilter(caseName: caseName))
        .type(KnowledgeQueryType.filteredSearch)
        .build();
    return search(query);
  }

  /// Search by Act / Statute Name.
  Future<KnowledgeSearchResult> searchByAct(String actName) async {
    final query = KnowledgeQueryBuilder()
        .query(actName)
        .filter(KnowledgeFilter(act: actName))
        .type(KnowledgeQueryType.filteredSearch)
        .build();
    return search(query);
  }

  /// Search by Concept.
  Future<KnowledgeSearchResult> searchByConcept(String concept) async {
    final query = KnowledgeQueryBuilder()
        .query(concept)
        .type(KnowledgeQueryType.crossPackageSearch)
        .build();
    return search(query);
  }

  /// Search by Relationship type & optional target ID.
  Future<KnowledgeSearchResult> searchByRelationship(
    RelationshipType type, {
    String? targetId,
  }) async {
    final query = KnowledgeQueryBuilder()
        .relationship(type, targetId: targetId)
        .type(KnowledgeQueryType.relationshipSearch)
        .build();
    return search(query);
  }

  /// Returns auto-complete suggestions.
  List<String> autocomplete(String prefix, {int limit = 10}) {
    final cached = cache.getSuggestions(prefix);
    if (cached != null) return cached;

    final results = autocompleteEngine.autocomplete(prefix, limit: limit);
    cache.putSuggestions(prefix, results);
    return results;
  }

  /// Returns did-you-mean suggestions.
  List<String> suggest(String query) {
    return suggestionEngine.suggest(query);
  }

  /// Triggered after pipeline registration to invalidate query & result caches.
  void onPipelineComplete() {
    cache.invalidateAll();
  }

  Set<KnowledgeObject> _resolveCandidates(KnowledgeQuery query) {
    if (query.queryType == KnowledgeQueryType.exactMatch) {
      final ids = index.searchIds(query.rawQuery);
      return ids
          .map((id) => index.storedObjects[id]!)
          .whereType<KnowledgeObject>()
          .toSet();
    }

    if (query.queryType == KnowledgeQueryType.tagSearch &&
        query.targetTag != null) {
      final ids = index.searchTags(query.targetTag!);
      return ids
          .map((id) => index.storedObjects[id]!)
          .whereType<KnowledgeObject>()
          .toSet();
    }

    if (query.queryType == KnowledgeQueryType.relationshipSearch &&
        query.relationshipType != null) {
      final ids = index.searchRelationships(
        query.relationshipType!,
        targetId: query.relationshipTargetId,
      );
      return ids
          .map((id) => index.storedObjects[id]!)
          .whereType<KnowledgeObject>()
          .toSet();
    }

    // Default: evaluate all indexed objects
    return index.storedObjects.values.toSet();
  }
}
