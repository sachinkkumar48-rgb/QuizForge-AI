import 'package:flutter_test/flutter_test.dart';
import 'package:titan_academy/titan_academy.dart';
import 'package:titan_course_management/titan_course_management.dart';

void main() {
  group('Course Management Unit Tests', () {
    late CourseManagementRepository repository;

    setUp(() {
      repository = CourseManagementRepositoryImpl();
    });

    test('getAdminCourses returns seeded default course', () async {
      final courses = await repository.getAdminCourses();
      expect(courses.isNotEmpty, isTrue);
      expect(courses.first.title, contains('Indian Polity'));
    });

    test('createCourse adds new course and metadata', () async {
      final newCourse = Course(
        id: 'course_bpsc_history',
        title: 'BPSC Modern History & Freedom Struggle',
        description: 'Targeted BPSC State Exam History course.',
        subject: 'History',
        level: 'Intermediate',
        instructor: Instructor(
          id: 'inst_2',
          name: 'History Board',
          title: 'Senior Faculty',
          bio: 'History faculty',
          avatarUrl: 'https://example.com/avatar.jpg',
          qualifications: const ['Ph.D.'],
          rating: 4.8,
          studentCount: 1000,
        ),
        modules: const [],
        estimatedHours: 20.0,
        rating: 4.8,
        enrolledCount: 500,
        imageUrl: 'https://example.com/course.jpg',
        tags: const ['BPSC', 'History'],
      );

      final metadata = KmpCourseMetadata(
        authorId: 'editor_bpsc',
        authorName: 'BPSC Subject Lead',
        category: ExamCategory.bpsc,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createCourse(newCourse, metadata);
      final fetched = await repository.getCourseById('course_bpsc_history');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('BPSC Modern History & Freedom Struggle'));

      final bpscCourses =
          await repository.getAdminCourses(category: ExamCategory.bpsc);
      expect(bpscCourses.length, equals(1));
    });

    test('KmpLearningPath serialization and exam filtering works', () async {
      final paths =
          await repository.getLearningPaths(category: ExamCategory.upsc);
      expect(paths.isNotEmpty, isTrue);
      expect(paths.first.targetExam, equals(ExamCategory.upsc));
    });
  });
}
