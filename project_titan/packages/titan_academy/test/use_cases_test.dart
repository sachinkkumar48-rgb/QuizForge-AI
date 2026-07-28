import 'package:flutter_test/flutter_test.dart';
import 'package:titan_academy/titan_academy.dart';

void main() {
  group('Use Cases Unit Tests', () {
    late AcademyRepository repository;
    late BrowseCoursesUseCase browseCoursesUseCase;
    late GetCourseUseCase getCourseUseCase;
    late EnrollCourseUseCase enrollCourseUseCase;
    late UpdateProgressUseCase updateProgressUseCase;
    late ContinueLearningUseCase continueLearningUseCase;

    setUp(() {
      repository = AcademyRepositoryImpl();
      browseCoursesUseCase = BrowseCoursesUseCase(repository);
      getCourseUseCase = GetCourseUseCase(repository);
      enrollCourseUseCase = EnrollCourseUseCase(repository);
      updateProgressUseCase = UpdateProgressUseCase(repository);
      continueLearningUseCase = ContinueLearningUseCase(repository);
    });

    test('BrowseCoursesUseCase executes query filter', () async {
      final results = await browseCoursesUseCase.execute(category: 'Economy');
      expect(results.length, equals(1));
      expect(results.first.subject, equals('Economy'));
    });

    test('GetCourseUseCase returns course and user enrollment', () async {
      await enrollCourseUseCase.execute(
          userId: 'u1', courseId: 'course_polity_101');
      final res = await getCourseUseCase.execute(
          courseId: 'course_polity_101', userId: 'u1');
      expect(res.course, isNotNull);
      expect(res.enrollment, isNotNull);
      expect(res.enrollment!.userId, equals('u1'));
    });

    test('EnrollCourseUseCase creates new enrollment', () async {
      final enrollment = await enrollCourseUseCase.execute(
        userId: 'u2',
        courseId: 'course_history_101',
      );
      expect(enrollment.courseId, equals('course_history_101'));
      expect(enrollment.userId, equals('u2'));
    });

    test('UpdateProgressUseCase updates lesson completion state', () async {
      await enrollCourseUseCase.execute(
          userId: 'u3', courseId: 'course_polity_101');
      final updatedProgress = await updateProgressUseCase.execute(
        userId: 'u3',
        courseId: 'course_polity_101',
        lessonId: 'les_p1_1_1',
        isCompleted: true,
        timeSpentMinutes: 25,
      );

      expect(updatedProgress.completedLessonIds, contains('les_p1_1_1'));
      expect(updatedProgress.timeSpentMinutes, equals(25));
    });

    test('ContinueLearningUseCase returns active course and next lesson',
        () async {
      await enrollCourseUseCase.execute(
          userId: 'u4', courseId: 'course_polity_101');
      final res = await continueLearningUseCase.execute(userId: 'u4');
      expect(res.course, isNotNull);
      expect(res.lesson, isNotNull);
      expect(res.enrollment, isNotNull);
    });
  });
}
