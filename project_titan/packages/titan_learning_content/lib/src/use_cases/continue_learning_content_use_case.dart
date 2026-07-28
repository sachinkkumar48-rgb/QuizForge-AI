import '../models/learning_content_models.dart';
import '../repository/learning_content_repository.dart';

/// Clean Architecture Use Case for finding the next active uncompleted content item for a user.
class ContinueLearningContentUseCase {
  final LearningContentRepository _repository;

  const ContinueLearningContentUseCase(this._repository);

  /// Retrieves the next uncompleted content item for [chapterId].
  Future<LearningContent?> execute({
    required String userId,
    required String chapterId,
  }) async {
    final contents = await _repository.getChapterContents(chapterId);
    if (contents.isEmpty) return null;

    for (final content in contents) {
      if (content.progress == null || !content.progress!.isCompleted) {
        return content;
      }
    }

    return contents.first;
  }
}
