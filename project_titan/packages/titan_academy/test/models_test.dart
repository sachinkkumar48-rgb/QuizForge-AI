import 'package:flutter_test/flutter_test.dart';
import 'package:titan_academy/titan_academy.dart';

void main() {
  group('Domain Models Unit Tests', () {
    final testInstructor = Instructor(
      id: 'inst_1',
      name: 'Test Instructor',
      title: 'Professor',
      bio: 'Expert Bio',
      avatarUrl: 'assets/inst.png',
      qualifications: const ['Ph.D. Law'],
      rating: 4.9,
      studentCount: 1000,
    );

    final testLesson = const Lesson(
      id: 'les_1',
      chapterId: 'chap_1',
      title: 'Test Lesson',
      description: 'Lesson Desc',
      durationMinutes: 30,
      type: 'video',
      content: 'Lesson Content',
      order: 1,
      topic: 'Polity',
    );

    final testChapter = Chapter(
      id: 'chap_1',
      moduleId: 'mod_1',
      title: 'Test Chapter',
      description: 'Chapter Desc',
      lessons: [testLesson],
      durationMinutes: 30,
    );

    final testModule = Module(
      id: 'mod_1',
      courseId: 'course_1',
      title: 'Test Module',
      description: 'Module Desc',
      chapters: [testChapter],
      durationMinutes: 30,
    );

    final testCourse = Course(
      id: 'course_1',
      title: 'Test Course',
      description: 'Course Desc',
      subject: 'Polity',
      level: 'Intermediate',
      instructor: testInstructor,
      modules: [testModule],
      estimatedHours: 10.0,
      rating: 4.8,
      enrolledCount: 500,
      imageUrl: 'assets/course.png',
      tags: const ['Polity', 'UPSC'],
      knowledgeNodeId: 'node_1',
    );

    final testProgress = LearningProgress(
      courseId: 'course_1',
      userId: 'user_1',
      completedLessonIds: const {'les_1'},
      lastAccessedLessonId: 'les_1',
      overallProgressPercentage: 100.0,
      timeSpentMinutes: 30,
      lastAccessedAt: DateTime(2026, 1, 1),
      isCompleted: true,
    );

    final testEnrollment = Enrollment(
      id: 'enr_1',
      userId: 'user_1',
      courseId: 'course_1',
      enrolledAt: DateTime(2026, 1, 1),
      progress: testProgress,
      status: 'completed',
    );

    test('Instructor copyWith and equality', () {
      final updated = testInstructor.copyWith(name: 'Updated Name');
      expect(updated.name, equals('Updated Name'));
      expect(updated.id, equals(testInstructor.id));
      expect(testInstructor == testInstructor, isTrue);
      expect(testInstructor == updated, isFalse);
    });

    test('Lesson copyWith and equality', () {
      final updated = testLesson.copyWith(isCompleted: true);
      expect(updated.isCompleted, isTrue);
      expect(testLesson.isCompleted, isFalse);
      expect(testLesson == testLesson, isTrue);
    });

    test('Chapter unmodifiable lessons list', () {
      expect(() => testChapter.lessons.add(testLesson), throwsUnsupportedError);
    });

    test('Module unmodifiable chapters list', () {
      expect(
          () => testModule.chapters.add(testChapter), throwsUnsupportedError);
    });

    test('Course copyWith and equality', () {
      final updated = testCourse.copyWith(rating: 5.0);
      expect(updated.rating, equals(5.0));
      expect(testCourse == updated, isFalse);
    });

    test('LearningProgress copyWith and equality', () {
      final updated = testProgress.copyWith(overallProgressPercentage: 50.0);
      expect(updated.overallProgressPercentage, equals(50.0));
      expect(testProgress == updated, isFalse);
    });

    test('Enrollment copyWith and equality', () {
      final updated = testEnrollment.copyWith(status: 'active');
      expect(updated.status, equals('active'));
      expect(testEnrollment == testEnrollment, isTrue);
    });
  });
}
