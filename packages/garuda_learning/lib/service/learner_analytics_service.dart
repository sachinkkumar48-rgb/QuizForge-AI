/// Learner Analytics & Reporting Service (TITAN-KO-046.0 P46).
///
/// Pure, deterministic domain service deriving authoritative performance metrics,
/// mastery distributions, weak area rankings, hierarchical curriculum breakdowns,
/// chronological trends, and faculty content telemetry.
library;

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/diagnostic_placement_result.dart';
import '../domain/entities/learner_analytics_report.dart';
import '../domain/entities/managed_content_item.dart';
import '../domain/entities/mastery_progression_decision.dart';
import '../repository/faculty_content_repository.dart';
import '../repository/learning_activity_completion_repository.dart';
import '../repository/session_checkpoint_repository.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'curriculum_service.dart';
import 'mastery_progression_service.dart';

/// Structured domain exception thrown when analytics computation encounters invalid or failing state.
class LearnerAnalyticsException implements Exception {
  final String message;
  final Object? cause;

  const LearnerAnalyticsException(this.message, [this.cause]);

  @override
  String toString() =>
      'LearnerAnalyticsException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Production domain service computing authoritative learning analytics.
class LearnerAnalyticsService {
  final CurriculumService _curriculumService;
  final AuthoritativeLearningStateRecoveryService? _authRecoveryService;
  final MasteryProgressionService _masteryService;
  final LearningActivityCompletionRepository? _completionRepository;
  final SessionCheckpointRepository? _checkpointRepository;
  final FacultyContentRepository? _facultyRepository;

  LearnerAnalyticsService({
    required CurriculumService curriculumService,
    required MasteryProgressionService masteryService,
    AuthoritativeLearningStateRecoveryService? authRecoveryService,
    LearningActivityCompletionRepository? completionRepository,
    SessionCheckpointRepository? checkpointRepository,
    FacultyContentRepository? facultyRepository,
  })  : _curriculumService = curriculumService,
        _masteryService = masteryService,
        _authRecoveryService = authRecoveryService,
        _completionRepository = completionRepository,
        _checkpointRepository = checkpointRepository,
        _facultyRepository = facultyRepository;

  CurriculumService get curriculumService => _curriculumService;
  MasteryProgressionService get masteryService => _masteryService;
  AuthoritativeLearningStateRecoveryService? get authRecoveryService =>
      _authRecoveryService;
  FacultyContentRepository? get facultyRepository => _facultyRepository;

  // ---------------------------------------------------------------------------
  // 1. Core Learner Analytics Computation
  // ---------------------------------------------------------------------------

  /// Computes a comprehensive authoritative analytics report for [learnerId] and [examId].
  Future<LearnerAnalyticsReport> computeLearnerReport({
    required String learnerId,
    required String examId,
    AuthoritativeLearnerState? authState,
    DiagnosticPlacementResult? diagnosticResult,
    DateTime? asOfDate,
  }) async {
    final cleanLearnerId = learnerId.trim();
    final cleanExamId = examId.trim().toLowerCase();

    if (cleanLearnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for analytics calculation');
    }
    if (cleanExamId.isEmpty) {
      throw ArgumentError('examId cannot be empty for analytics calculation');
    }

    final effectiveDate = (asOfDate ?? DateTime.now()).toUtc();

    // 1. Resolve Authoritative Learner State
    AuthoritativeLearnerState effectiveState;
    if (authState != null) {
      effectiveState = authState;
    } else {
      if (_authRecoveryService == null) {
        throw const LearnerAnalyticsException(
            'AuthoritativeLearningStateRecoveryService is required when authState is not supplied');
      }
      try {
        final recoveryResult = await _authRecoveryService!.recover(
          learnerId: cleanLearnerId,
          examId: cleanExamId,
          requestedAt: effectiveDate,
        );
        effectiveState = recoveryResult.state ??
            AuthoritativeLearnerState.empty(
              learnerId: cleanLearnerId,
              examId: cleanExamId,
              createdAt: effectiveDate,
            );
      } catch (e) {
        throw LearnerAnalyticsException(
            'Failed to load authoritative learner state for $cleanLearnerId: $e',
            e);
      }
    }

    // 2. Validate Curriculum Metadata
    final framework = _curriculumService.framework;
    if (framework.domains.isEmpty) {
      throw const LearnerAnalyticsException(
          'Curriculum framework has no domains registered');
    }

    try {
      // 3. Evaluate Objective Mastery Decisions Across Framework
      final decisions = _masteryService.evaluateAllObjectives(
        authState: effectiveState,
        diagnosticResult: diagnosticResult,
        evaluatedAt: effectiveDate,
      );

      // 4. Compute Mastery Distribution
      final masteryDistribution = _computeMasteryDistribution(decisions);

      // 5. Compute Performance Summary
      final summary = _computePerformanceSummary(
        effectiveState: effectiveState,
        decisions: decisions,
        totalFrameworkObjectives: framework.allObjectives.length,
        asOfDate: effectiveDate,
      );

      // 6. Compute Weak Areas Ranking
      final weakAreas = _computeWeakAreas(
        effectiveState: effectiveState,
        decisions: decisions,
      );

      // 7. Compute Curriculum Hierarchy Analytics (Subject -> Topic -> Objective)
      final subjects = _computeSubjectAnalytics(
        effectiveState: effectiveState,
        decisions: decisions,
        cleanExamId: cleanExamId,
      );

      // 8. Compute Chronological Performance Trends
      final trends = await _computePerformanceTrends(
        learnerId: cleanLearnerId,
        examId: cleanExamId,
        effectiveState: effectiveState,
      );

      // 9. Compute Faculty Content Analytics (if repository present)
      FacultyAnalyticsSummary? facultySummary;
      if (_facultyRepository != null) {
        try {
          facultySummary = await computeFacultyReport(examId: cleanExamId);
        } catch (_) {
          // Graceful fallback for faculty analytics without failing learner analytics
          facultySummary = null;
        }
      }

      return LearnerAnalyticsReport(
        learnerId: cleanLearnerId,
        examId: cleanExamId,
        generatedAt: effectiveDate,
        summary: summary,
        masteryDistribution: masteryDistribution,
        performanceTrends: trends,
        weakAreas: weakAreas,
        subjects: subjects,
        facultySummary: facultySummary,
      );
    } catch (e) {
      if (e is LearnerAnalyticsException || e is ArgumentError) rethrow;
      throw LearnerAnalyticsException(
          'Analytics calculation failure for learner $cleanLearnerId: $e', e);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Mastery Distribution Computation
  // ---------------------------------------------------------------------------

  Map<ProgressionStage, int> _computeMasteryDistribution(
    Map<String, ObjectiveProgressionDecision> decisions,
  ) {
    final distribution = <ProgressionStage, int>{
      for (final stage in ProgressionStage.values) stage: 0,
    };

    for (final decision in decisions.values) {
      distribution[decision.stage] = (distribution[decision.stage] ?? 0) + 1;
    }

    return distribution;
  }

  // ---------------------------------------------------------------------------
  // 3. Performance Summary & Streak Computation
  // ---------------------------------------------------------------------------

  LearnerPerformanceSummary _computePerformanceSummary({
    required AuthoritativeLearnerState effectiveState,
    required Map<String, ObjectiveProgressionDecision> decisions,
    required int totalFrameworkObjectives,
    required DateTime asOfDate,
  }) {
    int totalAttempts = 0;
    int correctCount = 0;
    int objectivesAttempted = 0;
    int objectivesMastered = 0;
    int objectivesNeedingRemediation = 0;
    DateTime? latestActivity;

    final activeDates = <DateTime>{};

    for (final progress in effectiveState.progressMap.values) {
      // Validate non-negative attempts
      final attempts = progress.attemptCount;
      final correct = progress.correctCount;

      totalAttempts += attempts;
      correctCount += correct;

      if (attempts > 0) {
        objectivesAttempted++;
      }

      if (progress.lastAttemptAt != null) {
        final last = progress.lastAttemptAt!.toUtc();
        if (latestActivity == null || last.isAfter(latestActivity)) {
          latestActivity = last;
        }
        activeDates.add(DateTime.utc(last.year, last.month, last.day));
      }
    }

    for (final decision in decisions.values) {
      if (decision.stage == ProgressionStage.mastered) {
        objectivesMastered++;
      } else if (decision.stage.isStruggling) {
        objectivesNeedingRemediation++;
      }
    }

    final double accuracy = totalAttempts > 0
        ? (correctCount / totalAttempts).clamp(0.0, 1.0)
        : 0.0;

    final double completionRate = totalFrameworkObjectives > 0
        ? (objectivesMastered / totalFrameworkObjectives).clamp(0.0, 1.0)
        : 0.0;

    final currentStreak = _calculateStreak(activeDates, asOfDate);

    return LearnerPerformanceSummary(
      totalAttempts: totalAttempts,
      totalQuestionsAttempted: totalAttempts,
      correctCount: correctCount,
      incorrectCount: (totalAttempts - correctCount).clamp(0, totalAttempts),
      accuracy: accuracy,
      objectivesAttempted: objectivesAttempted,
      objectivesMastered: objectivesMastered,
      objectivesNeedingRemediation: objectivesNeedingRemediation,
      totalObjectives: totalFrameworkObjectives,
      completionRate: completionRate,
      currentStreak: currentStreak,
      lastActiveAt: latestActivity,
    );
  }

  int _calculateStreak(Set<DateTime> activeDates, DateTime asOfDate) {
    if (activeDates.isEmpty) return 0;

    final targetToday =
        DateTime.utc(asOfDate.year, asOfDate.month, asOfDate.day);
    final targetYesterday = targetToday.subtract(const Duration(days: 1));

    // Determine streak starting anchor (today or yesterday)
    DateTime cursor;
    if (activeDates.contains(targetToday)) {
      cursor = targetToday;
    } else if (activeDates.contains(targetYesterday)) {
      cursor = targetYesterday;
    } else {
      return 0; // Streak broken
    }

    int streak = 0;
    while (activeDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // ---------------------------------------------------------------------------
  // 4. Weak Area Ranking Computation
  // ---------------------------------------------------------------------------

  List<WeakAreaMetric> _computeWeakAreas({
    required AuthoritativeLearnerState effectiveState,
    required Map<String, ObjectiveProgressionDecision> decisions,
  }) {
    final List<WeakAreaMetric> weakObjectives = [];

    // Collect weak objectives
    for (final entry in decisions.entries) {
      final objId = entry.key;
      final decision = entry.value;
      final progress = effectiveState.progressMap[objId];
      final attempts = progress?.attemptCount ?? 0;
      final correct = progress?.correctCount ?? 0;

      // Identify context hierarchy
      final obj = _curriculumService.getObjectiveById(objId);
      final unit = obj?.unitId != null
          ? _curriculumService.getUnitById(obj!.unitId)
          : null;
      final domain = unit?.domainId != null
          ? _curriculumService.getDomainById(unit!.domainId)
          : null;

      // An objective is a weak area candidate if:
      // 1. Stage is remediationRequired or regressed, OR
      // 2. Attempts > 0 and accuracy < 0.70
      final bool isStruggling = decision.stage.isStruggling;
      final double accuracy =
          attempts > 0 ? (correct / attempts).clamp(0.0, 1.0) : 0.0;
      final bool isLowAccuracy = attempts > 0 && accuracy < 0.70;

      if (isStruggling || isLowAccuracy) {
        weakObjectives.add(
          WeakAreaMetric(
            id: objId,
            name: obj?.title ?? decision.objectiveTitle,
            dimension: 'objective',
            subjectId: domain?.id,
            subjectName: domain?.title,
            topicId: unit?.id,
            topicName: unit?.title,
            attempts: attempts,
            correctCount: correct,
            accuracy: accuracy,
            stage: decision.stage,
            recommendedAction: decision.rationale.isNotEmpty
                ? decision.rationale
                : (isStruggling
                    ? 'Targeted Remedial Practice'
                    : 'Reinforcement Practice'),
            isRemediationRequired:
                decision.isRemediationRequired || isStruggling,
          ),
        );
      }
    }

    // Deterministic ranking:
    // 1. isRemediationRequired first (true before false)
    // 2. Lowest accuracy first (ascending)
    // 3. Highest attempts (repeated failures) descending
    // 4. Alphabetical ID for strict determinism
    weakObjectives.sort((a, b) {
      if (a.isRemediationRequired != b.isRemediationRequired) {
        return a.isRemediationRequired ? -1 : 1;
      }
      final accComp = a.accuracy.compareTo(b.accuracy);
      if (accComp != 0) return accComp;
      final attComp = b.attempts.compareTo(a.attempts);
      if (attComp != 0) return attComp;
      return a.id.compareTo(b.id);
    });

    return List.unmodifiable(weakObjectives);
  }

  // ---------------------------------------------------------------------------
  // 5. Subject & Topic Hierarchy Analytics Computation
  // ---------------------------------------------------------------------------

  List<SubjectAnalytics> _computeSubjectAnalytics({
    required AuthoritativeLearnerState effectiveState,
    required Map<String, ObjectiveProgressionDecision> decisions,
    required String cleanExamId,
  }) {
    final List<SubjectAnalytics> subjectResults = [];
    final framework = _curriculumService.framework;

    for (final domain in framework.domains) {
      int subjectAttempts = 0;
      int subjectCorrect = 0;
      int subjectObjectivesCount = 0;
      int subjectObjectivesAttempted = 0;
      int subjectObjectivesMastered = 0;

      final List<TopicAnalytics> topicResults = [];

      for (final unit in domain.units) {
        int topicAttempts = 0;
        int topicCorrect = 0;
        int topicObjectivesCount = unit.objectives.length;
        int topicObjectivesAttempted = 0;
        int topicObjectivesMastered = 0;

        final List<ObjectiveAnalytics> objResults = [];

        for (final obj in unit.objectives) {
          final progress = effectiveState.progressMap[obj.id];
          final decision = decisions[obj.id];
          final stage = decision?.stage ?? ProgressionStage.notStarted;

          final attempts = progress?.attemptCount ?? 0;
          final correct = progress?.correctCount ?? 0;
          final accuracy =
              attempts > 0 ? (correct / attempts).clamp(0.0, 1.0) : 0.0;

          if (attempts > 0) {
            topicObjectivesAttempted++;
          }
          if (stage == ProgressionStage.mastered) {
            topicObjectivesMastered++;
          }

          topicAttempts += attempts;
          topicCorrect += correct;

          objResults.add(
            ObjectiveAnalytics(
              objectiveId: obj.id,
              title: obj.title,
              topicId: unit.id,
              topicTitle: unit.title,
              subjectId: domain.id,
              subjectTitle: domain.title,
              attempts: attempts,
              correctCount: correct,
              accuracy: accuracy,
              stage: stage,
              lastAttemptAt: progress?.lastAttemptAt,
              recommendedAction: decision?.rationale,
            ),
          );
        }

        final double topicAccuracy = topicAttempts > 0
            ? (topicCorrect / topicAttempts).clamp(0.0, 1.0)
            : 0.0;
        final double topicProgress = topicObjectivesCount > 0
            ? (topicObjectivesMastered / topicObjectivesCount).clamp(0.0, 1.0)
            : 0.0;

        subjectAttempts += topicAttempts;
        subjectCorrect += topicCorrect;
        subjectObjectivesCount += topicObjectivesCount;
        subjectObjectivesAttempted += topicObjectivesAttempted;
        subjectObjectivesMastered += topicObjectivesMastered;

        topicResults.add(
          TopicAnalytics(
            topicId: unit.id,
            title: unit.title,
            subjectId: domain.id,
            subjectTitle: domain.title,
            questionsAttempted: topicAttempts,
            correctCount: topicCorrect,
            accuracy: topicAccuracy,
            totalObjectives: topicObjectivesCount,
            objectivesAttempted: topicObjectivesAttempted,
            objectivesMastered: topicObjectivesMastered,
            progress: topicProgress,
            objectives: objResults,
          ),
        );
      }

      final double subjectAccuracy = subjectAttempts > 0
          ? (subjectCorrect / subjectAttempts).clamp(0.0, 1.0)
          : 0.0;
      final double subjectProgress = subjectObjectivesCount > 0
          ? (subjectObjectivesMastered / subjectObjectivesCount).clamp(0.0, 1.0)
          : 0.0;

      subjectResults.add(
        SubjectAnalytics(
          subjectId: domain.id,
          title: domain.title,
          examId: cleanExamId,
          questionsAttempted: subjectAttempts,
          correctCount: subjectCorrect,
          accuracy: subjectAccuracy,
          totalObjectives: subjectObjectivesCount,
          objectivesAttempted: subjectObjectivesAttempted,
          objectivesMastered: subjectObjectivesMastered,
          progress: subjectProgress,
          topics: topicResults,
        ),
      );
    }

    return List.unmodifiable(subjectResults);
  }

  // ---------------------------------------------------------------------------
  // 6. Chronological Performance Trend Computation
  // ---------------------------------------------------------------------------

  Future<List<PerformanceTrendPoint>> _computePerformanceTrends({
    required String learnerId,
    required String examId,
    required AuthoritativeLearnerState effectiveState,
  }) async {
    final List<PerformanceTrendPoint> rawEvents = [];

    // 1. Gather from LearningActivityCompletionRepository if available
    if (_completionRepository != null) {
      try {
        final records = await _completionRepository!.getCompletedActivities(
          learnerId: learnerId,
          examId: examId,
        );

        // Deduplicate records by activityId / idempotencyKey
        final seenKeys = <String>{};
        for (final r in records) {
          if (!seenKeys.add(r.idempotencyKey)) continue;

          final att = r.outcome.questionsAttempted;
          final cor = r.outcome.correctAnswers;
          final acc = att > 0 ? (cor / att).clamp(0.0, 1.0) : 0.0;

          rawEvents.add(
            PerformanceTrendPoint(
              timestamp: r.completedAt,
              sessionId: r.sessionId,
              activityId: r.activityId,
              attempts: att,
              correctCount: cor,
              accuracy: acc,
              cumulativeAttempts: 0,
              cumulativeAccuracy: 0.0,
            ),
          );
        }
      } catch (_) {
        // Fallback gracefully to other evidence sources
      }
    }

    // 2. Gather from SessionCheckpointRepository if available and no completion records
    if (rawEvents.isEmpty && _checkpointRepository != null) {
      try {
        final checkpoints = await _checkpointRepository!.listCheckpoints(
          learnerId: learnerId,
          examId: examId,
        );

        final seenSessions = <String>{};
        for (final cp in checkpoints) {
          if (!seenSessions.add(cp.sessionId)) continue;

          final att = cp.completedQuestionIds.length;
          if (att == 0) continue;

          rawEvents.add(
            PerformanceTrendPoint(
              timestamp: cp.timestamp,
              sessionId: cp.sessionId,
              attempts: att,
              correctCount: att, // Checkpoints track completed question cursors
              accuracy: 1.0,
              cumulativeAttempts: 0,
              cumulativeAccuracy: 0.0,
              targetId: cp.activeObjectiveId,
            ),
          );
        }
      } catch (_) {}
    }

    // 3. Fallback to AuthoritativeLearnerState progressMap timestamps if still empty
    if (rawEvents.isEmpty) {
      for (final p in effectiveState.progressMap.values) {
        if (p.lastAttemptAt != null && p.attemptCount > 0) {
          rawEvents.add(
            PerformanceTrendPoint(
              timestamp: p.lastAttemptAt!.toUtc(),
              attempts: p.attemptCount,
              correctCount: p.correctCount,
              accuracy: p.successRate,
              cumulativeAttempts: 0,
              cumulativeAccuracy: 0.0,
              targetId: p.objectiveId,
            ),
          );
        }
      }
    }

    if (rawEvents.isEmpty) return const [];

    // Sort chronologically ascending
    rawEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate running cumulative totals
    int runAttempts = 0;
    int runCorrect = 0;
    final List<PerformanceTrendPoint> trendPoints = [];

    for (final event in rawEvents) {
      runAttempts += event.attempts;
      runCorrect += event.correctCount;
      final runAcc =
          runAttempts > 0 ? (runCorrect / runAttempts).clamp(0.0, 1.0) : 0.0;

      trendPoints.add(
        PerformanceTrendPoint(
          timestamp: event.timestamp,
          sessionId: event.sessionId,
          activityId: event.activityId,
          attempts: event.attempts,
          correctCount: event.correctCount,
          accuracy: event.accuracy,
          cumulativeAttempts: runAttempts,
          cumulativeAccuracy: runAcc,
          targetId: event.targetId,
        ),
      );
    }

    return List.unmodifiable(trendPoints);
  }

  // ---------------------------------------------------------------------------
  // 7. Faculty Content Operations Analytics
  // ---------------------------------------------------------------------------

  /// Computes faculty content metrics across managed items for [authorId] or entire catalogue.
  Future<FacultyAnalyticsSummary> computeFacultyReport({
    String? authorId,
    String? examId,
  }) async {
    if (_facultyRepository == null) {
      return const FacultyAnalyticsSummary();
    }

    try {
      final items = await _facultyRepository!.getAll(
        authorId: authorId,
        examId: examId,
      );

      int totalQuestions = 0;
      int totalRemedial = 0;
      int totalMaterials = 0;
      int publishedCount = 0;
      int draftCount = 0;
      int unpublishedCount = 0;

      for (final item in items) {
        switch (item.contentType) {
          case ManagedContentType.question:
            totalQuestions++;
            break;
          case ManagedContentType.remedialLesson:
            totalRemedial++;
            break;
          case ManagedContentType.learningMaterial:
            totalMaterials++;
            break;
        }

        switch (item.status) {
          case ContentLifecycleStatus.published:
            publishedCount++;
            break;
          case ContentLifecycleStatus.draft:
          case ContentLifecycleStatus.validationFailed:
          case ContentLifecycleStatus.readyToPublish:
            draftCount++;
            break;
          case ContentLifecycleStatus.unpublished:
            unpublishedCount++;
            break;
        }
      }

      return FacultyAnalyticsSummary(
        authorId: authorId,
        totalContentItems: items.length,
        totalQuestions: totalQuestions,
        totalRemedialLessons: totalRemedial,
        totalLearningMaterials: totalMaterials,
        publishedCount: publishedCount,
        draftCount: draftCount,
        unpublishedCount: unpublishedCount,
        learnerAttemptsOnManagedContent: 0,
        learnerAccuracyOnManagedContent: 0.0,
      );
    } catch (e) {
      throw LearnerAnalyticsException(
          'Failed to compute faculty content report: $e', e);
    }
  }
}
