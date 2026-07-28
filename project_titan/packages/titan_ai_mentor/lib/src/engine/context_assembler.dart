import 'dart:async';

import '../models/mentor_context.dart';

typedef IdentitySupplier = FutureOr<Map<String, dynamic>?> Function(
    String userId);
typedef LearningProfileSupplier = FutureOr<Map<String, dynamic>?> Function(
    String userId);
typedef KnowledgeGraphSupplier = FutureOr<Map<String, dynamic>?> Function(
    String userId);
typedef SearchSupplier = FutureOr<List<String>?> Function(String userId);
typedef RevisionSupplier = FutureOr<int?> Function(String userId);
typedef RecommendationSupplier = FutureOr<String?> Function(String userId);
typedef PlannerSupplier = FutureOr<Map<String, double>?> Function(
    String userId);
typedef AnalyticsSupplier = FutureOr<double?> Function(String userId);

/// Context Assembler gathering unified learner context across all 8 TITAN modules:
/// 1. Identity (User details, exam target)
/// 2. Learning Profile (Weak/strong subjects, topic mastery)
/// 3. Knowledge Graph (Active/recommended concepts)
/// 4. Semantic Search (Recent search queries)
/// 5. Revision (Pending revision count, spaced repetition status)
/// 6. Recommendation (Current AI recommended topic)
/// 7. Planner (Daily study hours target & completed)
/// 8. Analytics (Accuracy rate, performance metrics)
class ContextAssembler {
  final IdentitySupplier? identitySupplier;
  final LearningProfileSupplier? learningProfileSupplier;
  final KnowledgeGraphSupplier? knowledgeGraphSupplier;
  final SearchSupplier? searchSupplier;
  final RevisionSupplier? revisionSupplier;
  final RecommendationSupplier? recommendationSupplier;
  final PlannerSupplier? plannerSupplier;
  final AnalyticsSupplier? analyticsSupplier;

  const ContextAssembler({
    this.identitySupplier,
    this.learningProfileSupplier,
    this.knowledgeGraphSupplier,
    this.searchSupplier,
    this.revisionSupplier,
    this.recommendationSupplier,
    this.plannerSupplier,
    this.analyticsSupplier,
  });

  /// Assembles a unified [MentorContext] combining real-time subsystem data with offline fallbacks.
  Future<MentorContext> assembleContext({
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
    // 1. Identity
    String finalUserName = userName;
    String finalTargetExam = targetExam;
    if (identitySupplier != null) {
      try {
        final idData = await identitySupplier!(userId);
        if (idData != null) {
          finalUserName = idData['userName'] as String? ?? finalUserName;
          finalTargetExam = idData['targetExam'] as String? ?? finalTargetExam;
        }
      } catch (_) {}
    }

    // 2. Learning Profile
    List<String> finalWeak =
        weakSubjects ?? const ['Indian Polity', 'Modern History'];
    List<String> finalStrong = strongSubjects ?? const ['Geography'];
    if (learningProfileSupplier != null) {
      try {
        final lpData = await learningProfileSupplier!(userId);
        if (lpData != null) {
          finalWeak =
              (lpData['weakSubjects'] as List?)?.cast<String>() ?? finalWeak;
          finalStrong = (lpData['strongSubjects'] as List?)?.cast<String>() ??
              finalStrong;
        }
      } catch (_) {}
    }

    // 3. Knowledge Graph
    String? finalTopic = recommendedTopic;
    if (knowledgeGraphSupplier != null) {
      try {
        final kgData = await knowledgeGraphSupplier!(userId);
        if (kgData != null) {
          finalTopic = kgData['activeConcept'] as String? ?? finalTopic;
        }
      } catch (_) {}
    }

    // 4. Semantic Search
    List<String> finalQueries =
        recentSearchQueries ?? const ['Fundamental Rights', 'Monsoon'];
    if (searchSupplier != null) {
      try {
        final sData = await searchSupplier!(userId);
        if (sData != null) {
          finalQueries = sData;
        }
      } catch (_) {}
    }

    // 5. Revision
    int finalPending = pendingRevisionsCount;
    if (revisionSupplier != null) {
      try {
        final revData = await revisionSupplier!(userId);
        if (revData != null) {
          finalPending = revData;
        }
      } catch (_) {}
    }

    // 6. Recommendation
    if (recommendationSupplier != null) {
      try {
        final recTopic = await recommendationSupplier!(userId);
        if (recTopic != null) {
          finalTopic = recTopic;
        }
      } catch (_) {}
    }

    // 7. Planner
    double finalTargetHours = studyHoursTarget;
    double finalCompletedHours = studyHoursCompleted;
    if (plannerSupplier != null) {
      try {
        final pData = await plannerSupplier!(userId);
        if (pData != null) {
          finalTargetHours = pData['target'] ?? finalTargetHours;
          finalCompletedHours = pData['completed'] ?? finalCompletedHours;
        }
      } catch (_) {}
    }

    // 8. Analytics
    double finalAccuracy = accuracyRate;
    if (analyticsSupplier != null) {
      try {
        final aData = await analyticsSupplier!(userId);
        if (aData != null) {
          finalAccuracy = aData;
        }
      } catch (_) {}
    }

    final metadata = Map<String, dynamic>.from(additionalMetadata ?? {});
    metadata['assembledModules'] = const [
      'Identity',
      'Learning Profile',
      'Knowledge Graph',
      'Semantic Search',
      'Revision',
      'Recommendation',
      'Planner',
      'Analytics',
    ];

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
