import 'package:flutter_test/flutter_test.dart';
import 'package:titan_academy/titan_academy.dart';

void main() {
  group('AcademyRepositoryImpl Unit Tests', () {
    late AcademyRepository repository;

    setUp(() {
      repository = AcademyRepositoryImpl();
    });

    test('getCourses returns seeded catalog', () async {
      final courses = await repository.getCourses();
      expect(courses.length, greaterThanOrEqualTo(3));
    });

    test('getCourses filters by category/subject', () async {
      final polityCourses = await repository.getCourses(category: 'Polity');
      expect(polityCourses.every((c) => c.subject == 'Polity'), isTrue);
    });

    test('getCourses filters by searchQuery', () async {
      final searched = await repository.getCourses(searchQuery: 'Freedom');
      expect(searched.length, equals(1));
      expect(searched.first.subject, equals('History'));
    });

    test('getCourseById returns target course', () async {
      final course = await repository.getCourseById('course_polity_101');
      expect(course, isNotNull);
      expect(course!.title, contains('Indian Polity'));
    });

    test('enrollInCourse creates active enrollment', () async {
      final enrollment = await repository.enrollInCourse(
        userId: 'test_user',
        courseId: 'course_polity_101',
      );
      expect(enrollment.userId, equals('test_user'));
      expect(enrollment.courseId, equals('course_polity_101'));
      expect(enrollment.status, equals('active'));
    });

    test('updateProgress updates completed lessons and percentage', () async {
      await repository.enrollInCourse(
        userId: 'test_user',
        courseId: 'course_polity_101',
      );

      final progress = await repository.updateProgress(
        userId: 'test_user',
        courseId: 'course_polity_101',
        lessonId: 'les_p1_1_1',
        isCompleted: true,
        timeSpentMinutes: 30,
      );

      expect(progress.completedLessonIds, contains('les_p1_1_1'));
      expect(progress.overallProgressPercentage, greaterThan(0.0));
      expect(progress.timeSpentMinutes, equals(30));
    });

    test('getContinueLearningLesson retrieves next uncompleted lesson',
        () async {
      await repository.enrollInCourse(
        userId: 'test_user',
        courseId: 'course_polity_101',
      );

      final nextLesson = await repository.getContinueLearningLesson(
        userId: 'test_user',
        courseId: 'course_polity_101',
      );

      expect(nextLesson, isNotNull);
      expect(nextLesson!.id, equals('les_p1_1_1'));
    });
  });
}
