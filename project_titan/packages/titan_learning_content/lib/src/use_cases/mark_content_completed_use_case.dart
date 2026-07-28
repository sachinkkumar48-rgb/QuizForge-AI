import '../models/learning_content_models.dart';
import '../repository/learning_content_repository.dart';

/// Clean Architecture Use Case for marking a [LearningContent] item as completed.
class MarkContentCompletedUseCase {
  final LearningContentRepository _repository;

  const MarkContentCompletedUseCase(this._repository);

  /// Marks [contentId] as completed for [userId] with optional score and feedback.
  Future<ContentCompletion> execute({
    required String userId,
    required String contentId,
    double? score,
    String? feedback,
  }) {
    return _repository.markCompleted(
      userId: userId,
      contentId: contentId,
      score: score,
      feedback: feedback,
    );
  }
}
