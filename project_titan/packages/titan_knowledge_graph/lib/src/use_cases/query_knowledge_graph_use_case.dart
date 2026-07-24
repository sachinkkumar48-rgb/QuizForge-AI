import '../models/knowledge_node.dart';
import '../repository/knowledge_graph_repository.dart';

/// Clean Architecture Use Case for querying nodes and BFS traversals.
class QueryKnowledgeGraphUseCase {
  final KnowledgeGraphRepository _repository;

  const QueryKnowledgeGraphUseCase(this._repository);

  /// Look up a node by its ID.
  Future<KnowledgeNode?> getNode(String nodeId) {
    return _repository.getNode(nodeId);
  }

  /// Perform BFS graph traversal starting at [startNodeId].
  Future<List<KnowledgeNode>> traverseBfs(String startNodeId,
      {int maxDepth = 3}) {
    return _repository.traverseBfs(startNodeId, maxDepth: maxDepth);
  }
}
