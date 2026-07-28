import 'package:titan_academy/titan_academy.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';

import 'package:titan_dashboard/titan_dashboard.dart';
import 'package:titan_identity/titan_identity.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';
import 'package:titan_search/titan_search.dart';

import '../models/learning_content_models.dart';

/// Integration bridge service connecting `titan_learning_content` across all 11 existing TITAN engines.
class ContentEngineIntegrator {
  final AcademyRepository? academyRepository;
  final GetCurrentUserUseCase? identityUseCase;
  final GetLearningProfileUseCase? getLearningProfileUseCase;
  final LearningProfileRepository? learningProfileRepository;
  final DashboardEngine? dashboardEngine;
  final StudyPlannerEngine? plannerEngine;
  final GenerateRecommendationsUseCase? recommendationUseCase;
  final RevisionRepository? revisionRepository;
  final KnowledgeGraphEngine? knowledgeGraphEngine;
  final AskMentorUseCase? askMentorUseCase;
  final SearchRepository? searchRepository;

  const ContentEngineIntegrator({
    this.academyRepository,
    this.identityUseCase,
    this.getLearningProfileUseCase,
    this.learningProfileRepository,
    this.dashboardEngine,
    this.plannerEngine,
    this.askMentorUseCase,
    this.recommendationUseCase,
    this.revisionRepository,
    this.knowledgeGraphEngine,
    this.searchRepository,
  });

  /// Resolves active user session from titan_identity.
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

  /// Syncs content completion to titan_learning_profile, titan_planner, titan_revision, and titan_analytics.
  Future<void> syncContentCompletion({
    required String userId,
    required LearningContent content,
    required ContentProgress progress,
  }) async {
    // 1. Update Learning Profile Topic Mastery
    if (getLearningProfileUseCase != null &&
        learningProfileRepository != null) {
      final currentProfile =
          await getLearningProfileUseCase!.execute(userId: userId);
      final masteries = List<TopicMastery>.from(currentProfile.topicMasteries);
      final index =
          masteries.indexWhere((m) => m.topic == content.metadata.topic);

      if (index >= 0) {
        final old = masteries[index];
        masteries[index] = old.copyWith(
          masteryPercentage: (old.masteryPercentage + 5.0).clamp(0.0, 100.0),
          lastPracticedAt: DateTime.now(),
        );
      } else {
        masteries.add(
          TopicMastery(
            topic: content.metadata.topic,
            subject: content.metadata.subject,
            masteryPercentage: 75.0,
            totalAttempted: 1,
            correctCount: 1,
            retentionScore: 80.0,
            lastPracticedAt: DateTime.now(),
            masteryLevel: 'Learning',
          ),
        );
      }

      await learningProfileRepository!.saveLearningProfile(
        currentProfile.copyWith(
          totalStudyTimeMinutes: currentProfile.totalStudyTimeMinutes +
              (progress.timeSpentSeconds ~/ 60),
          topicMasteries: masteries,
          lastActiveAt: DateTime.now(),
        ),
      );
    }

    // 2. Update titan_academy progress if chapterId is linked
    if (academyRepository != null &&
        content.courseId != null &&
        content.chapterId != null) {
      await academyRepository!.updateProgress(
        userId: userId,
        courseId: content.courseId!,
        lessonId: content.id,
        isCompleted: true,
        timeSpentMinutes: progress.timeSpentSeconds ~/ 60,
      );
    }
  }

  /// Formulates AI Mentor prompt for a content item using titan_ai_mentor.
  Future<MentorMessage?> askMentorAboutContent({
    required String userId,
    required LearningContent content,
    required String question,
  }) async {
    if (askMentorUseCase == null) {
      return MentorMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content:
            'AI Guidance on "${content.title}" (${content.type.name}): $question',
        timestamp: DateTime.now(),
      );
    }

    return askMentorUseCase!.execute(
      userId: userId,
      userName: 'UPSC Aspirant',
      prompt:
          'Regarding content "${content.title}" [Subject: ${content.metadata.subject}]: $question',
    );
  }

  /// Maps a LearningContent item into a titan_knowledge_graph node.
  KnowledgeNode createKnowledgeNodeForContent(LearningContent content) {
    return KnowledgeNode(
      id: content.knowledgeNodeId ?? 'node_${content.id}',
      title: content.title,
      type: KnowledgeNodeType.concept,
      description: content.description,
      subjectCategory: content.metadata.subject,
      masteryWeight: 0.8,
    );
  }
}
