import '../models/knowledge_graph.dart';
import '../repository/knowledge_graph_repository.dart';

/// Clean Architecture Use Case for fetching and initializing Knowledge Graph snapshots.
class BuildKnowledgeGraphUseCase {
  final KnowledgeGraphRepository _repository;

  const BuildKnowledgeGraphUseCase(this._repository);

  /// Retrieves or constructs the active Knowledge Graph.
  Future<KnowledgeGraph> execute() {
    return _repository.getGraph();
  }
}
