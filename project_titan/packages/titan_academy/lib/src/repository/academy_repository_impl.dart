import '../integration/academy_engine_integrator.dart';
import '../models/academy_models.dart';
import 'academy_repository.dart';

/// Concrete implementation of [AcademyRepository] managing course catalog,
/// enrollment state persistence, and cross-engine synchronization.
class AcademyRepositoryImpl implements AcademyRepository {
  final AcademyEngineIntegrator integrator;
  final Map<String, Course> _courseCatalog = {};
  final Map<String, Enrollment> _enrollments =
      {}; // Key: '${userId}_${courseId}'

  AcademyRepositoryImpl({
    AcademyEngineIntegrator? integrator,
    List<Course>? initialCatalog,
  }) : integrator = integrator ?? const AcademyEngineIntegrator() {
    if (initialCatalog != null && initialCatalog.isNotEmpty) {
      for (final course in initialCatalog) {
        _courseCatalog[course.id] = course;
      }
    } else {
      _seedDefaultCatalog();
    }
  }

  void _seedDefaultCatalog() {
    final instPolity = Instructor(
      id: 'inst_1',
      name: 'Dr. M. Laxmikanth',
      title: 'Senior Constitutional Law Scholar',
      bio:
          'Author and renowned mentor in Indian Polity with over 20 years of coaching experience.',
      avatarUrl: 'assets/instructors/laxmikanth.png',
      qualifications: const [
        'M.A. Political Science',
        'Ph.D. Constitutional Law'
      ],
      rating: 4.9,
      studentCount: 154000,
    );

    final instHistory = Instructor(
      id: 'inst_2',
      name: 'Prof. Bipan Chandra',
      title: 'Historian & Modern History Specialist',
      bio:
          'Expert in 19th and 20th century Indian national movement and economic history.',
      avatarUrl: 'assets/instructors/bipan.png',
      qualifications: const ['Ph.D. History', 'Ex-Professor JNU'],
      rating: 4.8,
      studentCount: 120000,
    );

    final instEconomy = Instructor(
      id: 'inst_3',
      name: 'Ramesh Singh',
      title: 'Economics & Public Policy Faculty',
      bio:
          'Economist specializing in Union Budget, Monetary Policy, and Macroeconomic reforms.',
      avatarUrl: 'assets/instructors/ramesh.png',
      qualifications: const ['M.Sc. Economics (DSE)', 'Policy Advisor'],
      rating: 4.7,
      studentCount: 98000,
    );

    final polityCourse = Course(
      id: 'course_polity_101',
      title: 'Mastering Indian Polity & Constitution',
      description:
          'Comprehensive coverage of Preamble, Fundamental Rights, Parliament, and Judiciary for UPSC Civil Services Examination.',
      subject: 'Polity',
      level: 'Intermediate',
      instructor: instPolity,
      estimatedHours: 45.0,
      rating: 4.9,
      enrolledCount: 42000,
      imageUrl: 'assets/courses/polity.png',
      tags: const ['Constitution', 'Parliament', 'Rights', 'Polity'],
      knowledgeNodeId: 'node_polity_main',
      modules: [
        Module(
          id: 'mod_p1',
          courseId: 'course_polity_101',
          title: 'Constitutional Framework',
          description:
              'Historical background, Making of Constitution, and Salient Features.',
          durationMinutes: 180,
          chapters: [
            Chapter(
              id: 'chap_p1_1',
              moduleId: 'mod_p1',
              title: 'Preamble & Fundamental Rights',
              description:
                  'In-depth analysis of Articles 12-35 and constitutional remedies.',
              durationMinutes: 90,
              lessons: const [
                Lesson(
                  id: 'les_p1_1_1',
                  chapterId: 'chap_p1_1',
                  title: 'Significance & Basic Structure of Preamble',
                  description:
                      'Key terms: Sovereign, Socialist, Secular, Democratic, Republic.',
                  durationMinutes: 30,
                  type: 'video',
                  content:
                      'Detailed explanation of Kesavananda Bharati case and Preamble evolution.',
                  order: 1,
                  topic: 'Indian Polity',
                ),
                Lesson(
                  id: 'les_p1_1_2',
                  chapterId: 'chap_p1_1',
                  title: 'Article 14-18: Right to Equality',
                  description:
                      'Equality before law and equal protection of laws.',
                  durationMinutes: 30,
                  type: 'article',
                  content:
                      'Rule of law, exceptions, reservation policies, and milestone judgments.',
                  order: 2,
                  topic: 'Indian Polity',
                ),
                Lesson(
                  id: 'les_p1_1_3',
                  chapterId: 'chap_p1_1',
                  title: 'Article 21: Right to Life & Personal Liberty',
                  description:
                      'Expansive interpretation of Article 21 by Supreme Court.',
                  durationMinutes: 30,
                  type: 'interactive',
                  content:
                      'Maneka Gandhi case, privacy right, environmental right, and legal precedents.',
                  order: 3,
                  topic: 'Indian Polity',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final historyCourse = Course(
      id: 'course_history_101',
      title: 'Modern Indian History & Freedom Struggle',
      description:
          'From the advent of Europeans to Indian Independence, National Movement, and post-independence consolidation.',
      subject: 'History',
      level: 'Beginner',
      instructor: instHistory,
      estimatedHours: 38.0,
      rating: 4.8,
      enrolledCount: 31000,
      imageUrl: 'assets/courses/history.png',
      tags: const ['Modern History', 'Freedom Movement', 'Gandhian Era'],
      knowledgeNodeId: 'node_history_main',
      modules: [
        Module(
          id: 'mod_h1',
          courseId: 'course_history_101',
          title: 'The National Movement (1885-1947)',
          description:
              'Rise of nationalism, Moderate and Extremist phases, Gandhian Satyagrahas.',
          durationMinutes: 200,
          chapters: [
            Chapter(
              id: 'chap_h1_1',
              moduleId: 'mod_h1',
              title: 'Gandhian Era & Mass Movements',
              description:
                  'Non-Cooperation, Civil Disobedience, and Quit India Movement.',
              durationMinutes: 100,
              lessons: const [
                Lesson(
                  id: 'les_h1_1_1',
                  chapterId: 'chap_h1_1',
                  title: 'Champaran, Kheda, and Ahmedabad Satyagrahas',
                  description: 'Early experiments of Mahatma Gandhi in India.',
                  durationMinutes: 45,
                  type: 'video',
                  content:
                      'Analysis of local agrarian grievances and leadership methodology.',
                  order: 1,
                  topic: 'Modern History',
                ),
                Lesson(
                  id: 'les_h1_1_2',
                  chapterId: 'chap_h1_1',
                  title: 'Non-Cooperation Movement & Khilafat Issue',
                  description: 'Mass mobilization and constructive program.',
                  durationMinutes: 55,
                  type: 'article',
                  content:
                      'Causes, spread, Chauri Chaura withdrawal, and national impact.',
                  order: 2,
                  topic: 'Modern History',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final economyCourse = Course(
      id: 'course_economy_101',
      title: 'Indian Economy & Macroeconomic Policies',
      description:
          'Fiscal Policy, Monetary System, Banking, Inflation, External Trade, and Union Budget dynamics.',
      subject: 'Economy',
      level: 'Advanced',
      instructor: instEconomy,
      estimatedHours: 50.0,
      rating: 4.7,
      enrolledCount: 27000,
      imageUrl: 'assets/courses/economy.png',
      tags: const ['Macroeconomics', 'RBI Policy', 'Fiscal Deficit', 'Economy'],
      knowledgeNodeId: 'node_economy_main',
      modules: [
        Module(
          id: 'mod_e1',
          courseId: 'course_economy_101',
          title: 'Monetary Policy & Banking Operations',
          description:
              'RBI Repo rate, Reverse Repo, CRR, SLR, Inflation targeting, and NPA resolution.',
          durationMinutes: 150,
          chapters: [
            Chapter(
              id: 'chap_e1_1',
              moduleId: 'mod_e1',
              title: 'RBI Monetary Policy Framework',
              description:
                  'Quantitative and qualitative instruments of credit control.',
              durationMinutes: 75,
              lessons: const [
                Lesson(
                  id: 'les_e1_1_1',
                  chapterId: 'chap_e1_1',
                  title: 'LAF, Repo, Marginal Standing Facility (MSF)',
                  description: 'Liquidity management tools of Central Bank.',
                  durationMinutes: 40,
                  type: 'video',
                  content:
                      'How RBI controls money supply and liquidity in banking system.',
                  order: 1,
                  topic: 'Indian Economy',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    _courseCatalog[polityCourse.id] = polityCourse;
    _courseCatalog[historyCourse.id] = historyCourse;
    _courseCatalog[economyCourse.id] = economyCourse;
  }

  @override
  Future<List<Course>> getCourses({
    String? category,
    String? searchQuery,
    String? level,
  }) async {
    var courses = _courseCatalog.values.toList();

    if (category != null && category.isNotEmpty && category != 'All') {
      courses = courses
          .where((c) => c.subject.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (level != null && level.isNotEmpty && level != 'All') {
      courses = courses
          .where((c) => c.level.toLowerCase() == level.toLowerCase())
          .toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      courses = courses.where((c) {
        return c.title.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query) ||
            c.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    return courses;
  }

  @override
  Future<Course?> getCourseById(String id) async {
    return _courseCatalog[id];
  }

  @override
  Future<Enrollment> enrollInCourse({
    required String userId,
    required String courseId,
  }) async {
    final course = _courseCatalog[courseId];
    if (course == null) {
      throw ArgumentError('Course with id $courseId not found');
    }

    final key = '${userId}_$courseId';
    if (_enrollments.containsKey(key)) {
      return _enrollments[key]!;
    }

    final initialProgress = LearningProgress(
      courseId: courseId,
      userId: userId,
      completedLessonIds: const {},
      overallProgressPercentage: 0.0,
      timeSpentMinutes: 0,
      lastAccessedAt: DateTime.now(),
      isCompleted: false,
    );

    final enrollment = Enrollment(
      id: 'enr_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      courseId: courseId,
      enrolledAt: DateTime.now(),
      progress: initialProgress,
      status: 'active',
    );

    _enrollments[key] = enrollment;
    return enrollment;
  }

  @override
  Future<LearningProgress> updateProgress({
    required String userId,
    required String courseId,
    required String lessonId,
    bool isCompleted = true,
    int timeSpentMinutes = 0,
  }) async {
    final course = _courseCatalog[courseId];
    if (course == null) {
      throw ArgumentError('Course with id $courseId not found');
    }

    final key = '${userId}_$courseId';
    var enrollment = _enrollments[key];
    enrollment ??= await enrollInCourse(userId: userId, courseId: courseId);

    // Collect all lesson IDs in course to compute total percentage
    final allLessonIds = <String>[];
    Lesson? targetLesson;
    for (final m in course.modules) {
      for (final c in m.chapters) {
        for (final l in c.lessons) {
          allLessonIds.add(l.id);
          if (l.id == lessonId) {
            targetLesson = l;
          }
        }
      }
    }

    final updatedCompleted =
        Set<String>.from(enrollment.progress.completedLessonIds);
    if (isCompleted) {
      updatedCompleted.add(lessonId);
    } else {
      updatedCompleted.remove(lessonId);
    }

    final totalLessons = allLessonIds.isEmpty ? 1 : allLessonIds.length;
    final percentage = (updatedCompleted.length / totalLessons) * 100.0;
    final isCourseComplete = percentage >= 100.0;

    final updatedProgress = enrollment.progress.copyWith(
      completedLessonIds: updatedCompleted,
      lastAccessedLessonId: lessonId,
      overallProgressPercentage: percentage,
      timeSpentMinutes: enrollment.progress.timeSpentMinutes + timeSpentMinutes,
      lastAccessedAt: DateTime.now(),
      isCompleted: isCourseComplete,
    );

    final updatedEnrollment = enrollment.copyWith(
      progress: updatedProgress,
      status: isCourseComplete ? 'completed' : 'active',
    );

    _enrollments[key] = updatedEnrollment;

    // Cross-engine sync trigger
    if (targetLesson != null) {
      await integrator.syncLessonCompletionToProfile(
        userId: userId,
        course: course,
        lesson: targetLesson,
        timeSpentMinutes: timeSpentMinutes,
      );
    }

    return updatedProgress;
  }

  @override
  Future<Enrollment?> getEnrollment({
    required String userId,
    required String courseId,
  }) async {
    return _enrollments['${userId}_$courseId'];
  }

  @override
  Future<List<Enrollment>> getUserEnrollments(String userId) async {
    return _enrollments.values.where((e) => e.userId == userId).toList();
  }

  @override
  Future<Lesson?> getContinueLearningLesson({
    required String userId,
    String? courseId,
  }) async {
    final userEnrollments = await getUserEnrollments(userId);
    if (userEnrollments.isEmpty) return null;

    Enrollment? targetEnrollment;
    if (courseId != null) {
      targetEnrollment = userEnrollments.firstWhere(
        (e) => e.courseId == courseId,
        orElse: () => userEnrollments.first,
      );
    } else {
      // Find latest accessed enrollment
      userEnrollments.sort((a, b) =>
          b.progress.lastAccessedAt.compareTo(a.progress.lastAccessedAt));
      targetEnrollment = userEnrollments.first;
    }

    final course = await getCourseById(targetEnrollment.courseId);
    if (course == null) return null;

    final completed = targetEnrollment.progress.completedLessonIds;
    for (final m in course.modules) {
      for (final c in m.chapters) {
        for (final l in c.lessons) {
          if (!completed.contains(l.id)) {
            return l;
          }
        }
      }
    }

    // If all completed, return first lesson
    if (course.modules.isNotEmpty &&
        course.modules.first.chapters.isNotEmpty &&
        course.modules.first.chapters.first.lessons.isNotEmpty) {
      return course.modules.first.chapters.first.lessons.first;
    }

    return null;
  }
}
