import '../models/learning_content_models.dart';
import '../repository/learning_content_repository.dart';

/// Clean Architecture Use Case for fetching a specific [LearningContent] item by ID.
class GetLearningContentUseCase {
  final LearningContentRepository _repository;

  const GetLearningContentUseCase(this._repository);

  /// Executes content retrieval by [contentId].
  Future<LearningContent?> execute(String contentId) {
    return _repository.getContentById(contentId);
  }
}
