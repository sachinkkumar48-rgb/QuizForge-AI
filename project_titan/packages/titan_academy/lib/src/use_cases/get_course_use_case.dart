import '../models/academy_models.dart';
import '../repository/academy_repository.dart';

/// Clean Architecture Use Case for fetching detailed course information and user enrollment.
class GetCourseUseCase {
  final AcademyRepository _repository;

  const GetCourseUseCase(this._repository);

  /// Retrieves a course by [courseId] and optionally attaches active [userId] enrollment.
  Future<({Course? course, Enrollment? enrollment})> execute({
    required String courseId,
    String? userId,
  }) async {
    final course = await _repository.getCourseById(courseId);
    Enrollment? enrollment;
    if (course != null && userId != null) {
      enrollment =
          await _repository.getEnrollment(userId: userId, courseId: courseId);
    }
    return (course: course, enrollment: enrollment);
  }
}
