import 'package:titan_academy/titan_academy.dart';
import '../models/kmp_course_models.dart';

abstract class CourseManagementRepository {
  Future<List<Course>> getAdminCourses({ExamCategory? category});
  Future<Course?> getCourseById(String id);
  Future<Course> createCourse(Course course, KmpCourseMetadata metadata);
  Future<Course> updateCourse(Course course, KmpCourseMetadata metadata);
  Future<void> deleteCourse(String id);

  Future<List<KmpLearningPath>> getLearningPaths({ExamCategory? category});
  Future<KmpLearningPath> createLearningPath(KmpLearningPath path);
}
