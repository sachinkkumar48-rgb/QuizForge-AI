import 'dart:collection';

import '../models/knowledge_edge.dart';
import '../models/knowledge_graph.dart';
import '../models/knowledge_node.dart';
import '../models/knowledge_path.dart';

/// Pure domain Knowledge Graph Engine executing graph algorithms:
/// - BFS (Breadth-First Search)
/// - Neighbor Discovery
/// - Shortest Learning Path (Dijkstra / Weighted BFS)
/// - Related Topic Ranking
class KnowledgeGraphEngine {
  const KnowledgeGraphEngine();

  /// Performs Breadth-First Search (BFS) traversal starting from [startNodeId] up to [maxDepth].
  List<KnowledgeNode> bfsTraversal({
    required KnowledgeGraph graph,
    required String startNodeId,
    int maxDepth = 3,
  }) {
    final startNode = graph.getNode(startNodeId);
    if (startNode == null) return const [];

    final visited = <String>{startNodeId};
    final queue = Queue<_BfsStep>()..add(_BfsStep(node: startNode, depth: 0));
    final result = <KnowledgeNode>[];

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      result.add(current.node);

      if (current.depth >= maxDepth) continue;

      final outgoing = graph.getOutgoingEdges(current.node.id);
      for (final edge in outgoing) {
        if (!visited.contains(edge.targetId)) {
          final targetNode = graph.getNode(edge.targetId);
          if (targetNode != null) {
            visited.add(edge.targetId);
            queue.add(_BfsStep(node: targetNode, depth: current.depth + 1));
          }
        }
      }
    }

    return result;
  }

  /// Discovers direct neighbor nodes for a given [nodeId], optional filtering by edge type or node type.
  List<KnowledgeNode> discoverNeighbors({
    required KnowledgeGraph graph,
    required String nodeId,
    KnowledgeRelationType? relationType,
    KnowledgeNodeType? targetNodeType,
    bool includeIncoming = true,
  }) {
    final node = graph.getNode(nodeId);
    if (node == null) return const [];

    final neighborIds = <String>{};
    final outgoing = graph.getOutgoingEdges(nodeId);
    for (final edge in outgoing) {
      if (relationType == null || edge.relationType == relationType) {
        neighborIds.add(edge.targetId);
      }
    }

    if (includeIncoming) {
      final incoming = graph.getIncomingEdges(nodeId);
      for (final edge in incoming) {
        if (relationType == null || edge.relationType == relationType) {
          neighborIds.add(edge.sourceId);
        }
      }
    }

    final neighbors = <KnowledgeNode>[];
    for (final id in neighborIds) {
      final n = graph.getNode(id);
      if (n != null) {
        if (targetNodeType == null || n.type == targetNodeType) {
          neighbors.add(n);
        }
      }
    }

    return neighbors;
  }

  /// Computes the shortest learning path between [startNodeId] and [targetNodeId] using Dijkstra's algorithm.
  KnowledgePath? findShortestLearningPath({
    required KnowledgeGraph graph,
    required String startNodeId,
    required String targetNodeId,
  }) {
    final startNode = graph.getNode(startNodeId);
    final targetNode = graph.getNode(targetNodeId);

    if (startNode == null || targetNode == null) return null;
    if (startNodeId == targetNodeId) {
      return KnowledgePath(
        nodes: [startNode],
        edges: const [],
        totalDistance: 0.0,
      );
    }

    final distances = <String, double>{startNodeId: 0.0};
    final previousNodes = <String, String>{};
    final previousEdges = <String, KnowledgeEdge>{};
    final unvisited = <String>{...graph.nodes.keys};

    while (unvisited.isNotEmpty) {
      // Pick unvisited node with smallest distance
      String? current;
      var smallestDist = double.infinity;

      for (final nodeId in unvisited) {
        final d = distances[nodeId] ?? double.infinity;
        if (d < smallestDist) {
          smallestDist = d;
          current = nodeId;
        }
      }

      if (current == null || smallestDist == double.infinity) break;
      if (current == targetNodeId) break; // Reached destination

      unvisited.remove(current);

      final outgoing = graph.getOutgoingEdges(current);
      for (final edge in outgoing) {
        if (!unvisited.contains(edge.targetId)) continue;

        // Cost is inverse of edge weight + prerequisite penalty
        final edgeCost = (1.0 / (edge.weight > 0 ? edge.weight : 0.1));
        final newDist = distances[current]! + edgeCost;

        if (newDist < (distances[edge.targetId] ?? double.infinity)) {
          distances[edge.targetId] = newDist;
          previousNodes[edge.targetId] = current;
          previousEdges[edge.targetId] = edge;
        }
      }
    }

    if (!previousNodes.containsKey(targetNodeId)) {
      return null; // No path exists
    }

    // Reconstruct path backward
    final pathNodes = <KnowledgeNode>[];
    final pathEdges = <KnowledgeEdge>[];
    var currentId = targetNodeId;

    while (currentId != startNodeId) {
      final node = graph.getNode(currentId)!;
      pathNodes.add(node);

      final edge = previousEdges[currentId]!;
      pathEdges.add(edge);

      currentId = previousNodes[currentId]!;
    }

    pathNodes.add(startNode);

    return KnowledgePath(
      nodes: pathNodes.reversed.toList(),
      edges: pathEdges.reversed.toList(),
      totalDistance: distances[targetNodeId] ?? 0.0,
    );
  }

  /// Ranks related topics by graph proximity, edge weights, and mastery weight scores.
  List<KnowledgeNode> rankRelatedTopics({
    required KnowledgeGraph graph,
    required String rootNodeId,
    int topN = 5,
  }) {
    final rootNode = graph.getNode(rootNodeId);
    if (rootNode == null) return const [];

    final scores = <String, double>{};
    final visitedNodes =
        bfsTraversal(graph: graph, startNodeId: rootNodeId, maxDepth: 2);

    for (final node in visitedNodes) {
      if (node.id == rootNodeId) continue;

      // Base score inverse to distance, weighted by mastery gap (1 - masteryWeight)
      final shortestPath = findShortestLearningPath(
        graph: graph,
        startNodeId: rootNodeId,
        targetNodeId: node.id,
      );

      final distance = shortestPath?.totalDistance ?? 10.0;
      final proximityScore = 1.0 / (1.0 + distance);
      final gapScore = (1.0 - node.masteryWeight);

      final totalScore = (proximityScore * 0.6) + (gapScore * 0.4);
      scores[node.id] = totalScore;
    }

    final sortedNodes = visitedNodes.where((n) => n.id != rootNodeId).toList()
      ..sort((a, b) {
        final scoreA = scores[a.id] ?? 0.0;
        final scoreB = scores[b.id] ?? 0.0;
        return scoreB.compareTo(scoreA); // Descending score
      });

    return sortedNodes.take(topN).toList();
  }
}

class _BfsStep {
  final KnowledgeNode node;
  final int depth;

  const _BfsStep({required this.node, required this.depth});
}
