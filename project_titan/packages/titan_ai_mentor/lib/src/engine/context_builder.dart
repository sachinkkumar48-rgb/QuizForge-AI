import 'dart:async';

import '../models/mentor_context.dart';

typedef IdentitySupplier = FutureOr<Map<String, dynamic>?> Function(
    String userId);
typedef LearningProfileSupplier = FutureOr<Map<String, dynamic>?> Function(
    String userId);
typedef LearningJourneySupplier = FutureOr<Map<String, dynamic>?> Function(
    String userId);
typedef PlannerSupplier = FutureOr<Map<String, double>?> Function(
    String userId);
typedef KnowledgeGraphSupplier = FutureOr<Map<String, dynamic>?> Function(
    String userId);
typedef DashboardSupplier = FutureOr<Map<String, dynamic>?> Function(
    String userId);
typedef RecommendationSupplier = FutureOr<String?> Function(String userId);
typedef RevisionSupplier = FutureOr<int?> Function(String userId);
typedef NotesSupplier = FutureOr<List<String>?> Function(String userId);
typedef RecentSessionsSupplier = FutureOr<List<String>?> Function(
    String userId);
typedef SearchSupplier = FutureOr<List<String>?> Function(String userId);
typedef ConversationHistorySupplier = FutureOr<List<Map<String, String>>?>
    Function(String userId);

/// Modular, lazy Context Builder assembling real-time context across all 12 TITAN subsystems:
/// 1. Identity
/// 2. Learning Profile
/// 3. Learning Journey
/// 4. Planner
/// 5. Knowledge Graph
/// 6. Dashboard
/// 7. Recommendations
/// 8. Revision
/// 9. Notes
/// 10. Recent Learning Sessions
/// 11. Search History
/// 12. Conversation History
class ContextBuilder {
  final IdentitySupplier? identitySupplier;
  final LearningProfileSupplier? learningProfileSupplier;
  final LearningJourneySupplier? learningJourneySupplier;
  final PlannerSupplier? plannerSupplier;
  final KnowledgeGraphSupplier? knowledgeGraphSupplier;
  final DashboardSupplier? dashboardSupplier;
  final RecommendationSupplier? recommendationSupplier;
  final RevisionSupplier? revisionSupplier;
  final NotesSupplier? notesSupplier;
  final RecentSessionsSupplier? recentSessionsSupplier;
  final SearchSupplier? searchSupplier;
  final ConversationHistorySupplier? conversationHistorySupplier;

  const ContextBuilder({
    this.identitySupplier,
    this.learningProfileSupplier,
    this.learningJourneySupplier,
    this.plannerSupplier,
    this.knowledgeGraphSupplier,
    this.dashboardSupplier,
    this.recommendationSupplier,
    this.revisionSupplier,
    this.notesSupplier,
    this.recentSessionsSupplier,
    this.searchSupplier,
    this.conversationHistorySupplier,
  });

  /// Assembles comprehensive unified [MentorContext].
  Future<MentorContext> buildContext({
    required String userId,
    required String userName,
    String targetExam = 'UPSC CSE',
    List<String>? weakSubjects,
    List<String>? strongSubjects,
    List<String>? recentSearchQueries,
    int pendingRevisionsCount = 0,
    String? recommendedTopic,
    double studyHoursTarget = 6.0,
    double studyHoursCompleted = 0.0,
    double accuracyRate = 0.0,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    String finalUserName = userName;
    String finalTargetExam = targetExam;
    List<String> finalWeak =
        weakSubjects ?? const ['Indian Polity', 'Modern History'];
    List<String> finalStrong = strongSubjects ?? const ['Geography'];
    String? finalTopic = recommendedTopic;
    List<String> finalQueries =
        recentSearchQueries ?? const ['Fundamental Rights', 'Monsoon'];
    int finalPending = pendingRevisionsCount;
    double finalTargetHours = studyHoursTarget;
    double finalCompletedHours = studyHoursCompleted;
    double finalAccuracy = accuracyRate;

    final assembledModules = <String>[];

    // 1. Identity
    if (identitySupplier != null) {
      try {
        final data = await identitySupplier!(userId);
        if (data != null) {
          finalUserName = data['userName'] as String? ?? finalUserName;
          finalTargetExam = data['targetExam'] as String? ?? finalTargetExam;
          assembledModules.add('Identity');
        }
      } catch (_) {}
    }

    // 2. Learning Profile
    if (learningProfileSupplier != null) {
      try {
        final data = await learningProfileSupplier!(userId);
        if (data != null) {
          finalWeak =
              (data['weakSubjects'] as List?)?.cast<String>() ?? finalWeak;
          finalStrong =
              (data['strongSubjects'] as List?)?.cast<String>() ?? finalStrong;
          assembledModules.add('Learning Profile');
        }
      } catch (_) {}
    }

    // 3. Learning Journey
    if (learningJourneySupplier != null) {
      try {
        final data = await learningJourneySupplier!(userId);
        if (data != null) {
          assembledModules.add('Learning Journey');
        }
      } catch (_) {}
    }

    // 4. Planner
    if (plannerSupplier != null) {
      try {
        final data = await plannerSupplier!(userId);
        if (data != null) {
          finalTargetHours = data['target'] ?? finalTargetHours;
          finalCompletedHours = data['completed'] ?? finalCompletedHours;
          assembledModules.add('Planner');
        }
      } catch (_) {}
    }

    // 5. Knowledge Graph
    if (knowledgeGraphSupplier != null) {
      try {
        final data = await knowledgeGraphSupplier!(userId);
        if (data != null) {
          finalTopic = data['activeConcept'] as String? ?? finalTopic;
          assembledModules.add('Knowledge Graph');
        }
      } catch (_) {}
    }

    // 6. Dashboard
    if (dashboardSupplier != null) {
      try {
        final data = await dashboardSupplier!(userId);
        if (data != null) {
          finalAccuracy =
              (data['accuracyRate'] as num?)?.toDouble() ?? finalAccuracy;
          assembledModules.add('Dashboard');
        }
      } catch (_) {}
    }

    // 7. Recommendations
    if (recommendationSupplier != null) {
      try {
        final topic = await recommendationSupplier!(userId);
        if (topic != null) {
          finalTopic = topic;
          assembledModules.add('Recommendations');
        }
      } catch (_) {}
    }

    // 8. Revision
    if (revisionSupplier != null) {
      try {
        final revCount = await revisionSupplier!(userId);
        if (revCount != null) {
          finalPending = revCount;
          assembledModules.add('Revision');
        }
      } catch (_) {}
    }

    // 9. Notes
    List<String> recentNotes = const [];
    if (notesSupplier != null) {
      try {
        final nData = await notesSupplier!(userId);
        if (nData != null) {
          recentNotes = nData;
          assembledModules.add('Notes');
        }
      } catch (_) {}
    }

    // 10. Recent Learning Sessions
    List<String> recentSessions = const [];
    if (recentSessionsSupplier != null) {
      try {
        final sData = await recentSessionsSupplier!(userId);
        if (sData != null) {
          recentSessions = sData;
          assembledModules.add('Recent Sessions');
        }
      } catch (_) {}
    }

    // 11. Search History
    if (searchSupplier != null) {
      try {
        final sData = await searchSupplier!(userId);
        if (sData != null) {
          finalQueries = sData;
          assembledModules.add('Search History');
        }
      } catch (_) {}
    }

    // 12. Conversation History
    List<Map<String, String>> convHistory = const [];
    if (conversationHistorySupplier != null) {
      try {
        final hData = await conversationHistorySupplier!(userId);
        if (hData != null) {
          convHistory = hData;
          assembledModules.add('Conversation History');
        }
      } catch (_) {}
    }

    final metadata = Map<String, dynamic>.from(additionalMetadata ?? {});
    metadata['assembledModules'] = assembledModules;
    metadata['recentNotes'] = recentNotes;
    metadata['recentSessions'] = recentSessions;
    metadata['conversationHistoryTurnCount'] = convHistory.length;

    return MentorContext(
      userId: userId,
      userName: finalUserName,
      targetExam: finalTargetExam,
      weakSubjects: finalWeak,
      strongSubjects: finalStrong,
      recentSearchQueries: finalQueries,
      pendingRevisionsCount: finalPending,
      recommendedTopic: finalTopic ?? 'Preamble & Fundamental Rights',
      studyHoursTarget: finalTargetHours,
      studyHoursCompleted: finalCompletedHours,
      accuracyRate: finalAccuracy,
      metadata: metadata,
    );
  }
}
