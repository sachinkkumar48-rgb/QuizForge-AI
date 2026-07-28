import '../models/academy_models.dart';

/// Clean Architecture abstract repository interface for TITAN Academy course management.
abstract class AcademyRepository {
  /// Retrieves list of courses, optionally filtered by subject/category, search query, or difficulty level.
  Future<List<Course>> getCourses({
    String? category,
    String? searchQuery,
    String? level,
  });

  /// Retrieves a specific course by its unique ID.
  Future<Course?> getCourseById(String id);

  /// Enrolls a user in a course and initializes their learning progress.
  Future<Enrollment> enrollInCourse({
    required String userId,
    required String courseId,
  });

  /// Updates lesson completion and progress for an enrolled course.
  Future<LearningProgress> updateProgress({
    required String userId,
    required String courseId,
    required String lessonId,
    bool isCompleted = true,
    int timeSpentMinutes = 0,
  });

  /// Retrieves user's enrollment for a specific course if present.
  Future<Enrollment?> getEnrollment({
    required String userId,
    required String courseId,
  });

  /// Retrieves all active and completed enrollments for a user.
  Future<List<Enrollment>> getUserEnrollments(String userId);

  /// Retrieves the next uncompleted lesson for the active course to continue learning.
  Future<Lesson?> getContinueLearningLesson({
    required String userId,
    String? courseId,
  });
}
