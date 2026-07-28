import '../models/learning_content_models.dart';
import '../repository/learning_content_repository.dart';

/// Clean Architecture Use Case for updating progress on a [LearningContent] item.
class UpdateContentProgressUseCase {
  final LearningContentRepository _repository;

  const UpdateContentProgressUseCase(this._repository);

  /// Updates last position, completion percentage, and time spent for [userId] on [contentId].
  Future<ContentProgress> execute({
    required String userId,
    required String contentId,
    required int lastPositionSeconds,
    required double completionPercentage,
    required int timeSpentSeconds,
  }) {
    return _repository.updateProgress(
      userId: userId,
      contentId: contentId,
      lastPositionSeconds: lastPositionSeconds,
      completionPercentage: completionPercentage,
      timeSpentSeconds: timeSpentSeconds,
    );
  }
}
