import '../models/knowledge_edge.dart';
import '../models/knowledge_graph.dart';
import '../models/knowledge_node.dart';
import '../models/knowledge_path.dart';

/// Abstract repository interface for Knowledge Graph operations.
abstract class KnowledgeGraphRepository {
  /// Builds or retrieves the active Knowledge Graph snapshot.
  Future<KnowledgeGraph> getGraph();

  /// Retrieves a specific node by its unique ID.
  Future<KnowledgeNode?> getNode(String nodeId);

  /// Traverses graph starting from [startNodeId] using BFS.
  Future<List<KnowledgeNode>> traverseBfs(String startNodeId,
      {int maxDepth = 3});

  /// Finds related topic nodes for a root node.
  Future<List<KnowledgeNode>> findRelatedTopics(String rootNodeId,
      {int topN = 5});

  /// Computes optimal shortest learning path from source node to target node.
  Future<KnowledgePath?> getLearningPath(
      String startNodeId, String targetNodeId);

  /// Adds a new node to the active graph.
  Future<KnowledgeGraph> addNode(KnowledgeNode node);

  /// Adds a new edge to the active graph.
  Future<KnowledgeGraph> addEdge(KnowledgeEdge edge);
}
