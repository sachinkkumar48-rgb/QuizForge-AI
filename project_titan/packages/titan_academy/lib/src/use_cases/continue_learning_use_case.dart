import '../models/academy_models.dart';
import '../repository/academy_repository.dart';

/// Clean Architecture Use Case for fetching the next uncompleted lesson to continue learning.
class ContinueLearningUseCase {
  final AcademyRepository _repository;

  const ContinueLearningUseCase(this._repository);

  /// Retrieves next lesson to resume for [userId], optionally for a specific [courseId].
  Future<({Course? course, Lesson? lesson, Enrollment? enrollment})> execute({
    required String userId,
    String? courseId,
  }) async {
    final userEnrollments = await _repository.getUserEnrollments(userId);
    if (userEnrollments.isEmpty) {
      return (course: null, lesson: null, enrollment: null);
    }

    Enrollment targetEnrollment;
    if (courseId != null) {
      targetEnrollment = userEnrollments.firstWhere(
        (e) => e.courseId == courseId,
        orElse: () => userEnrollments.first,
      );
    } else {
      userEnrollments.sort((a, b) =>
          b.progress.lastAccessedAt.compareTo(a.progress.lastAccessedAt));
      targetEnrollment = userEnrollments.first;
    }

    final course = await _repository.getCourseById(targetEnrollment.courseId);
    final lesson = await _repository.getContinueLearningLesson(
        userId: userId, courseId: targetEnrollment.courseId);

    return (course: course, lesson: lesson, enrollment: targetEnrollment);
  }
}
