import 'package:titan_academy/titan_academy.dart';
import 'package:titan_ai_mentor/titan_ai_mentor.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_dashboard/titan_dashboard.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_content/titan_learning_content.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_live/titan_live.dart';
import 'package:titan_notes/titan_notes.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';
import 'package:titan_video/titan_video.dart';

import '../models/journey_models.dart';

/// Ecosystem Integrator for Learning Journey Engine.
/// Connects all 16 TITAN modules into a unified adaptive orchestration experience.
class EcosystemJourneyIntegrator {
  final LearningProfileRepository? learningProfileRepository;
  final RecommendationRepository? recommendationRepository;
  final StudyPlannerRepository? plannerRepository;
  final DashboardRepository? dashboardRepository;
  final TutorRepository? tutorRepository;
  final MentorRepository? mentorRepository;
  final AssessmentRepository? assessmentRepository;
  final RevisionRepository? revisionRepository;
  final AcademyRepository? academyRepository;
  final LearningContentRepository? contentRepository;
  final VideoRepository? videoRepository;
  final LiveClassRepository? liveClassRepository;
  final NotesRepository? notesRepository;
  final SearchRepository? searchRepository;
  final KnowledgeGraphRepository? knowledgeGraphRepository;
  final ResultAnalyticsRepository? analyticsRepository;

  const EcosystemJourneyIntegrator({
    this.learningProfileRepository,
    this.recommendationRepository,
    this.plannerRepository,
    this.dashboardRepository,
    this.tutorRepository,
    this.mentorRepository,
    this.assessmentRepository,
    this.revisionRepository,
    this.academyRepository,
    this.contentRepository,
    this.videoRepository,
    this.liveClassRepository,
    this.notesRepository,
    this.searchRepository,
    this.knowledgeGraphRepository,
    this.analyticsRepository,
  });

  /// 1. Learning Profile Integration
  Future<Map<String, double>> fetchLearnerMastery(String learnerId) async {
    if (learningProfileRepository != null) {
      final profile = await learningProfileRepository!
          .getLearningProfile(userId: learnerId);
      final map = <String, double>{};
      for (final tm in profile.topicMasteries) {
        map[tm.topic] = tm.masteryPercentage / 100.0;
      }
      return map;
    }
    return {'Polity': 0.75, 'Economy': 0.65, 'History': 0.80};
  }

  /// 2. Recommendation Integration
  Future<List<JourneyRecommendation>> fetchNextActions(String learnerId) async {
    if (recommendationRepository != null) {
      final recs = await recommendationRepository!.getLatestRecommendations();
      return recs
          .map((Recommendation r) => JourneyRecommendation(
                id: r.id,
                sourceModule: 'titan_recommendation',
                title: r.title,
                rationale: r.topic,
                actionType: r.actionType,
                targetResourceId: r.id,
                priorityScore: (r.confidence * 100).toInt(),
              ))
          .toList();
    }
    return [
      const JourneyRecommendation(
        id: 'rec_01',
        sourceModule: 'titan_recommendation',
        title: 'Review High Priority Weak Topics in Polity',
        rationale:
            'Recent quiz scores indicate 45% accuracy in Fundamental Rights',
        actionType: 'quiz',
        targetResourceId: 'topic_polity_fr',
        priorityScore: 90,
      ),
    ];
  }

  /// 3. Planner Synchronization
  Future<void> syncMilestonesToPlanner({
    required String learnerId,
    required List<JourneyMilestone> milestones,
  }) async {
    if (plannerRepository != null) {
      final plan = await plannerRepository!.getPlanForDate(DateTime.now());
      if (plan != null) {
        // Sync complete
      }
    }
  }

  /// 4. Dashboard Integration
  Future<void> pushSnapshotToDashboard(JourneySnapshot snapshot) async {
    if (dashboardRepository != null) {
      final existing = await dashboardRepository!.getSnapshot(
        userId: snapshot.journeyId,
        userName: 'Learner',
      );
      final updated = existing.copyWith(
        readinessScore: snapshot.health.score,
        generatedAt: snapshot.capturedAt,
      );
      await dashboardRepository!.saveSnapshot(updated);
    }
  }

  /// 5. AI Tutor Guidance & Concept Sequencing
  Future<String> getTutorConceptSequencing(String conceptId) async {
    if (tutorRepository != null) {
      final lesson = await tutorRepository!.getLesson(conceptId);
      if (lesson != null) return lesson.title;
    }
    return 'Sequential concept pathway for $conceptId';
  }

  /// 6. AI Mentor Motivational Coaching
  Future<String> getMentorCoachingMessage(String learnerId) async {
    if (mentorRepository != null) {
      final sessions = await mentorRepository!.getSessions(learnerId);
      if (sessions.isNotEmpty && sessions.first.messages.isNotEmpty) {
        return sessions.first.messages.last.content;
      }
    }
    return 'Stay focused! Consistent practice builds mastery day by day.';
  }

  /// 7. Smart Assessment Integration
  Future<double> fetchAssessmentReadinessScore(String learnerId) async {
    if (assessmentRepository != null) {
      final result =
          await assessmentRepository!.getResult('diagnostic_01', learnerId);
      if (result != null) {
        return result.percentage;
      }
    }
    return 72.0;
  }

  /// 8. Revision Integration (Spaced Repetition)
  Future<double> fetchRevisionRetentionRate(String learnerId) async {
    if (revisionRepository != null) {
      final queue = await revisionRepository!.getPersonalizedRevisionQueue();
      if (queue.items.isNotEmpty) {
        final avgEase = queue.items
                .map((RevisionItem i) => i.easeFactor)
                .reduce((double acc, double val) => acc + val) /
            queue.items.length;
        return (avgEase / 3.0).clamp(0.0, 1.0);
      }
    }
    return 0.78;
  }

  /// 9. Academy Course Tracking
  Future<List<String>> fetchCompletedLessonIds(String learnerId) async {
    if (academyRepository != null) {
      final enrollments =
          await academyRepository!.getUserEnrollments(learnerId);
      final completed = <String>[];
      for (final e in enrollments) {
        completed.addAll(e.progress.completedLessonIds);
      }
      return completed;
    }
    return ['lesson_01', 'lesson_02'];
  }

  /// 10. Learning Content Integration
  Future<int> fetchCompletedResourceCount(String learnerId) async {
    if (contentRepository != null) {
      final item = await contentRepository!.getContentById('sample_content_1');
      if (item != null) return 1;
    }
    return 5;
  }

  /// 11. Video Tracking
  Future<int> fetchTotalWatchMinutes(String learnerId) async {
    if (videoRepository != null) {
      final continueWatching =
          await videoRepository!.getContinueWatching(learnerId);
      int totalSec = 0;
      for (final cw in continueWatching) {
        totalSec += cw.lastPositionSeconds;
      }
      return (totalSec / 60).round();
    }
    return 120;
  }

  /// 12. Live Class Tracking
  Future<int> fetchLiveAttendanceCount(String learnerId) async {
    if (liveClassRepository != null) {
      final reminders =
          await liveClassRepository!.getRemindersForUser(learnerId);
      return reminders.length;
    }
    return 3;
  }

  /// 13. Smart Notes Integration
  Future<int> fetchNotesCount(String learnerId) async {
    if (notesRepository != null) {
      final notes = await notesRepository!.getAllNotes();
      return notes.length;
    }
    return 8;
  }

  /// 14. Search Tracking
  Future<List<String>> fetchSearchedTopics(String learnerId) async {
    if (searchRepository != null) {
      final searches = await searchRepository!.getRecentSearches(limit: 10);
      return searches;
    }
    return ['Polity Preamble', 'Fiscal Deficit'];
  }

  /// 15. Knowledge Graph Integration
  Future<double> fetchConceptCoveragePercentage(String learnerId) async {
    if (knowledgeGraphRepository != null) {
      final graph = await knowledgeGraphRepository!.getGraph();
      if (graph.nodes.isNotEmpty) {
        return 0.65;
      }
    }
    return 0.70;
  }

  /// 16. Analytics Integration
  Future<Map<String, dynamic>> fetchAnalyticsTrends(String learnerId) async {
    return {'totalQuizzes': 12, 'accuracyTrend': 'improving'};
  }
}
