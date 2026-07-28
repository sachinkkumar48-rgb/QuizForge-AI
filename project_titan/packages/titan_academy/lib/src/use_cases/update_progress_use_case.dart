import '../models/academy_models.dart';
import '../repository/academy_repository.dart';

/// Clean Architecture Use Case for updating lesson completion and user progress.
class UpdateProgressUseCase {
  final AcademyRepository _repository;

  const UpdateProgressUseCase(this._repository);

  /// Updates progress for [lessonId] within [courseId] for [userId].
  Future<LearningProgress> execute({
    required String userId,
    required String courseId,
    required String lessonId,
    bool isCompleted = true,
    int timeSpentMinutes = 0,
  }) {
    return _repository.updateProgress(
      userId: userId,
      courseId: courseId,
      lessonId: lessonId,
      isCompleted: isCompleted,
      timeSpentMinutes: timeSpentMinutes,
    );
  }
}
