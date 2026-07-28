import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_academy/titan_academy.dart';

void main() {
  group('Material 3 Widgets Unit & Widget Tests', () {
    late RepositoryData fixture;

    setUp(() {
      fixture = RepositoryData();
    });

    Widget wrapMaterial(Widget child) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      );
    }

    testWidgets('CourseCard renders course details and rating',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapMaterial(
          CourseCard(
            course: fixture.testCourse,
            enrollment: fixture.testEnrollment,
          ),
        ),
      );

      expect(
          find.text('Mastering Indian Polity & Constitution'), findsOneWidget);
      expect(find.text('Dr. M. Laxmikanth'), findsOneWidget);
      expect(find.text('Polity'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
    });

    testWidgets('LessonCard renders lesson info and completed icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapMaterial(
          LessonCard(
            lesson: fixture.testLesson,
            isCurrent: true,
          ),
        ),
      );

      expect(find.text('Preamble & Rights'), findsOneWidget);
      expect(find.textContaining('30 mins'), findsOneWidget);
    });

    testWidgets('ContinueLearningCard renders active lesson and resume button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapMaterial(
          ContinueLearningCard(
            course: fixture.testCourse,
            lesson: fixture.testLesson,
            enrollment: fixture.testEnrollment,
          ),
        ),
      );

      expect(find.text('CONTINUE LEARNING'), findsOneWidget);
      expect(find.text('Resume Lesson'), findsOneWidget);
      expect(find.textContaining('Preamble & Rights'), findsOneWidget);
    });

    testWidgets('ChapterList renders chapters expandable accordion',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapMaterial(
          Scaffold(
            body: ChapterList(
              chapters: [fixture.testChapter],
            ),
          ),
        ),
      );

      expect(find.text('Constitutional Framework'), findsOneWidget);
    });

    testWidgets(
        'CourseDetailsPage renders full course details and enroll button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapMaterial(
          CourseDetailsPage(
            course: fixture.testCourse,
            enrollment: fixture.testEnrollment,
          ),
        ),
      );

      expect(
          find.text('Mastering Indian Polity & Constitution'), findsOneWidget);
      expect(find.text('Dr. M. Laxmikanth'), findsOneWidget);
      expect(find.text('Ask AI Mentor'), findsOneWidget);
      expect(find.text('Enrolled in Course'), findsOneWidget);
    });

    testWidgets('AcademyDashboard renders dashboard catalog and search',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapMaterial(
          AcademyDashboard(
            catalog: [fixture.testCourse],
            enrollments: [fixture.testEnrollment],
            activeCourse: fixture.testCourse,
            activeLesson: fixture.testLesson,
            activeEnrollment: fixture.testEnrollment,
          ),
        ),
      );

      expect(find.text('TITAN Academy'), findsWidgets);
      expect(find.text('Course Catalog'), findsOneWidget);
      expect(find.text('Mastering Indian Polity & Constitution'),
          findsNWidgets(2));
    });
  });
}

class RepositoryData {
  late final Instructor testInstructor;
  late final Lesson testLesson;
  late final Chapter testChapter;
  late final Module testModule;
  late final Course testCourse;
  late final LearningProgress testProgress;
  late final Enrollment testEnrollment;

  RepositoryData() {
    testInstructor = Instructor(
      id: 'inst_1',
      name: 'Dr. M. Laxmikanth',
      title: 'Constitutional Scholar',
      bio: 'Author and mentor',
      avatarUrl: 'assets/inst.png',
      qualifications: const ['Ph.D.'],
      rating: 4.9,
      studentCount: 154000,
    );

    testLesson = const Lesson(
      id: 'les_p1_1_1',
      chapterId: 'chap_p1_1',
      title: 'Preamble & Rights',
      description: 'Preamble explanation',
      durationMinutes: 30,
      type: 'video',
      content: 'Preamble content',
      order: 1,
      topic: 'Polity',
    );

    testChapter = Chapter(
      id: 'chap_p1_1',
      moduleId: 'mod_p1',
      title: 'Constitutional Framework',
      description: 'Framework chapter',
      lessons: [testLesson],
      durationMinutes: 30,
    );

    testModule = Module(
      id: 'mod_p1',
      courseId: 'course_polity_101',
      title: 'Polity Module 1',
      description: 'Module desc',
      chapters: [testChapter],
      durationMinutes: 30,
    );

    testCourse = Course(
      id: 'course_polity_101',
      title: 'Mastering Indian Polity & Constitution',
      description: 'Polity description',
      subject: 'Polity',
      level: 'Intermediate',
      instructor: testInstructor,
      modules: [testModule],
      estimatedHours: 45.0,
      rating: 4.9,
      enrolledCount: 42000,
      imageUrl: 'assets/polity.png',
      tags: const ['Polity'],
    );

    testProgress = LearningProgress(
      courseId: 'course_polity_101',
      userId: 'user_1',
      completedLessonIds: const {'les_p1_1_1'},
      lastAccessedLessonId: 'les_p1_1_1',
      overallProgressPercentage: 100.0,
      timeSpentMinutes: 30,
      lastAccessedAt: DateTime(2026, 1, 1),
    );

    testEnrollment = Enrollment(
      id: 'enr_1',
      userId: 'user_1',
      courseId: 'course_polity_101',
      enrolledAt: DateTime(2026, 1, 1),
      progress: testProgress,
    );
  }
}
