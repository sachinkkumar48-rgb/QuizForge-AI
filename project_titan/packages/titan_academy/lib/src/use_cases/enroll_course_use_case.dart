import '../models/academy_models.dart';
import '../repository/academy_repository.dart';

/// Clean Architecture Use Case for enrolling a user in a course.
class EnrollCourseUseCase {
  final AcademyRepository _repository;

  const EnrollCourseUseCase(this._repository);

  /// Enrolls [userId] into [courseId] and initializes learning progress.
  Future<Enrollment> execute({
    required String userId,
    required String courseId,
  }) {
    return _repository.enrollInCourse(userId: userId, courseId: courseId);
  }
}
