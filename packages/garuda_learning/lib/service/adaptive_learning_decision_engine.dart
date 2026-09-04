/// Adaptive Learning Decision Engine Service (TITAN-KO-041.0 P41).
///
/// Deterministic pedagogical reasoning engine that synthesizes authoritative learner
/// state, session checkpoints, and curriculum frameworks to decide the optimal next
/// learning action with machine-readable evidence and auditable decision traces.
library;

import '../domain/entities/adaptive_decision_policy.dart';
import '../domain/entities/adaptive_learning_decision.dart';
import '../domain/entities/adaptive_practice_session_config.dart';
import '../domain/entities/adaptive_question_selection_config.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/curriculum_framework.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_continuation_plan.dart';
import '../domain/entities/remedial_lesson.dart';
import '../domain/entities/resumable_learning_session.dart';
import '../domain/entities/resumable_session_status.dart';
import '../domain/entities/review_item.dart';
import '../domain/entities/session_checkpoint.dart';

/// Core decision engine orchestrating deterministic pedagogical decision making.
class AdaptiveLearningDecisionEngine {
  /// Default policy governing threshold evaluations and priority ordering.
  final AdaptiveDecisionPolicy defaultPolicy;

  AdaptiveLearningDecisionEngine({
    AdaptiveDecisionPolicy? policy,
  }) : defaultPolicy = policy ?? AdaptiveDecisionPolicy.standard;

  /// Evaluates learner progress, active sessions, and curriculum structure to produce
  /// an immutable, revision-anchored [AdaptiveLearningDecision].
  AdaptiveLearningDecision evaluate({
    required AuthoritativeLearnerState authoritativeState,
    SessionCheckpoint? activeCheckpoint,
    ResumableLearningSession? activeSession,
    CurriculumFramework? framework,
    List<ReviewItem>? reviewItems,
    List<RemedialLesson>? availableRemedialLessons,
    DateTime? asOfDate,
    AdaptiveDecisionPolicy? overridePolicy,
  }) {
    final policy = overridePolicy ?? defaultPolicy;
    final effectiveAsOf =
        (asOfDate ?? authoritativeState.lastUpdatedAt).toUtc();

    // Multi-tenant validation
    if (activeCheckpoint != null) {
      if (activeCheckpoint.learnerId != authoritativeState.learnerId ||
          activeCheckpoint.examId != authoritativeState.examId) {
        throw ArgumentError(
          'Tenant mismatch: state (${authoritativeState.learnerId}:${authoritativeState.examId}) '
          'vs checkpoint (${activeCheckpoint.learnerId}:${activeCheckpoint.examId})',
        );
      }
    }

    if (activeSession != null) {
      if (activeSession.learnerId != authoritativeState.learnerId ||
          activeSession.examId != authoritativeState.examId) {
        throw ArgumentError(
          'Tenant mismatch: state (${authoritativeState.learnerId}:${authoritativeState.examId}) '
          'vs session (${activeSession.learnerId}:${activeSession.examId})',
        );
      }
    }

    if (activeCheckpoint != null &&
        activeSession != null &&
        activeCheckpoint.sessionId != activeSession.sessionId) {
      throw ArgumentError(
        'Session ID mismatch: checkpoint (${activeCheckpoint.sessionId}) '
        'vs session (${activeSession.sessionId})',
      );
    }

    final steps = <DecisionTraceStep>[];
    int stepIndex = 0;

    for (final decisionType in policy.priorityOrder) {
      stepIndex++;

      switch (decisionType) {
        case LearningDecisionType.continuation:
          final match = _evaluateContinuation(
            stepIndex: stepIndex,
            activeCheckpoint: activeCheckpoint,
            activeSession: activeSession,
            authoritativeState: authoritativeState,
            effectiveAsOf: effectiveAsOf,
            steps: steps,
          );
          if (match != null) return match;
          break;

        case LearningDecisionType.remediation:
          final match = _evaluateRemediation(
            stepIndex: stepIndex,
            policy: policy,
            authoritativeState: authoritativeState,
            availableRemedialLessons: availableRemedialLessons,
            effectiveAsOf: effectiveAsOf,
            steps: steps,
          );
          if (match != null) return match;
          break;

        case LearningDecisionType.review:
          final match = _evaluateReview(
            stepIndex: stepIndex,
            policy: policy,
            authoritativeState: authoritativeState,
            reviewItems: reviewItems,
            effectiveAsOf: effectiveAsOf,
            steps: steps,
          );
          if (match != null) return match;
          break;

        case LearningDecisionType.reinforcement:
          final match = _evaluateReinforcement(
            stepIndex: stepIndex,
            policy: policy,
            authoritativeState: authoritativeState,
            effectiveAsOf: effectiveAsOf,
            steps: steps,
          );
          if (match != null) return match;
          break;

        case LearningDecisionType.advancement:
          final match = _evaluateAdvancement(
            stepIndex: stepIndex,
            framework: framework,
            authoritativeState: authoritativeState,
            effectiveAsOf: effectiveAsOf,
            steps: steps,
          );
          if (match != null) return match;
          break;

        case LearningDecisionType.complete:
          final match = _evaluateComplete(
            stepIndex: stepIndex,
            authoritativeState: authoritativeState,
            effectiveAsOf: effectiveAsOf,
            steps: steps,
          );
          if (match != null) return match;
          break;
      }
    }

    // Default fallback to complete if priorityOrder is exhausted without matches
    return _createDecision(
      type: LearningDecisionType.complete,
      priority: LearningDecisionPriority.none,
      reason:
          'All evaluation policies evaluated with no actionable targets; marking complete.',
      target: LearningTarget.none,
      evidence: LearningDecisionEvidence(
        authoritativeStateRevision: authoritativeState.revision,
        notes: const ['Fallback evaluation to complete'],
      ),
      authoritativeState: authoritativeState,
      effectiveAsOf: effectiveAsOf,
      steps: steps,
      summary: 'Curriculum complete (fallback)',
    );
  }

  /// Formulates an actionable continuation plan from an existing decision.
  LearningContinuationPlan formulateContinuationPlan({
    required AdaptiveLearningDecision decision,
    ResumableLearningSession? resumableSession,
    RemedialLesson? remedialLesson,
    AdaptiveQuestionSelectionConfig? selectionConfig,
    AdaptivePracticeSessionConfig? sessionConfig,
    DateTime? createdAt,
  }) {
    final effectiveCreatedAt = (createdAt ?? decision.decidedAt).toUtc();
    final planId = 'plan_${decision.decisionId}';

    return LearningContinuationPlan(
      planId: planId,
      decision: decision,
      target: decision.target,
      selectionConfig: selectionConfig,
      sessionConfig: sessionConfig,
      remedialLesson: remedialLesson,
      resumableSession: resumableSession,
      createdAt: effectiveCreatedAt,
    );
  }

  /// Convenience pipeline method evaluating the state and returning the formulated plan.
  LearningContinuationPlan evaluateAndPlan({
    required AuthoritativeLearnerState authoritativeState,
    SessionCheckpoint? activeCheckpoint,
    ResumableLearningSession? activeSession,
    CurriculumFramework? framework,
    List<ReviewItem>? reviewItems,
    List<RemedialLesson>? availableRemedialLessons,
    DateTime? asOfDate,
    AdaptiveDecisionPolicy? overridePolicy,
  }) {
    final decision = evaluate(
      authoritativeState: authoritativeState,
      activeCheckpoint: activeCheckpoint,
      activeSession: activeSession,
      framework: framework,
      reviewItems: reviewItems,
      availableRemedialLessons: availableRemedialLessons,
      asOfDate: asOfDate,
      overridePolicy: overridePolicy,
    );

    // Resolve attached remedial lesson if applicable
    RemedialLesson? matchingLesson;
    if (decision.type == LearningDecisionType.remediation &&
        availableRemedialLessons != null &&
        decision.target.objectiveId != null) {
      for (final lesson in availableRemedialLessons) {
        if (lesson.objectiveId == decision.target.objectiveId) {
          matchingLesson = lesson;
          break;
        }
      }
    }

    return formulateContinuationPlan(
      decision: decision,
      resumableSession: activeSession,
      remedialLesson: matchingLesson,
      createdAt: decision.decidedAt,
    );
  }

  // --- PRIVATE EVALUATION HELPERS ---

  AdaptiveLearningDecision? _evaluateContinuation({
    required int stepIndex,
    required SessionCheckpoint? activeCheckpoint,
    required ResumableLearningSession? activeSession,
    required AuthoritativeLearnerState authoritativeState,
    required DateTime effectiveAsOf,
    required List<DecisionTraceStep> steps,
  }) {
    final hasUnfinishedCheckpoint =
        activeCheckpoint != null && !activeCheckpoint.isCompleted;

    final hasUnfinishedSession = activeSession != null &&
        !activeSession.status.isTerminal &&
        activeSession.status != ResumableSessionStatus.completed;

    if (!hasUnfinishedCheckpoint && !hasUnfinishedSession) {
      steps.add(
        DecisionTraceStep(
          stepIndex: stepIndex,
          policy: LearningDecisionType.continuation,
          ruleName: 'active_session_continuation',
          isMatched: false,
          reason:
              'No active, interrupted, or unfinished learning session detected.',
          evaluatedMetrics: {
            'hasCheckpoint': activeCheckpoint != null,
            'isCheckpointCompleted': activeCheckpoint?.isCompleted ?? false,
            'hasSession': activeSession != null,
            'sessionStatus': activeSession?.status.name,
          },
        ),
      );
      return null;
    }

    // Determine resumption coordinates
    final String sessionId;
    final int cursorIndex;
    final String? objectiveId;
    final int? checkpointRev;

    if (activeCheckpoint != null) {
      sessionId = activeCheckpoint.sessionId;
      cursorIndex = activeCheckpoint.questionIndex;
      objectiveId = activeCheckpoint.activeObjectiveId;
      checkpointRev = activeCheckpoint.checkpointRevision;
    } else {
      sessionId = activeSession!.sessionId;
      cursorIndex = activeSession.currentQuestionIndex;
      objectiveId = activeSession.currentObjectiveId;
      checkpointRev = activeSession.lastPersistedRevision;
    }

    final reason =
        'Active learning session $sessionId is interrupted at question cursor $cursorIndex and requires continuation.';

    steps.add(
      DecisionTraceStep(
        stepIndex: stepIndex,
        policy: LearningDecisionType.continuation,
        ruleName: 'active_session_continuation',
        isMatched: true,
        reason: reason,
        evaluatedMetrics: {
          'sessionId': sessionId,
          'cursorIndex': cursorIndex,
          'objectiveId': objectiveId,
          'checkpointRevision': checkpointRev,
        },
      ),
    );

    final target = LearningTarget.sessionCursor(
      sessionId: sessionId,
      cursorIndex: cursorIndex,
      objectiveId: objectiveId,
    );

    final evidence = LearningDecisionEvidence(
      objectiveId: objectiveId,
      authoritativeStateRevision: authoritativeState.revision,
      checkpointRevision: checkpointRev,
      activeSessionId: sessionId,
      hasUnfinishedSession: true,
      notes: [reason],
    );

    return _createDecision(
      type: LearningDecisionType.continuation,
      priority: LearningDecisionPriority.urgent,
      reason: reason,
      target: target,
      evidence: evidence,
      authoritativeState: authoritativeState,
      checkpointRevision: checkpointRev,
      effectiveAsOf: effectiveAsOf,
      steps: steps,
      summary: 'Resuming active session $sessionId at cursor $cursorIndex',
    );
  }

  AdaptiveLearningDecision? _evaluateRemediation({
    required int stepIndex,
    required AdaptiveDecisionPolicy policy,
    required AuthoritativeLearnerState authoritativeState,
    required List<RemedialLesson>? availableRemedialLessons,
    required DateTime effectiveAsOf,
    required List<DecisionTraceStep> steps,
  }) {
    final candidates = <LearnerProgress>[];

    for (final progress in authoritativeState.progressMap.values) {
      if (progress.attemptCount >= policy.remediationMinAttempts &&
          progress.successRate < policy.remediationSuccessRateThreshold) {
        candidates.add(progress);
      }
    }

    if (candidates.isEmpty) {
      steps.add(
        DecisionTraceStep(
          stepIndex: stepIndex,
          policy: LearningDecisionType.remediation,
          ruleName: 'material_weakness_remediation',
          isMatched: false,
          reason:
              'Zero objectives met remediation criteria (attemptCount >= ${policy.remediationMinAttempts}, successRate < ${policy.remediationSuccessRateThreshold}).',
          evaluatedMetrics: {
            'totalObjectivesEvaluated': authoritativeState.progressMap.length,
            'minAttemptsThreshold': policy.remediationMinAttempts,
            'successRateThreshold': policy.remediationSuccessRateThreshold,
          },
        ),
      );
      return null;
    }

    // Deterministic candidate sorting: lowest success rate first, then highest attempts, then objectiveId
    candidates.sort((a, b) {
      final rateComp = a.successRate.compareTo(b.successRate);
      if (rateComp != 0) return rateComp;
      final attemptComp = b.attemptCount.compareTo(a.attemptCount);
      if (attemptComp != 0) return attemptComp;
      return a.objectiveId.compareTo(b.objectiveId);
    });

    final targetProgress = candidates.first;

    // Check if an explicit remedial lesson exists
    RemedialLesson? matchingLesson;
    if (availableRemedialLessons != null) {
      for (final lesson in availableRemedialLessons) {
        if (lesson.objectiveId == targetProgress.objectiveId) {
          matchingLesson = lesson;
          break;
        }
      }
    }

    final reason =
        'Learner has low success rate (${(targetProgress.successRate * 100).toStringAsFixed(1)}%) '
        'across ${targetProgress.attemptCount} attempts on objective ${targetProgress.objectiveId}, '
        'triggering concept remediation.';

    steps.add(
      DecisionTraceStep(
        stepIndex: stepIndex,
        policy: LearningDecisionType.remediation,
        ruleName: 'material_weakness_remediation',
        isMatched: true,
        reason: reason,
        evaluatedMetrics: {
          'objectiveId': targetProgress.objectiveId,
          'attemptCount': targetProgress.attemptCount,
          'correctCount': targetProgress.correctCount,
          'successRate': targetProgress.successRate,
          'boundLessonId': matchingLesson?.lessonId,
        },
      ),
    );

    final target = matchingLesson != null
        ? LearningTarget.remedialLesson(
            lessonId: matchingLesson.lessonId,
            objectiveId: targetProgress.objectiveId,
          )
        : LearningTarget.objective(
            objectiveId: targetProgress.objectiveId,
            type: LearningTargetType.remedialLesson,
          );

    final evidence = LearningDecisionEvidence(
      objectiveId: targetProgress.objectiveId,
      masteryScore: targetProgress.successRate,
      attemptCount: targetProgress.attemptCount,
      correctCount: targetProgress.correctCount,
      successRate: targetProgress.successRate,
      confidence: 1.0,
      lastPracticedAt: targetProgress.lastAttemptAt,
      authoritativeStateRevision: authoritativeState.revision,
      notes: [reason],
    );

    return _createDecision(
      type: LearningDecisionType.remediation,
      priority: LearningDecisionPriority.urgent,
      reason: reason,
      target: target,
      evidence: evidence,
      authoritativeState: authoritativeState,
      effectiveAsOf: effectiveAsOf,
      steps: steps,
      summary: 'Concept remediation on ${targetProgress.objectiveId}',
    );
  }

  AdaptiveLearningDecision? _evaluateReview({
    required int stepIndex,
    required AdaptiveDecisionPolicy policy,
    required AuthoritativeLearnerState authoritativeState,
    required List<ReviewItem>? reviewItems,
    required DateTime effectiveAsOf,
    required List<DecisionTraceStep> steps,
  }) {
    String? selectedObjectiveId;
    int? daysSinceReview;

    if (reviewItems != null && reviewItems.isNotEmpty) {
      final dueItems = reviewItems
          .where((item) => item.isDue(asOfDate: effectiveAsOf))
          .toList();

      if (dueItems.isNotEmpty) {
        dueItems.sort((a, b) {
          final pA = a.priorityScore(asOfDate: effectiveAsOf);
          final pB = b.priorityScore(asOfDate: effectiveAsOf);
          final pComp = pB.compareTo(pA); // higher priority first
          if (pComp != 0) return pComp;
          return a.objectiveId.compareTo(b.objectiveId);
        });

        final top = dueItems.first;
        selectedObjectiveId = top.objectiveId;
        if (top.lastReviewed != null) {
          daysSinceReview = effectiveAsOf.difference(top.lastReviewed!).inDays;
        }
      }
    }

    // Fallback to authoritative state achievement date if explicit reviewItems not provided
    if (selectedObjectiveId == null) {
      final candidates = <LearnerProgress>[];

      for (final progress in authoritativeState.progressMap.values) {
        if (progress.isAchieved && progress.lastAttemptAt != null) {
          final elapsedDays =
              effectiveAsOf.difference(progress.lastAttemptAt!).inDays;
          if (elapsedDays >= policy.reviewIntervalDays) {
            candidates.add(progress);
          }
        }
      }

      if (candidates.isNotEmpty) {
        candidates.sort((a, b) {
          final dateComp = a.lastAttemptAt!.compareTo(b.lastAttemptAt!);
          if (dateComp != 0) return dateComp; // oldest attempt first
          return a.objectiveId.compareTo(b.objectiveId);
        });

        final top = candidates.first;
        selectedObjectiveId = top.objectiveId;
        daysSinceReview = effectiveAsOf.difference(top.lastAttemptAt!).inDays;
      }
    }

    if (selectedObjectiveId == null) {
      steps.add(
        DecisionTraceStep(
          stepIndex: stepIndex,
          policy: LearningDecisionType.review,
          ruleName: 'spaced_repetition_review',
          isMatched: false,
          reason:
              'Zero mastered objectives are currently due for spaced review.',
          evaluatedMetrics: {
            'reviewIntervalDays': policy.reviewIntervalDays,
            'reviewItemsTracked': reviewItems?.length ?? 0,
          },
        ),
      );
      return null;
    }

    final reason =
        'Objective $selectedObjectiveId is due for spaced repetition review to preserve long-term retention.';

    steps.add(
      DecisionTraceStep(
        stepIndex: stepIndex,
        policy: LearningDecisionType.review,
        ruleName: 'spaced_repetition_review',
        isMatched: true,
        reason: reason,
        evaluatedMetrics: {
          'objectiveId': selectedObjectiveId,
          'daysSinceReview': daysSinceReview,
        },
      ),
    );

    final target = LearningTarget.objective(
      objectiveId: selectedObjectiveId,
      type: LearningTargetType.reviewObjective,
    );

    final progress = authoritativeState.progressMap[selectedObjectiveId];

    final evidence = LearningDecisionEvidence(
      objectiveId: selectedObjectiveId,
      masteryScore: progress?.successRate ?? 1.0,
      attemptCount: progress?.attemptCount ?? 0,
      correctCount: progress?.correctCount ?? 0,
      successRate: progress?.successRate ?? 1.0,
      lastPracticedAt: progress?.lastAttemptAt,
      daysSinceReview: daysSinceReview,
      authoritativeStateRevision: authoritativeState.revision,
      notes: [reason],
    );

    return _createDecision(
      type: LearningDecisionType.review,
      priority: LearningDecisionPriority.high,
      reason: reason,
      target: target,
      evidence: evidence,
      authoritativeState: authoritativeState,
      effectiveAsOf: effectiveAsOf,
      steps: steps,
      summary: 'Spaced review on $selectedObjectiveId',
    );
  }

  AdaptiveLearningDecision? _evaluateReinforcement({
    required int stepIndex,
    required AdaptiveDecisionPolicy policy,
    required AuthoritativeLearnerState authoritativeState,
    required DateTime effectiveAsOf,
    required List<DecisionTraceStep> steps,
  }) {
    final candidates = <LearnerProgress>[];

    for (final progress in authoritativeState.progressMap.values) {
      // In-progress: attempted at least once, but not achieved
      if (progress.attemptCount >= 1 &&
          !progress.isAchieved &&
          progress.status != LearnerObjectiveStatus.achieved) {
        candidates.add(progress);
      }
    }

    if (candidates.isEmpty) {
      steps.add(
        DecisionTraceStep(
          stepIndex: stepIndex,
          policy: LearningDecisionType.reinforcement,
          ruleName: 'in_progress_reinforcement',
          isMatched: false,
          reason:
              'Zero objectives are currently in progress needing reinforcement.',
          evaluatedMetrics: {
            'totalObjectives': authoritativeState.progressMap.length,
          },
        ),
      );
      return null;
    }

    // Deterministic sort: lowest success rate first, then highest attempts, then objectiveId
    candidates.sort((a, b) {
      final rateComp = a.successRate.compareTo(b.successRate);
      if (rateComp != 0) return rateComp;
      final attComp = b.attemptCount.compareTo(a.attemptCount);
      if (attComp != 0) return attComp;
      return a.objectiveId.compareTo(b.objectiveId);
    });

    final targetProgress = candidates.first;
    final reason = 'Objective ${targetProgress.objectiveId} is in progress '
        '(${targetProgress.attemptCount} attempts, ${(targetProgress.successRate * 100).toStringAsFixed(1)}% success) '
        'requiring reinforcement to reach mastery.';

    steps.add(
      DecisionTraceStep(
        stepIndex: stepIndex,
        policy: LearningDecisionType.reinforcement,
        ruleName: 'in_progress_reinforcement',
        isMatched: true,
        reason: reason,
        evaluatedMetrics: {
          'objectiveId': targetProgress.objectiveId,
          'attemptCount': targetProgress.attemptCount,
          'successRate': targetProgress.successRate,
        },
      ),
    );

    final target = LearningTarget.objective(
      objectiveId: targetProgress.objectiveId,
      type: LearningTargetType.practiceObjective,
    );

    final evidence = LearningDecisionEvidence(
      objectiveId: targetProgress.objectiveId,
      masteryScore: targetProgress.successRate,
      attemptCount: targetProgress.attemptCount,
      correctCount: targetProgress.correctCount,
      successRate: targetProgress.successRate,
      lastPracticedAt: targetProgress.lastAttemptAt,
      authoritativeStateRevision: authoritativeState.revision,
      notes: [reason],
    );

    return _createDecision(
      type: LearningDecisionType.reinforcement,
      priority: LearningDecisionPriority.medium,
      reason: reason,
      target: target,
      evidence: evidence,
      authoritativeState: authoritativeState,
      effectiveAsOf: effectiveAsOf,
      steps: steps,
      summary: 'Mastery reinforcement on ${targetProgress.objectiveId}',
    );
  }

  AdaptiveLearningDecision? _evaluateAdvancement({
    required int stepIndex,
    required CurriculumFramework? framework,
    required AuthoritativeLearnerState authoritativeState,
    required DateTime effectiveAsOf,
    required List<DecisionTraceStep> steps,
  }) {
    if (framework != null) {
      for (final obj in framework.allObjectives) {
        final progress = authoritativeState.progressMap[obj.id];
        final isNotAttempted = progress == null ||
            (progress.attemptCount == 0 &&
                progress.status == LearnerObjectiveStatus.notStarted);

        if (isNotAttempted) {
          // Verify prerequisites are satisfied
          final prereqsMet =
              obj.prerequisites.where((p) => p.isMandatory).every((p) {
            final prereqProgress =
                authoritativeState.progressMap[p.prerequisiteObjectiveId];
            return prereqProgress != null && prereqProgress.isAchieved;
          });

          if (prereqsMet) {
            final unit = framework.unitMap[obj.unitId];
            final reason =
                'Advancing learner to next curriculum objective ${obj.id} (${obj.title}).';

            steps.add(
              DecisionTraceStep(
                stepIndex: stepIndex,
                policy: LearningDecisionType.advancement,
                ruleName: 'curriculum_sequence_advancement',
                isMatched: true,
                reason: reason,
                evaluatedMetrics: {
                  'objectiveId': obj.id,
                  'unitId': obj.unitId,
                  'prerequisitesCount': obj.prerequisites.length,
                },
              ),
            );

            final target = LearningTarget.objective(
              objectiveId: obj.id,
              type: LearningTargetType.curriculumObjective,
              topic: unit?.title,
              subject: framework.title,
            );

            final evidence = LearningDecisionEvidence(
              objectiveId: obj.id,
              topic: unit?.title,
              subject: framework.title,
              masteryScore: 0.0,
              attemptCount: 0,
              correctCount: 0,
              successRate: 0.0,
              authoritativeStateRevision: authoritativeState.revision,
              notes: [reason],
            );

            return _createDecision(
              type: LearningDecisionType.advancement,
              priority: LearningDecisionPriority.low,
              reason: reason,
              target: target,
              evidence: evidence,
              authoritativeState: authoritativeState,
              effectiveAsOf: effectiveAsOf,
              steps: steps,
              summary: 'Advancing to next curriculum objective ${obj.id}',
            );
          }
        }
      }
    } else {
      // Framework is absent: check if any unattempted objective exists in state
      final unattempted = authoritativeState.progressMap.values
          .where((p) =>
              p.attemptCount == 0 &&
              p.status == LearnerObjectiveStatus.notStarted)
          .toList();

      if (unattempted.isNotEmpty) {
        unattempted.sort((a, b) => a.objectiveId.compareTo(b.objectiveId));
        final targetProgress = unattempted.first;
        final reason =
            'Advancing learner to unattempted objective ${targetProgress.objectiveId}.';

        steps.add(
          DecisionTraceStep(
            stepIndex: stepIndex,
            policy: LearningDecisionType.advancement,
            ruleName: 'curriculum_sequence_advancement',
            isMatched: true,
            reason: reason,
            evaluatedMetrics: {
              'objectiveId': targetProgress.objectiveId,
            },
          ),
        );

        final target = LearningTarget.objective(
          objectiveId: targetProgress.objectiveId,
          type: LearningTargetType.curriculumObjective,
        );

        final evidence = LearningDecisionEvidence(
          objectiveId: targetProgress.objectiveId,
          authoritativeStateRevision: authoritativeState.revision,
          notes: [reason],
        );

        return _createDecision(
          type: LearningDecisionType.advancement,
          priority: LearningDecisionPriority.low,
          reason: reason,
          target: target,
          evidence: evidence,
          authoritativeState: authoritativeState,
          effectiveAsOf: effectiveAsOf,
          steps: steps,
          summary: 'Advancing to objective ${targetProgress.objectiveId}',
        );
      }
    }

    steps.add(
      DecisionTraceStep(
        stepIndex: stepIndex,
        policy: LearningDecisionType.advancement,
        ruleName: 'curriculum_sequence_advancement',
        isMatched: false,
        reason:
            'Zero new curriculum objectives are currently eligible for advancement.',
        evaluatedMetrics: {
          'hasFramework': framework != null,
          'totalFrameworkObjectives': framework?.allObjectives.length ?? 0,
        },
      ),
    );
    return null;
  }

  AdaptiveLearningDecision? _evaluateComplete({
    required int stepIndex,
    required AuthoritativeLearnerState authoritativeState,
    required DateTime effectiveAsOf,
    required List<DecisionTraceStep> steps,
  }) {
    const reason =
        'All curriculum objectives achieved and zero spaced repetition reviews pending.';

    steps.add(
      const DecisionTraceStep(
        stepIndex: 6,
        policy: LearningDecisionType.complete,
        ruleName: 'curriculum_completion',
        isMatched: true,
        reason: reason,
        evaluatedMetrics: {},
      ),
    );

    final evidence = LearningDecisionEvidence(
      authoritativeStateRevision: authoritativeState.revision,
      notes: const [reason],
    );

    return _createDecision(
      type: LearningDecisionType.complete,
      priority: LearningDecisionPriority.none,
      reason: reason,
      target: LearningTarget.none,
      evidence: evidence,
      authoritativeState: authoritativeState,
      effectiveAsOf: effectiveAsOf,
      steps: steps,
      summary: 'Curriculum complete',
    );
  }

  AdaptiveLearningDecision _createDecision({
    required LearningDecisionType type,
    required LearningDecisionPriority priority,
    required String reason,
    required LearningTarget target,
    required LearningDecisionEvidence evidence,
    required AuthoritativeLearnerState authoritativeState,
    int? checkpointRevision,
    required DateTime effectiveAsOf,
    required List<DecisionTraceStep> steps,
    required String summary,
  }) {
    final decisionId =
        'dec_${authoritativeState.learnerId}_${authoritativeState.examId}_r${authoritativeState.revision}_${type.name}_${effectiveAsOf.millisecondsSinceEpoch}';

    final trace = DecisionTrace(
      traceId: 'trc_$decisionId',
      learnerId: authoritativeState.learnerId,
      examId: authoritativeState.examId,
      authoritativeStateRevision: authoritativeState.revision,
      evaluatedAt: effectiveAsOf,
      steps: steps,
      selectedType: type,
      summary: summary,
    );

    return AdaptiveLearningDecision(
      decisionId: decisionId,
      learnerId: authoritativeState.learnerId,
      examId: authoritativeState.examId,
      type: type,
      priority: priority,
      reason: reason,
      target: target,
      evidence: evidence,
      authoritativeStateRevision: authoritativeState.revision,
      checkpointRevision: checkpointRevision,
      decidedAt: effectiveAsOf,
      trace: trace,
    );
  }
}
