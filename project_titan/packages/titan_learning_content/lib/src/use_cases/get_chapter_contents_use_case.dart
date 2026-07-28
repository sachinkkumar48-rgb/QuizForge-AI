import '../models/learning_content_models.dart';
import '../repository/learning_content_repository.dart';

/// Clean Architecture Use Case for fetching all [LearningContent] items in a chapter.
class GetChapterContentsUseCase {
  final LearningContentRepository _repository;

  const GetChapterContentsUseCase(this._repository);

  /// Retrieves list of learning content items assigned to [chapterId].
  Future<List<LearningContent>> execute(String chapterId) {
    return _repository.getChapterContents(chapterId);
  }
}
