import '../entities/knowledge_relationship.dart';
import '../repositories/relationship_repository.dart';
import '../value_objects/relationship_type.dart';
import 'relationship_query_service.dart';
import 'traversal_result.dart';

/// Domain service executing graph traversal algorithms, neighbor lookups, and cycle-safe
/// queries over [KnowledgeRelationship] edges in the TITAN Knowledge Intelligence Engine.
class KnowledgeTraversalService {
  final RelationshipQueryService _queryService;

  /// Constructs a [KnowledgeTraversalService] wrapping [queryService].
  const KnowledgeTraversalService(this._queryService);

  /// Helper factory constructing [KnowledgeTraversalService] directly from a [RelationshipRepository].
  factory KnowledgeTraversalService.fromRepository(
      RelationshipRepository repository) {
    return KnowledgeTraversalService(RelationshipQueryService(repository));
  }

  /// Retrieves a sorted, unique list of neighbor node IDs connected to [nodeId].
  ///
  /// If [type] is provided, only relationships matching [type] are included.
  /// If [outgoingOnly] is true, only target nodes of outgoing edges are returned.
  Future<List<String>> getNeighbors(
    String nodeId, {
    RelationshipType? type,
    bool outgoingOnly = false,
  }) async {
    if (nodeId.trim().isEmpty) return const [];

    final List<KnowledgeRelationship> edges;
    if (type != null) {
      edges = await _queryService.getRelationshipsByType(nodeId, type,
          outgoingOnly: outgoingOnly);
    } else if (outgoingOnly) {
      edges = await _queryService.getOutgoingRelationships(nodeId);
    } else {
      edges = await _queryService.getAllRelationships(nodeId);
    }

    final neighborIds = <String>{};
    for (final edge in edges) {
      if (edge.sourceKnowledgeId == nodeId) {
        neighborIds.add(edge.targetKnowledgeId);
      } else if (!outgoingOnly && edge.targetKnowledgeId == nodeId) {
        neighborIds.add(edge.sourceKnowledgeId);
      }
    }

    neighborIds.remove(nodeId);
    final result = neighborIds.toList()..sort();
    return result;
  }

  /// Performs a deterministic Breadth-First Search (BFS) graph traversal starting from [startNodeId].
  ///
  /// Features:
  /// - **Configurable Depth**: Traverses up to [maxDepth] steps.
  /// - **Deterministic Ordering**: Sorts candidate edges at each node by relationship ID and target ID.
  /// - **Cycle Detection**: Detects and avoids visiting previously traversed nodes, preventing infinite loops.
  Future<TraversalResult> traverse(
    String startNodeId, {
    int maxDepth = 1,
    RelationshipType? typeFilter,
    bool outgoingOnly = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cleanStartId = startNodeId.trim();

    if (cleanStartId.isEmpty || maxDepth < 0) {
      return TraversalResult(
        visitedNodes: const [],
        traversedEdges: const [],
        traversalDepth: 0,
        statistics: {
          'totalVisitedNodes': 0,
          'totalTraversedEdges': 0,
          'maxDepthReached': 0,
          'executionTimeMs': stopwatch.elapsedMilliseconds,
          'cyclesDetected': 0,
        },
      );
    }

    final visitedNodes = <String>[cleanStartId];
    final visitedSet = <String>{cleanStartId};
    final traversedEdges = <KnowledgeRelationship>[];
    final traversedEdgeIds = <String>{};
    int cyclesDetected = 0;
    int currentDepthReached = 0;

    List<String> currentLevel = [cleanStartId];

    for (int depth = 1; depth <= maxDepth; depth++) {
      if (currentLevel.isEmpty) break;

      final nextLevel = <String>[];

      for (final currentNodeId in currentLevel) {
        final List<KnowledgeRelationship> edges;
        if (typeFilter != null) {
          edges = await _queryService.getRelationshipsByType(
            currentNodeId,
            typeFilter,
            outgoingOnly: outgoingOnly,
          );
        } else if (outgoingOnly) {
          edges = await _queryService.getOutgoingRelationships(currentNodeId);
        } else {
          edges = await _queryService.getAllRelationships(currentNodeId);
        }

        // Sort edges deterministically by relationshipId then targetKnowledgeId
        final sortedEdges = List<KnowledgeRelationship>.from(edges)
          ..sort((a, b) {
            final cmpId = a.relationshipId.compareTo(b.relationshipId);
            if (cmpId != 0) return cmpId;
            return a.targetKnowledgeId.compareTo(b.targetKnowledgeId);
          });

        for (final edge in sortedEdges) {
          final String neighborId = (edge.sourceKnowledgeId == currentNodeId)
              ? edge.targetKnowledgeId
              : edge.sourceKnowledgeId;

          if (neighborId == currentNodeId) continue;

          if (visitedSet.contains(neighborId)) {
            cyclesDetected++;
            continue;
          }

          visitedSet.add(neighborId);
          visitedNodes.add(neighborId);

          if (!traversedEdgeIds.contains(edge.relationshipId)) {
            traversedEdgeIds.add(edge.relationshipId);
            traversedEdges.add(edge);
          }

          nextLevel.add(neighborId);
        }
      }

      if (nextLevel.isNotEmpty) {
        currentDepthReached = depth;
      }
      currentLevel = nextLevel;
    }

    stopwatch.stop();

    return TraversalResult(
      visitedNodes: visitedNodes,
      traversedEdges: traversedEdges,
      traversalDepth: currentDepthReached,
      statistics: {
        'totalVisitedNodes': visitedNodes.length,
        'totalTraversedEdges': traversedEdges.length,
        'maxDepthReached': currentDepthReached,
        'executionTimeMs': stopwatch.elapsedMilliseconds,
        'cyclesDetected': cyclesDetected,
      },
    );
  }
}
