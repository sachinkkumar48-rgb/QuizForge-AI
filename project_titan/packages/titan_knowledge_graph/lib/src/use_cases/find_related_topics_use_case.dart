import '../models/knowledge_node.dart';
import '../repository/knowledge_graph_repository.dart';

/// Clean Architecture Use Case for discovering ranked related topics in the Knowledge Graph.
class FindRelatedTopicsUseCase {
  final KnowledgeGraphRepository _repository;

  const FindRelatedTopicsUseCase(this._repository);

  /// Discovers and ranks top N related topic nodes for [rootNodeId].
  Future<List<KnowledgeNode>> execute(String rootNodeId, {int topN = 5}) {
    return _repository.findRelatedTopics(rootNodeId, topN: topN);
  }
}
