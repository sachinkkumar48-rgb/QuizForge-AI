import '../entities/knowledge_object.dart';
import '../entities/knowledge_relationship.dart';
import '../repositories/knowledge_repository.dart';
import '../value_objects/relationship_type.dart';
import 'knowledge_traversal_service.dart';
import 'relationship_query_service.dart';

/// Graph-driven recommendation service interpreting directed [KnowledgeRelationship]
/// graph edges in the TITAN Knowledge Intelligence Engine without external AI dependencies.
class RecommendationService {
  final KnowledgeRepository _knowledgeRepository;
  final RelationshipQueryService _queryService;
  final KnowledgeTraversalService _traversalService;

  /// Constructs a [RecommendationService].
  const RecommendationService({
    required KnowledgeRepository knowledgeRepository,
    required RelationshipQueryService queryService,
    required KnowledgeTraversalService traversalService,
  })  : _knowledgeRepository = knowledgeRepository,
        _queryService = queryService,
        _traversalService = traversalService;

  /// Exposes the underlying [KnowledgeTraversalService].
  KnowledgeTraversalService get traversalService => _traversalService;

  /// Recommends related [KnowledgeObject] entities connected to [nodeId].
  ///
  /// Evaluates connected relationships via graph traversal up to [maxDepth],
  /// sorts them by confidence score descending, resolves entities from [KnowledgeRepository],
  /// and returns up to [limit] results.
  Future<List<KnowledgeObject>> relatedKnowledge(
    String nodeId, {
    int limit = 5,
    int maxDepth = 1,
  }) async {
    final cleanId = nodeId.trim();
    if (cleanId.isEmpty || limit <= 0) return const [];

    final traversal = await _traversalService.traverse(
      cleanId,
      maxDepth: maxDepth,
      outgoingOnly: false,
    );

    if (traversal.traversedEdges.isEmpty) return const [];

    // Sort edges by confidence descending, then by target/source ID
    final sortedEdges =
        List<KnowledgeRelationship>.from(traversal.traversedEdges)
          ..sort((a, b) {
            final cmpConfidence = b.confidence.compareTo(a.confidence);
            if (cmpConfidence != 0) return cmpConfidence;
            return a.relationshipId.compareTo(b.relationshipId);
          });

    final targetIds = <String>[];
    for (final edge in sortedEdges) {
      final String candidateId = (edge.sourceKnowledgeId == cleanId)
          ? edge.targetKnowledgeId
          : edge.sourceKnowledgeId;
      if (candidateId != cleanId && !targetIds.contains(candidateId)) {
        targetIds.add(candidateId);
      }
    }

    final results = <KnowledgeObject>[];
    for (final candidateId in targetIds) {
      if (results.length >= limit) break;
      final obj = await _knowledgeRepository.findById(candidateId);
      if (obj != null) {
        results.add(obj);
      }
    }

    return results;
  }

  /// Recommends prerequisite [KnowledgeObject] entities required before studying [nodeId].
  ///
  /// Finds incoming and outgoing `RelationshipType.prerequisiteOf` relationships,
  /// resolves prerequisite entities, and returns them in logical order.
  Future<List<KnowledgeObject>> prerequisiteKnowledge(String nodeId) async {
    final cleanId = nodeId.trim();
    if (cleanId.isEmpty) return const [];

    final incomingPrereqs = await _queryService.getRelationshipsByType(
      cleanId,
      RelationshipType.prerequisiteOf,
      outgoingOnly: false,
    );

    if (incomingPrereqs.isEmpty) return const [];

    // In prerequisiteOf: "Source entity is a required foundational concept for understanding target entity."
    // So for target = cleanId, source is the prerequisite.
    final prereqIds = <String>[];
    for (final edge in incomingPrereqs) {
      final String prereqId = (edge.targetKnowledgeId == cleanId)
          ? edge.sourceKnowledgeId
          : edge.targetKnowledgeId;
      if (prereqId != cleanId && !prereqIds.contains(prereqId)) {
        prereqIds.add(prereqId);
      }
    }

    final results = <KnowledgeObject>[];
    for (final id in prereqIds) {
      final obj = await _knowledgeRepository.findById(id);
      if (obj != null) {
        results.add(obj);
      }
    }

    return results;
  }

  /// Suggests next logical topic [KnowledgeObject] entities to study after [nodeId].
  ///
  /// Evaluates outgoing `prerequisiteOf` (where [nodeId] is prerequisite for next topics),
  /// `expands`, and `relatedTo` relationships up to [limit] items.
  Future<List<KnowledgeObject>> nextTopics(String nodeId,
      {int limit = 5}) async {
    final cleanId = nodeId.trim();
    if (cleanId.isEmpty || limit <= 0) return const [];

    final outgoingEdges = await _queryService.getOutgoingRelationships(cleanId);
    if (outgoingEdges.isEmpty) return const [];

    // Priority ordering: prerequisiteOf (1), expands (2), relatedTo (3), others (4)
    int getPriority(RelationshipType type) {
      switch (type) {
        case RelationshipType.prerequisiteOf:
          return 1;
        case RelationshipType.expands:
          return 2;
        case RelationshipType.relatedTo:
          return 3;
        default:
          return 4;
      }
    }

    final sortedEdges = List<KnowledgeRelationship>.from(outgoingEdges)
      ..sort((a, b) {
        final prioA = getPriority(a.relationshipType);
        final priob = getPriority(b.relationshipType);
        if (prioA != priob) return prioA.compareTo(priob);

        final cmpConf = b.confidence.compareTo(a.confidence);
        if (cmpConf != 0) return cmpConf;
        return a.targetKnowledgeId.compareTo(b.targetKnowledgeId);
      });

    final nextTopicIds = <String>[];
    for (final edge in sortedEdges) {
      if (edge.targetKnowledgeId != cleanId &&
          !nextTopicIds.contains(edge.targetKnowledgeId)) {
        nextTopicIds.add(edge.targetKnowledgeId);
      }
    }

    final results = <KnowledgeObject>[];
    for (final topicId in nextTopicIds) {
      if (results.length >= limit) break;
      final obj = await _knowledgeRepository.findById(topicId);
      if (obj != null) {
        results.add(obj);
      }
    }

    return results;
  }
}
