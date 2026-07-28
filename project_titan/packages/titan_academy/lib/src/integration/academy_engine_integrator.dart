import 'package:titan_ai_mentor/titan_ai_mentor.dart';
import 'package:titan_identity/titan_identity.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';

import '../models/academy_models.dart';

/// Integration bridge service encapsulating communication between TITAN Academy
/// and external TITAN engines without duplicating business logic.
class AcademyEngineIntegrator {
  final GetCurrentUserUseCase? identityUseCase;
  final GetLearningProfileUseCase? getLearningProfileUseCase;
  final LearningProfileRepository? learningProfileRepository;
  final GenerateRecommendationsUseCase? recommendationUseCase;
  final StudyPlannerEngine? plannerEngine;
  final AskMentorUseCase? askMentorUseCase;

  const AcademyEngineIntegrator({
    this.identityUseCase,
    this.getLearningProfileUseCase,
    this.learningProfileRepository,
    this.recommendationUseCase,
    this.plannerEngine,
    this.askMentorUseCase,
  });

  /// Resolves current active user from titan_identity engine.
  Future<User?> getCurrentUser() async {
    if (identityUseCase != null) {
      return identityUseCase!.getUser();
    }
    return User(
      id: 'default_aspirant',
      email: 'aspirant@titan.academy',
      displayName: 'UPSC Aspirant',
      providerType: AuthProviderType.guest,
      createdAt: DateTime.now(),
    );
  }

  /// Syncs completed lesson to titan_learning_profile engine.
  Future<void> syncLessonCompletionToProfile({
    required String userId,
    required Course course,
    required Lesson lesson,
    required int timeSpentMinutes,
  }) async {
    if (getLearningProfileUseCase == null ||
        learningProfileRepository == null) {
      return;
    }

    final currentProfile =
        await getLearningProfileUseCase!.execute(userId: userId);
    final existingMasteries =
        List<TopicMastery>.from(currentProfile.topicMasteries);
    final topicIndex =
        existingMasteries.indexWhere((tm) => tm.topic == lesson.topic);

    if (topicIndex >= 0) {
      final oldMastery = existingMasteries[topicIndex];
      final newAttempted = oldMastery.totalAttempted + 1;
      final newCorrect = oldMastery.correctCount + 1;
      final newPercentage = (newCorrect / newAttempted) * 100.0;
      existingMasteries[topicIndex] = oldMastery.copyWith(
        masteryPercentage: newPercentage,
        totalAttempted: newAttempted,
        correctCount: newCorrect,
        lastPracticedAt: DateTime.now(),
        masteryLevel: newPercentage > 80.0 ? 'Proficient' : 'Learning',
      );
    } else {
      existingMasteries.add(
        TopicMastery(
          topic: lesson.topic,
          subject: course.subject,
          masteryPercentage: 80.0,
          totalAttempted: 1,
          correctCount: 1,
          retentionScore: 85.0,
          lastPracticedAt: DateTime.now(),
          masteryLevel: 'Learning',
        ),
      );
    }

    final updatedProfile = currentProfile.copyWith(
      totalStudyTimeMinutes:
          currentProfile.totalStudyTimeMinutes + timeSpentMinutes,
      topicMasteries: existingMasteries,
      lastActiveAt: DateTime.now(),
    );

    await learningProfileRepository!.saveLearningProfile(updatedProfile);
  }

  /// Generates study planner tasks in titan_planner for active course lessons.
  StudyTask createPlannerTaskForLesson({
    required Course course,
    required Lesson lesson,
  }) {
    return StudyTask(
      id: 'task_${course.id}_${lesson.id}',
      title: '${course.title}: ${lesson.title}',
      topic: lesson.topic,
      category: 'Concept Learning',
      priority: 'High',
      estimatedDurationMinutes: lesson.durationMinutes,
      isCompleted: lesson.isCompleted,
    );
  }

  /// Creates a KnowledgeNode from titan_knowledge_graph for a course topic.
  KnowledgeNode createKnowledgeNodeForCourse(Course course) {
    return KnowledgeNode(
      id: course.knowledgeNodeId ?? 'node_${course.id}',
      title: course.title,
      type: KnowledgeNodeType.topic,
      description: course.description,
      subjectCategory: course.subject,
      masteryWeight: 0.8,
    );
  }

  /// Formulates AI Mentor prompt using titan_ai_mentor context.
  Future<MentorMessage?> askMentorAboutLesson({
    required String userId,
    required Course course,
    required Lesson lesson,
    required String question,
  }) async {
    final promptText =
        'Regarding ${course.title} - Lesson "${lesson.title}": $question';

    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'Here is guidance on "${lesson.title}" in ${course.title}: $question\n\nFocus on core concepts, PYQ trends, and analytical connections to current affairs.',
        timestamp: DateTime.now(),
      );
    }

    return askMentorUseCase!.execute(
      userId: userId,
      userName: 'UPSC Aspirant',
      prompt: promptText,
    );
  }

  /// Generates course recommendations based on user study metrics.
  List<Course> filterRecommendedCourses({
    required List<Course> catalog,
    required String preferredSubject,
  }) {
    return catalog
        .where((c) =>
            c.subject.toLowerCase() == preferredSubject.toLowerCase() ||
            c.rating >= 4.5)
        .toList();
  }
}
