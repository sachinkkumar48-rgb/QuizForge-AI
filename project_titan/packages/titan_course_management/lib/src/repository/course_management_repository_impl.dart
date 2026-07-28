import 'package:titan_academy/titan_academy.dart';
import '../models/kmp_course_models.dart';
import '../seed/flagship_polity_course.dart';
import 'course_management_repository.dart';

class CourseManagementRepositoryImpl implements CourseManagementRepository {
  final Map<String, Course> _courses = {};
  final Map<String, KmpCourseMetadata> _metadataStore = {};
  final Map<String, KmpLearningPath> _paths = {};

  CourseManagementRepositoryImpl() {
    // Seed flagship course: UPSC Civil Services – Indian Polity Foundation
    final flagship = FlagshipPolityCourseSeed.buildCourse();
    _courses[flagship.id] = flagship;
    _metadataStore[flagship.id] = FlagshipPolityCourseSeed.metadata;

    final flagshipPath = FlagshipPolityCourseSeed.learningPath;
    _paths[flagshipPath.id] = flagshipPath;

    // Seed default administrative course
    final defaultCourse = Course(
      id: 'course_polity_101',
      title: 'Indian Polity & Governance Masterclass',
      description:
          'Comprehensive UPSC Prelims & Mains Polity Foundation Course.',
      subject: 'Polity',
      level: 'Advanced',
      instructor: Instructor(
        id: 'inst_1',
        name: 'Dr. M. Laxmikanth',
        title: 'Senior UPSC Faculty',
        bio: 'Senior UPSC Faculty',
        avatarUrl: 'assets/images/instructor.png',
        qualifications: const ['M.A. Political Science', 'Author'],
        rating: 4.9,
        studentCount: 50000,
      ),
      modules: [
        Module(
          id: 'mod_1',
          courseId: 'course_polity_101',
          title: 'Constitutional Framework',
          description: 'Preamble, Fundamental Rights, DPSP, and Duties.',
          durationMinutes: 120,
          chapters: [
            Chapter(
              id: 'chap_1',
              moduleId: 'mod_1',
              title: 'Fundamental Rights & Judicial Review',
              description: 'Analysis of Article 21 and basic structure.',
              durationMinutes: 45,
              lessons: const [
                Lesson(
                  id: 'lesson_fr_21',
                  chapterId: 'chap_1',
                  title: 'Article 21: Protection of Life and Personal Liberty',
                  description: 'Detailed study of Article 21',
                  durationMinutes: 45,
                  type: 'article',
                  content: 'Article 21 details',
                  order: 1,
                  topic: 'Fundamental Rights',
                ),
              ],
            ),
          ],
        ),
      ],
      estimatedHours: 60.0,
      rating: 4.8,
      enrolledCount: 1250,
      imageUrl: 'assets/images/polity.png',
      tags: const ['Polity', 'UPSC', 'Governance'],
    );

    _courses[defaultCourse.id] = defaultCourse;
    _metadataStore[defaultCourse.id] = KmpCourseMetadata(
      authorId: 'admin_1',
      authorName: 'TITAN Editorial Board',
      category: ExamCategory.upsc,
      difficulty: KmpDifficulty.master,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final defaultPath = KmpLearningPath(
      id: 'path_upsc_polity_fast_track',
      title: 'UPSC Polity Fast-Track 2027',
      description: 'Structured 60-day roadmap for Polity Prelims & Mains.',
      targetExam: ExamCategory.upsc,
      courseIdsSequence: ['course_polity_101'],
      isPublished: true,
    );
    _paths[defaultPath.id] = defaultPath;
  }

  @override
  Future<List<Course>> getAdminCourses({ExamCategory? category}) async {
    if (category == null) return _courses.values.toList();
    return _courses.values.where((c) {
      final meta = _metadataStore[c.id];
      return meta?.category == category;
    }).toList();
  }

  @override
  Future<Course?> getCourseById(String id) async {
    return _courses[id];
  }

  @override
  Future<Course> createCourse(Course course, KmpCourseMetadata metadata) async {
    _courses[course.id] = course;
    _metadataStore[course.id] = metadata;
    return course;
  }

  @override
  Future<Course> updateCourse(Course course, KmpCourseMetadata metadata) async {
    _courses[course.id] = course;
    _metadataStore[course.id] = metadata;
    return course;
  }

  @override
  Future<void> deleteCourse(String id) async {
    _courses.remove(id);
    _metadataStore.remove(id);
  }

  @override
  Future<List<KmpLearningPath>> getLearningPaths(
      {ExamCategory? category}) async {
    if (category == null) return _paths.values.toList();
    return _paths.values.where((p) => p.targetExam == category).toList();
  }

  @override
  Future<KmpLearningPath> createLearningPath(KmpLearningPath path) async {
    _paths[path.id] = path;
    return path;
  }
}
