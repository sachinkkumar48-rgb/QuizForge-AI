import '../entities/knowledge_object.dart';
import '../repositories/knowledge_repository.dart';
import '../services/knowledge_traversal_service.dart';
import '../services/relationship_query_service.dart';
import '../value_objects/relationship_type.dart';
import 'knowledge_search_query.dart';
import 'knowledge_search_result.dart';
import 'search_ranking_strategy.dart';

/// Storage-independent, deterministic domain search service orchestrating search,
/// multi-attribute filtering, graph proximity evaluation, and ranking across Project TITAN.
class KnowledgeSearchService {
  final KnowledgeRepository _knowledgeRepository;
  final RelationshipQueryService _queryService;
  final KnowledgeTraversalService _traversalService;
  final SearchRankingStrategy _rankingStrategy;

  /// Constructs a [KnowledgeSearchService].
  const KnowledgeSearchService({
    required KnowledgeRepository knowledgeRepository,
    required RelationshipQueryService queryService,
    required KnowledgeTraversalService traversalService,
    SearchRankingStrategy rankingStrategy =
        const DefaultSearchRankingStrategy(),
  })  : _knowledgeRepository = knowledgeRepository,
        _queryService = queryService,
        _traversalService = traversalService,
        _rankingStrategy = rankingStrategy;

  /// Executes a unified search against [KnowledgeRepository] using the provided [query].
  Future<KnowledgeSearchResult> search(KnowledgeSearchQuery query) async {
    final stopwatch = Stopwatch()..start();

    // 1. Fetch raw candidate objects from KnowledgeRepository
    final List<KnowledgeObject> candidates =
        await _knowledgeRepository.search(query.freeText ?? '');

    // 2. Evaluate Graph Relationship Proximity if relationshipTypes filter is present
    final Set<String> connectedGraphNodeIds = <String>{};
    if (query.relationshipTypes.isNotEmpty &&
        query.freeText != null &&
        query.freeText!.isNotEmpty) {
      for (final relType in query.relationshipTypes) {
        final rels = await _queryService.getRelationshipsByType(
          query.freeText!,
          relType,
          outgoingOnly: false,
        );
        for (final r in rels) {
          connectedGraphNodeIds.add(r.sourceKnowledgeId);
          connectedGraphNodeIds.add(r.targetKnowledgeId);
        }
      }
    }

    // 3. Apply Multi-field filtering
    final filtered = candidates.where((obj) {
      // KnowledgeType filter
      if (query.knowledgeTypes.isNotEmpty &&
          !query.knowledgeTypes.contains(obj.type)) {
        return false;
      }

      // Language filter
      if (query.language != null &&
          query.language!.isNotEmpty &&
          obj.language.toLowerCase() != query.language!.toLowerCase()) {
        return false;
      }

      // Subjects filter
      if (query.subjects.isNotEmpty) {
        final hasSubject = query.subjects.any((qs) =>
            obj.subjects.any((os) => os.toLowerCase() == qs.toLowerCase()));
        if (!hasSubject) return false;
      }

      // Topics filter
      if (query.topics.isNotEmpty) {
        final hasTopic = query.topics.any((qt) =>
            obj.topics.any((ot) => ot.toLowerCase() == qt.toLowerCase()));
        if (!hasTopic) return false;
      }

      // Tags filter (matches keywords or topics)
      if (query.tags.isNotEmpty) {
        final hasTag = query.tags.any((tag) {
          final tLower = tag.toLowerCase();
          return obj.keywords.any((k) => k.toLowerCase() == tLower) ||
              obj.topics.any((top) => top.toLowerCase() == tLower);
        });
        if (!hasTag) return false;
      }

      return true;
    }).toList();

    // 4. Rank candidates deterministically
    final ranked = _rankingStrategy.rank(
      filtered,
      query,
      connectedGraphNodeIds:
          connectedGraphNodeIds.isNotEmpty ? connectedGraphNodeIds : null,
    );

    // 5. Apply limit/offset pagination
    final totalCount = ranked.length;
    final paginated = ranked.skip(query.offset).take(query.limit).toList();

    stopwatch.stop();

    return KnowledgeSearchResult(
      matchedObjects: paginated,
      totalCount: totalCount,
      statistics: {
        'executionTimeMs': stopwatch.elapsedMilliseconds,
        'totalCandidateCount': candidates.length,
        'filteredCount': filtered.length,
        'returnedCount': paginated.length,
        'limit': query.limit,
        'offset': query.offset,
      },
      appliedFilters: query.toMap(),
    );
  }

  /// Convenience shortcut searching entities matching a specific [topic].
  Future<KnowledgeSearchResult> searchByTopic(
    String topic, {
    int limit = 20,
    int offset = 0,
  }) async {
    final query = KnowledgeSearchQuery(
      topics: [topic],
      limit: limit,
      offset: offset,
    );
    return await search(query);
  }

  /// Convenience shortcut searching entities matching a specific [subject].
  Future<KnowledgeSearchResult> searchBySubject(
    String subject, {
    int limit = 20,
    int offset = 0,
  }) async {
    final query = KnowledgeSearchQuery(
      subjects: [subject],
      limit: limit,
      offset: offset,
    );
    return await search(query);
  }

  /// Convenience shortcut searching entities matching a specific [tag].
  Future<KnowledgeSearchResult> searchByTag(
    String tag, {
    int limit = 20,
    int offset = 0,
  }) async {
    final query = KnowledgeSearchQuery(
      tags: [tag],
      limit: limit,
      offset: offset,
    );
    return await search(query);
  }

  /// Graph-assisted search retrieving related entities connected to [nodeId].
  Future<KnowledgeSearchResult> searchRelated(
    String nodeId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final stopwatch = Stopwatch()..start();
    final neighborIds = await _traversalService.getNeighbors(nodeId);

    final objects = <KnowledgeObject>[];
    for (final id in neighborIds) {
      final obj = await _knowledgeRepository.findById(id);
      if (obj != null) {
        objects.add(obj);
      }
    }

    final query = KnowledgeSearchQuery(limit: limit, offset: offset);
    final ranked = _rankingStrategy.rank(
      objects,
      query,
      connectedGraphNodeIds: neighborIds.toSet(),
    );

    final paginated = ranked.skip(offset).take(limit).toList();
    stopwatch.stop();

    return KnowledgeSearchResult(
      matchedObjects: paginated,
      totalCount: ranked.length,
      statistics: {
        'executionTimeMs': stopwatch.elapsedMilliseconds,
        'returnedCount': paginated.length,
        'searchType': 'searchRelated',
        'targetNodeId': nodeId,
      },
      appliedFilters: {'nodeId': nodeId, 'searchType': 'searchRelated'},
    );
  }

  /// Graph-assisted search retrieving prerequisite entities for [nodeId].
  Future<KnowledgeSearchResult> searchPrerequisites(
    String nodeId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final stopwatch = Stopwatch()..start();
    final prereqRels = await _queryService.getRelationshipsByType(
      nodeId,
      RelationshipType.prerequisiteOf,
      outgoingOnly: false,
    );

    final prereqIds = <String>{};
    for (final rel in prereqRels) {
      final prereqId = (rel.targetKnowledgeId == nodeId)
          ? rel.sourceKnowledgeId
          : rel.targetKnowledgeId;
      if (prereqId != nodeId) {
        prereqIds.add(prereqId);
      }
    }

    final objects = <KnowledgeObject>[];
    for (final id in prereqIds) {
      final obj = await _knowledgeRepository.findById(id);
      if (obj != null) {
        objects.add(obj);
      }
    }

    final query = KnowledgeSearchQuery(limit: limit, offset: offset);
    final ranked = _rankingStrategy.rank(
      objects,
      query,
      connectedGraphNodeIds: prereqIds,
    );

    final paginated = ranked.skip(offset).take(limit).toList();
    stopwatch.stop();

    return KnowledgeSearchResult(
      matchedObjects: paginated,
      totalCount: ranked.length,
      statistics: {
        'executionTimeMs': stopwatch.elapsedMilliseconds,
        'returnedCount': paginated.length,
        'searchType': 'searchPrerequisites',
        'targetNodeId': nodeId,
      },
      appliedFilters: {'nodeId': nodeId, 'searchType': 'searchPrerequisites'},
    );
  }

  /// Graph-assisted search retrieving next topic entities following [nodeId].
  Future<KnowledgeSearchResult> searchNextTopics(
    String nodeId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final stopwatch = Stopwatch()..start();
    final outgoing = await _queryService.getOutgoingRelationships(nodeId);

    final nextTopicIds = <String>{};
    for (final rel in outgoing) {
      if (rel.targetKnowledgeId != nodeId) {
        nextTopicIds.add(rel.targetKnowledgeId);
      }
    }

    final objects = <KnowledgeObject>[];
    for (final id in nextTopicIds) {
      final obj = await _knowledgeRepository.findById(id);
      if (obj != null) {
        objects.add(obj);
      }
    }

    final query = KnowledgeSearchQuery(limit: limit, offset: offset);
    final ranked = _rankingStrategy.rank(
      objects,
      query,
      connectedGraphNodeIds: nextTopicIds,
    );

    final paginated = ranked.skip(offset).take(limit).toList();
    stopwatch.stop();

    return KnowledgeSearchResult(
      matchedObjects: paginated,
      totalCount: ranked.length,
      statistics: {
        'executionTimeMs': stopwatch.elapsedMilliseconds,
        'returnedCount': paginated.length,
        'searchType': 'searchNextTopics',
        'targetNodeId': nodeId,
      },
      appliedFilters: {'nodeId': nodeId, 'searchType': 'searchNextTopics'},
    );
  }
}
