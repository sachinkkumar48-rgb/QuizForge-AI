import '../models/learning_content_models.dart';
import '../repository/learning_content_repository.dart';

/// Clean Architecture Use Case for retrieving personalized content recommendations for a user.
class GetRecommendedContentUseCase {
  final LearningContentRepository _repository;

  const GetRecommendedContentUseCase(this._repository);

  /// Retrieves recommended content items filtered by target [subject] or weak areas.
  Future<List<LearningContent>> execute({
    required String userId,
    String? subject,
  }) async {
    // In actual execution, queries repository or recommendation engine
    final chapterItems = await _repository.getChapterContents('chap_p1_1');
    if (subject != null && subject.isNotEmpty) {
      return chapterItems
          .where(
              (c) => c.metadata.subject.toLowerCase() == subject.toLowerCase())
          .toList();
    }
    return chapterItems;
  }
}
