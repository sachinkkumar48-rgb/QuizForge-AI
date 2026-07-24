import '../models/knowledge_path.dart';
import '../repository/knowledge_graph_repository.dart';

/// Clean Architecture Use Case for computing shortest learning paths between nodes.
class GetLearningPathUseCase {
  final KnowledgeGraphRepository _repository;

  const GetLearningPathUseCase(this._repository);

  /// Calculates the shortest learning path connecting [startNodeId] to [targetNodeId].
  Future<KnowledgePath?> execute(String startNodeId, String targetNodeId) {
    return _repository.getLearningPath(startNodeId, targetNodeId);
  }
}
