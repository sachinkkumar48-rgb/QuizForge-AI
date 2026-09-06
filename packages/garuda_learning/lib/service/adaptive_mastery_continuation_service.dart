/// Adaptive Mastery Continuation Service (TITAN-KO-044.0 P44).
///
/// Orchestrates the closed-loop transition from activity completion and authoritative
/// learner state reconciliation into objective-level progression analysis, weakness
/// detection, readiness evaluation, and deterministic next-plan formulation.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../domain/entities/adaptive_continuation_feedback.dart';
import '../domain/entities/adaptive_decision_policy.dart';
import '../domain/entities/adaptive_mastery_continuation_request.dart';
import '../domain/entities/adaptive_mastery_continuation_result.dart';
import '../domain/entities/assessment_threshold_config.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/curriculum_framework.dart';
import '../domain/entities/learning_activity_completion_result.dart';
import '../domain/entities/mastery_continuation_audit_trail.dart';
import '../domain/entities/next_learning_action.dart';
import '../domain/entities/objective_mastery_status.dart';
import '../domain/entities/objective_progression_summary.dart';
import '../domain/entities/objective_weakness_detail.dart';
import '../domain/entities/remedial_lesson.dart';
import '../domain/entities/review_item.dart';
import '../repository/adaptive_mastery_continuation_repository.dart';
import '../repository/authoritative_learning_state_repository.dart';
import 'adaptive_learning_decision_engine.dart';
import 'authoritative_learning_state_recovery_service.dart';

/// Production service managing the closed-loop mastery continuation pipeline.
class AdaptiveMasteryContinuationService {
  final AuthoritativeLearningStateRepository _stateRepository;
  final AuthoritativeLearningStateRecoveryService _recoveryService;
  final AdaptiveMasteryContinuationRepository _continuationRepository;
  final AdaptiveLearningDecisionEngine _decisionEngine;
  final AssessmentThresholdConfig _thresholdConfig;
  final AdaptiveDecisionPolicy _policy;

  AdaptiveMasteryContinuationService({
    required AuthoritativeLearningStateRepository stateRepository,
    required AuthoritativeLearningStateRecoveryService recoveryService,
    required AdaptiveMasteryContinuationRepository continuationRepository,
    AdaptiveLearningDecisionEngine? decisionEngine,
    AssessmentThresholdConfig? thresholdConfig,
    AdaptiveDecisionPolicy? policy,
  })  : _stateRepository = stateRepository,
        _recoveryService = recoveryService,
        _continuationRepository = continuationRepository,
        _decisionEngine = decisionEngine ?? AdaptiveLearningDecisionEngine(),
        _thresholdConfig = thresholdConfig ?? const AssessmentThresholdConfig(),
        _policy = policy ?? AdaptiveDecisionPolicy.standard;

  AuthoritativeLearningStateRepository get stateRepository => _stateRepository;
  AdaptiveMasteryContinuationRepository get continuationRepository =>
      _continuationRepository;

  /// Evaluates objective progression, diagnoses weaknesses, calculates readiness,
  /// and deterministically determines the next learning action and plan.
  Future<AdaptiveMasteryContinuationResult> evaluate(
    AdaptiveMasteryContinuationRequest request,
  ) async {
    var auditTrail = const MasteryContinuationAuditTrail.empty();
    final effectiveTs = request.evaluatedAt.toUtc();

    // ------------------------------------------------------------------------
    // Step 1: Precondition & Multi-Tenant Validation
    // ------------------------------------------------------------------------
    if (request.requestId.isEmpty ||
        request.learnerId.isEmpty ||
        request.examId.isEmpty) {
      final error = MasteryContinuationError(
        code: 'preconditionFailed',
        message: 'Request ID, Learner ID, and Exam ID cannot be empty.',
        timestamp: effectiveTs,
      );
      auditTrail = auditTrail.logFailure('requestValidated', details: {
        'error': error.message,
      });
      return AdaptiveMasteryContinuationResult(
        requestId: request.requestId,
        status: AdaptiveMasteryContinuationStatus.invalidRequest,
        auditTrail: auditTrail,
        error: error,
        evaluatedAt: effectiveTs,
      );
    }

    // Completion result tenant validation
    if (request.completionResult != null) {
      final comp = request.completionResult!;
      final compLearner = comp.outcome?.learnerId ??
          comp.resultingAuthoritativeState?.learnerId;
      final compExam =
          comp.outcome?.examId ?? comp.resultingAuthoritativeState?.examId;

      if (compLearner != null &&
          compLearner.isNotEmpty &&
          compLearner != request.learnerId) {
        final error = MasteryContinuationError(
          code: 'tenantMismatch',
          message:
              'Learner mismatch: request (${request.learnerId}) != completion ($compLearner)',
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('tenantValidated', details: {
          'error': error.message,
        });
        return AdaptiveMasteryContinuationResult(
          requestId: request.requestId,
          status: AdaptiveMasteryContinuationStatus.invalidRequest,
          auditTrail: auditTrail,
          error: error,
          evaluatedAt: effectiveTs,
        );
      }

      if (compExam != null &&
          compExam.isNotEmpty &&
          compExam.toLowerCase().trim() != request.examId) {
        final error = MasteryContinuationError(
          code: 'tenantMismatch',
          message:
              'Exam mismatch: request (${request.examId}) != completion ($compExam)',
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('tenantValidated', details: {
          'error': error.message,
        });
        return AdaptiveMasteryContinuationResult(
          requestId: request.requestId,
          status: AdaptiveMasteryContinuationStatus.invalidRequest,
          auditTrail: auditTrail,
          error: error,
          evaluatedAt: effectiveTs,
        );
      }
    }

    // Checkpoint tenant validation
    if (request.activeCheckpoint != null) {
      final chk = request.activeCheckpoint!;
      if (chk.learnerId != request.learnerId ||
          chk.examId.toLowerCase().trim() != request.examId) {
        final error = MasteryContinuationError(
          code: 'tenantMismatch',
          message:
              'Checkpoint tenant mismatch: request (${request.learnerId}:${request.examId}) != checkpoint (${chk.learnerId}:${chk.examId})',
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('tenantValidated', details: {
          'error': error.message,
        });
        return AdaptiveMasteryContinuationResult(
          requestId: request.requestId,
          status: AdaptiveMasteryContinuationStatus.invalidRequest,
          auditTrail: auditTrail,
          error: error,
          evaluatedAt: effectiveTs,
        );
      }
    }

    auditTrail = auditTrail.logSuccess('requestValidated', details: {
      'requestId': request.requestId,
      'learnerId': request.learnerId,
      'examId': request.examId,
    });

    // ------------------------------------------------------------------------
    // Step 2: Authoritative Learner State Resolution
    // ------------------------------------------------------------------------
    AuthoritativeLearnerState authState;
    if (request.currentState != null) {
      authState = request.currentState!;
    } else if (request.completionResult?.resultingAuthoritativeState != null) {
      authState = request.completionResult!.resultingAuthoritativeState!;
    } else {
      final recovery = await _recoveryService.recover(
        learnerId: request.learnerId,
        examId: request.examId,
        requestedAt: effectiveTs,
      );
      if (recovery.state == null) {
        final error = MasteryContinuationError(
          code: 'stateResolutionFailed',
          message:
              'Authoritative learner state not found for "${request.learnerId}:${request.examId}".',
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('stateResolved', details: {
          'error': error.message,
        });
        return AdaptiveMasteryContinuationResult(
          requestId: request.requestId,
          status: AdaptiveMasteryContinuationStatus.invalidRequest,
          auditTrail: auditTrail,
          error: error,
          evaluatedAt: effectiveTs,
        );
      }
      authState = recovery.state!;
    }

    // Direct state tenant validation
    if (authState.learnerId != request.learnerId ||
        authState.examId != request.examId) {
      final error = MasteryContinuationError(
        code: 'tenantMismatch',
        message:
            'Authoritative state tenant (${authState.learnerId}:${authState.examId}) does not match request (${request.learnerId}:${request.examId}).',
        timestamp: effectiveTs,
      );
      auditTrail = auditTrail.logFailure('stateResolved', details: {
        'error': error.message,
      });
      return AdaptiveMasteryContinuationResult(
        requestId: request.requestId,
        status: AdaptiveMasteryContinuationStatus.invalidRequest,
        auditTrail: auditTrail,
        error: error,
        evaluatedAt: effectiveTs,
      );
    }

    auditTrail = auditTrail.logSuccess('stateResolved', details: {
      'revision': authState.revision,
      'trackedObjectivesCount': authState.progressMap.length,
      'stateFingerprint': authState.stateFingerprint,
    });

    // ------------------------------------------------------------------------
    // Step 3: Idempotency Check
    // ------------------------------------------------------------------------
    final activityId = request.completionResult?.activityId;
    final idempotencyKey =
        'mcont_${request.learnerId}_${request.examId}_rev${authState.revision}_${activityId ?? "direct"}';

    final cachedFeedback =
        await _continuationRepository.findByIdempotencyKey(idempotencyKey);
    if (cachedFeedback != null) {
      auditTrail = auditTrail.logSuccess('idempotencyChecked', details: {
        'isIdempotentReplay': true,
        'idempotencyKey': idempotencyKey,
      });

      // Formulate next plan from cached decision
      final plan = _decisionEngine.evaluateAndPlan(
        authoritativeState: authState,
        activeCheckpoint: request.activeCheckpoint,
        activeSession: request.activeSession,
        framework: request.curriculumFramework,
        reviewItems: request.reviewItems,
        availableRemedialLessons: request.availableRemedialLessons,
        asOfDate: effectiveTs,
        overridePolicy: _policy,
      );

      return AdaptiveMasteryContinuationResult(
        requestId: request.requestId,
        status: AdaptiveMasteryContinuationStatus.alreadyEvaluated,
        feedback: cachedFeedback,
        continuationPlan: plan,
        auditTrail: auditTrail,
        evaluatedAt: cachedFeedback.evaluatedAt,
      );
    }

    auditTrail = auditTrail.logSuccess('idempotencyChecked', details: {
      'isIdempotentReplay': false,
      'idempotencyKey': idempotencyKey,
    });

    // ------------------------------------------------------------------------
    // Step 4: Objective-Level Progression Evaluation
    // ------------------------------------------------------------------------
    final objectiveEvidenceDeltas = <String, _ObjectiveDelta>{};

    if (request.completionResult?.evidence?.questionEvidence != null) {
      for (final qEv in request.completionResult!.evidence!.questionEvidence) {
        if (qEv.isAnswered) {
          for (final objId in qEv.objectiveIds) {
            final delta = objectiveEvidenceDeltas.putIfAbsent(
                objId, () => _ObjectiveDelta());
            delta.newAttempts++;
            if (qEv.isCorrect) {
              delta.newCorrect++;
            }
          }
        }
      }
    }

    final progressions = SplayTreeMap<String, ObjectiveProgressionSummary>();
    final demonstrated = <String>[];
    final weaknesses = <ObjectiveWeaknessDetail>[];

    for (final progress in authState.progressMap.values) {
      final objId = progress.objectiveId;
      final delta = objectiveEvidenceDeltas[objId] ?? _ObjectiveDelta();

      final currentAttempts = progress.attemptCount;
      final currentCorrect = progress.correctCount;
      final currentRate = progress.successRate;

      final priorAttempts = math.max(0, currentAttempts - delta.newAttempts);
      final priorCorrect = math.max(0, currentCorrect - delta.newCorrect);
      final priorRate = priorAttempts == 0
          ? 0.0
          : (priorCorrect / priorAttempts).clamp(0.0, 1.0);

      final priorStatus = _classifyStatus(priorAttempts, priorRate);
      final updatedStatus = _classifyStatus(currentAttempts, currentRate,
          priorStatus: priorStatus);

      final transition = _determineTransition(
        priorStatus: priorStatus,
        newStatus: updatedStatus,
        priorRate: priorRate,
        newRate: currentRate,
        deltaAttempts: delta.newAttempts,
      );

      // Confidence: Volume sufficiency (70%) + Performance signal (30%)
      final sufficiency =
          (currentAttempts / _thresholdConfig.minimumAttempts).clamp(0.0, 1.0);
      final confidence =
          ((0.7 * sufficiency) + (0.3 * currentRate)).clamp(0.0, 1.0);

      final rationale = _generateProgressionRationale(
        objId: objId,
        priorStatus: priorStatus,
        newStatus: updatedStatus,
        transition: transition,
        deltaAttempts: delta.newAttempts,
        currentAttempts: currentAttempts,
        currentRate: currentRate,
      );

      final summary = ObjectiveProgressionSummary(
        objectiveId: objId,
        priorStatus: priorStatus,
        newStatus: updatedStatus,
        transitionType: transition,
        priorAttempts: priorAttempts,
        newAttempts: delta.newAttempts,
        totalAttempts: currentAttempts,
        priorCorrect: priorCorrect,
        newCorrect: delta.newCorrect,
        totalCorrect: currentCorrect,
        priorSuccessRate: priorRate,
        newSuccessRate: currentRate,
        confidenceScore: confidence,
        rationale: rationale,
      );

      progressions[objId] = summary;

      if (transition.isPositive || summary.isMastered) {
        demonstrated.add(objId);
      }

      if (summary.isStruggling) {
        final deficiencyScore =
            ((1.0 - currentRate) * sufficiency).clamp(0.0, 1.0);

        String? matchingLessonId;
        if (request.availableRemedialLessons != null) {
          for (final lesson in request.availableRemedialLessons!) {
            if (lesson.objectiveId == objId) {
              matchingLessonId = lesson.lessonId;
              break;
            }
          }
        }

        weaknesses.add(
          ObjectiveWeaknessDetail(
            objectiveId: objId,
            deficiencyScore: deficiencyScore,
            attemptCount: currentAttempts,
            correctCount: currentCorrect,
            successRate: currentRate,
            isRegressed: updatedStatus == ObjectiveMasteryStatus.regressed,
            recommendedRemedialLessonId: matchingLessonId,
            rationale:
                'Objective $objId has deficiency ${(deficiencyScore * 100).toStringAsFixed(1)}% '
                'across $currentAttempts attempts (${(currentRate * 100).toStringAsFixed(1)}% success).',
          ),
        );
      }
    }

    // Deterministic sorting of weak areas: highest deficiency first, then attempts, then objId
    weaknesses.sort((a, b) {
      final dComp = b.deficiencyScore.compareTo(a.deficiencyScore);
      if (dComp != 0) return dComp;
      final aComp = b.attemptCount.compareTo(a.attemptCount);
      if (aComp != 0) return aComp;
      return a.objectiveId.compareTo(b.objectiveId);
    });

    auditTrail = auditTrail.logSuccess('objectivesEvaluated', details: {
      'evaluatedCount': progressions.length,
      'demonstratedCount': demonstrated.length,
      'weaknessCount': weaknesses.length,
    });

    // ------------------------------------------------------------------------
    // Step 5: Overall Readiness & Confidence Calculation
    // ------------------------------------------------------------------------
    double overallReadiness = 0.0;
    double overallConfidence = 0.0;

    if (progressions.isNotEmpty) {
      double readinessSum = 0.0;
      double confidenceSum = 0.0;

      for (final p in progressions.values) {
        confidenceSum += p.confidenceScore;
        final score = p.isMastered
            ? 1.0 * p.confidenceScore
            : p.newSuccessRate * p.confidenceScore;
        readinessSum += score;
      }

      overallConfidence = (confidenceSum / progressions.length).clamp(0.0, 1.0);
      overallReadiness = (readinessSum / progressions.length).clamp(0.0, 1.0);
    }

    auditTrail = auditTrail.logSuccess('readinessComputed', details: {
      'overallReadinessScore': overallReadiness,
      'overallConfidence': overallConfidence,
    });

    // ------------------------------------------------------------------------
    // Step 6: Next Learning Action Determination
    // ------------------------------------------------------------------------
    final NextLearningAction nextAction = _determineNextAction(
      request: request,
      authoritativeState: authState,
      weaknesses: weaknesses,
      progressions: progressions,
      effectiveTs: effectiveTs,
    );

    auditTrail = auditTrail.logSuccess('actionDetermined', details: {
      'actionType': nextAction.actionType.name,
      'priority': nextAction.priority.name,
      'targetObjectiveId': nextAction.targetObjectiveId,
      'rationale': nextAction.rationale,
    });

    // ------------------------------------------------------------------------
    // Step 7: Feedback Contract Synthesis
    // ------------------------------------------------------------------------
    final feedbackId =
        'mcf_${request.learnerId}_${request.examId}_rev${authState.revision}';
    final feedback = AdaptiveContinuationFeedback(
      feedbackId: feedbackId,
      learnerId: request.learnerId,
      examId: request.examId,
      authoritativeRevision: authState.revision,
      evaluatedAt: effectiveTs,
      activityId: activityId,
      sessionId: request.completionResult?.outcome?.sessionId ??
          request.activeCheckpoint?.sessionId,
      overallReadinessScore: overallReadiness,
      overallConfidence: overallConfidence,
      objectiveProgressions: progressions,
      demonstratedCompetencies: demonstrated,
      detectedWeaknesses: weaknesses,
      recommendedAction: nextAction,
      auditTrail: auditTrail,
      idempotencyKey: idempotencyKey,
    );

    await _continuationRepository.saveFeedback(feedback);

    auditTrail = auditTrail.logSuccess('feedbackPersisted', details: {
      'feedbackId': feedbackId,
      'fingerprint': feedback.fingerprint,
    });

    // ------------------------------------------------------------------------
    // Step 8: Closed-Loop Continuation Plan Formulation (P41)
    // ------------------------------------------------------------------------
    final continuationPlan = _decisionEngine.evaluateAndPlan(
      authoritativeState: authState,
      activeCheckpoint: request.activeCheckpoint,
      activeSession: request.activeSession,
      framework: request.curriculumFramework,
      reviewItems: request.reviewItems,
      availableRemedialLessons: request.availableRemedialLessons,
      asOfDate: effectiveTs,
      overridePolicy: _policy,
    );

    auditTrail = auditTrail.logSuccess('planFormulated', details: {
      'planId': continuationPlan.planId,
      'decisionType': continuationPlan.decision.type.name,
    });

    return AdaptiveMasteryContinuationResult(
      requestId: request.requestId,
      status: AdaptiveMasteryContinuationStatus.success,
      feedback: feedback,
      continuationPlan: continuationPlan,
      auditTrail: auditTrail,
      evaluatedAt: effectiveTs,
    );
  }

  /// Convenience entry point directly evaluating from a P43 completion result.
  Future<AdaptiveMasteryContinuationResult> evaluateFromCompletion({
    required String requestId,
    required LearningActivityCompletionResult completionResult,
    CurriculumFramework? curriculumFramework,
    List<ReviewItem>? reviewItems,
    List<RemedialLesson>? availableRemedialLessons,
    DateTime? evaluatedAt,
    Map<String, dynamic>? options,
  }) {
    final req = AdaptiveMasteryContinuationRequest.fromCompletion(
      requestId: requestId,
      completionResult: completionResult,
      curriculumFramework: curriculumFramework,
      reviewItems: reviewItems,
      availableRemedialLessons: availableRemedialLessons,
      evaluatedAt: evaluatedAt,
      options: options,
    );
    return evaluate(req);
  }

  // --------------------------------------------------------------------------
  // Private Classification & Decision Helpers
  // --------------------------------------------------------------------------

  ObjectiveMasteryStatus _classifyStatus(
    int attempts,
    double successRate, {
    ObjectiveMasteryStatus? priorStatus,
  }) {
    if (attempts == 0) {
      return ObjectiveMasteryStatus.notAttempted;
    }
    if (attempts >= _policy.remediationMinAttempts &&
        successRate < _policy.remediationSuccessRateThreshold) {
      return ObjectiveMasteryStatus.remediationRequired;
    }
    if (attempts < _thresholdConfig.minimumAttempts) {
      return ObjectiveMasteryStatus.insufficientEvidence;
    }
    if (priorStatus == ObjectiveMasteryStatus.mastered && successRate < 0.70) {
      return ObjectiveMasteryStatus.regressed;
    }
    if (successRate >= _thresholdConfig.minimumSuccessRate) {
      return ObjectiveMasteryStatus.mastered;
    }
    return ObjectiveMasteryStatus.inProgress;
  }

  ObjectiveTransitionType _determineTransition({
    required ObjectiveMasteryStatus priorStatus,
    required ObjectiveMasteryStatus newStatus,
    required double priorRate,
    required double newRate,
    required int deltaAttempts,
  }) {
    if (priorStatus == ObjectiveMasteryStatus.notAttempted) {
      if (newStatus == ObjectiveMasteryStatus.mastered) {
        return ObjectiveTransitionType.mastered;
      }
      return ObjectiveTransitionType.initialAssessment;
    }
    if (priorStatus != ObjectiveMasteryStatus.mastered &&
        newStatus == ObjectiveMasteryStatus.mastered) {
      return ObjectiveTransitionType.mastered;
    }
    if (priorStatus == ObjectiveMasteryStatus.mastered &&
        newStatus == ObjectiveMasteryStatus.mastered) {
      return ObjectiveTransitionType.maintainedMastery;
    }
    if (priorStatus == ObjectiveMasteryStatus.mastered &&
        (newStatus == ObjectiveMasteryStatus.regressed ||
            newStatus == ObjectiveMasteryStatus.remediationRequired)) {
      return ObjectiveTransitionType.regressed;
    }
    if (priorStatus != ObjectiveMasteryStatus.remediationRequired &&
        newStatus == ObjectiveMasteryStatus.remediationRequired) {
      return ObjectiveTransitionType.remediationTriggered;
    }
    if (priorStatus == ObjectiveMasteryStatus.remediationRequired &&
        newStatus != ObjectiveMasteryStatus.remediationRequired) {
      return ObjectiveTransitionType.remediationResolved;
    }
    if (deltaAttempts == 0) {
      return ObjectiveTransitionType.unchanged;
    }
    if (newRate > priorRate) {
      return ObjectiveTransitionType.progressed;
    }
    return ObjectiveTransitionType.unchanged;
  }

  String _generateProgressionRationale({
    required String objId,
    required ObjectiveMasteryStatus priorStatus,
    required ObjectiveMasteryStatus newStatus,
    required ObjectiveTransitionType transition,
    required int deltaAttempts,
    required int currentAttempts,
    required double currentRate,
  }) {
    final pct = (currentRate * 100).toStringAsFixed(1);
    switch (transition) {
      case ObjectiveTransitionType.initialAssessment:
        return 'Initial assessment: recorded $currentAttempts attempts on $objId ($pct% success).';
      case ObjectiveTransitionType.mastered:
        return 'Mastery achieved: exceeded ${_thresholdConfig.minimumAttempts} attempts with $pct% success on $objId.';
      case ObjectiveTransitionType.maintainedMastery:
        return 'Mastery maintained: sustained high performance ($pct%) on $objId.';
      case ObjectiveTransitionType.regressed:
        return 'Regression observed: performance dropped to $pct% on previously mastered objective $objId.';
      case ObjectiveTransitionType.remediationTriggered:
        return 'Remediation triggered: low performance ($pct% < 50%) indicates material weakness on $objId.';
      case ObjectiveTransitionType.remediationResolved:
        return 'Remediation resolved: performance improved to $pct% on $objId.';
      case ObjectiveTransitionType.progressed:
        return 'Progressed: positive performance trajectory ($pct%) observed across $currentAttempts attempts.';
      case ObjectiveTransitionType.unchanged:
        return 'Status unchanged: stable performance ($pct%) across $currentAttempts attempts on $objId.';
    }
  }

  NextLearningAction _determineNextAction({
    required AdaptiveMasteryContinuationRequest request,
    required AuthoritativeLearnerState authoritativeState,
    required List<ObjectiveWeaknessDetail> weaknesses,
    required Map<String, ObjectiveProgressionSummary> progressions,
    required DateTime effectiveTs,
  }) {
    // 1. Unfinished active session (Priority 1: Urgent)
    if (request.activeCheckpoint != null &&
        !request.activeCheckpoint!.isCompleted) {
      final chk = request.activeCheckpoint!;
      return NextLearningAction.continuation(
        sessionId: chk.sessionId,
        cursorIndex: chk.questionIndex,
        objectiveId: chk.activeObjectiveId,
        rationale:
            'Active session ${chk.sessionId} is interrupted at question cursor ${chk.questionIndex}; resuming practice.',
      );
    }

    // 2. Material Weakness / Regression (Priority 2: Urgent)
    if (weaknesses.isNotEmpty) {
      final target = weaknesses.first;
      return NextLearningAction.remediation(
        objectiveId: target.objectiveId,
        remedialLessonId: target.recommendedRemedialLessonId,
        rationale: target.isRegressed
            ? 'Regression detected on objective ${target.objectiveId}; targeted remediation required.'
            : 'Material weakness diagnosed on objective ${target.objectiveId} (${(target.successRate * 100).toStringAsFixed(1)}% success); remediation required.',
      );
    }

    // 3. Spaced Review (Priority 3: High)
    if (request.reviewItems != null && request.reviewItems!.isNotEmpty) {
      final due = request.reviewItems!
          .where((item) => item.isDue(asOfDate: effectiveTs))
          .toList();
      if (due.isNotEmpty) {
        due.sort((a, b) => b
            .priorityScore(asOfDate: effectiveTs)
            .compareTo(a.priorityScore(asOfDate: effectiveTs)));
        final top = due.first;
        return NextLearningAction.review(
          objectiveId: top.objectiveId,
          rationale:
              'Objective ${top.objectiveId} is due for spaced review to prevent memory decay.',
        );
      }
    }

    // 4. In-Progress & Insufficient Evidence Reinforcement (Priority 4: Medium)
    final needsReinforcement = progressions.values
        .where((p) =>
            (p.newStatus == ObjectiveMasteryStatus.inProgress ||
                p.newStatus == ObjectiveMasteryStatus.insufficientEvidence) &&
            !p.isMastered)
        .toList();
    if (needsReinforcement.isNotEmpty) {
      // Sort lowest success rate first, then fewest attempts
      needsReinforcement.sort((a, b) {
        final r = a.newSuccessRate.compareTo(b.newSuccessRate);
        if (r != 0) return r;
        return a.totalAttempts.compareTo(b.totalAttempts);
      });
      final top = needsReinforcement.first;
      return NextLearningAction.reinforcement(
        objectiveId: top.objectiveId,
        rationale: top.newStatus == ObjectiveMasteryStatus.insufficientEvidence
            ? 'Objective ${top.objectiveId} has insufficient evidence (${top.totalAttempts}/${_thresholdConfig.minimumAttempts} attempts); reinforcing to establish statistical confidence.'
            : 'Objective ${top.objectiveId} is in progress (${top.totalAttempts} attempts, ${(top.newSuccessRate * 100).toStringAsFixed(1)}% success); reinforcing towards mastery.',
      );
    }

    // 5. Syllabus Advancement (Priority 5: Low)
    if (request.curriculumFramework != null) {
      for (final unit in request.curriculumFramework!.allUnits) {
        for (final obj in unit.objectives) {
          final progress = authoritativeState.getProgress(obj.id);
          if (progress == null || !progress.isAchieved) {
            // Check prerequisites
            bool prereqsMet = true;
            for (final pre in obj.prerequisiteIds) {
              final preProg = authoritativeState.getProgress(pre);
              if (preProg == null || !preProg.isAchieved) {
                prereqsMet = false;
                break;
              }
            }
            if (prereqsMet) {
              return NextLearningAction.advancement(
                objectiveId: obj.id,
                topic: unit.title,
                rationale:
                    'Prerequisites satisfied; advancing to next curriculum objective ${obj.id} (${obj.title}).',
              );
            }
          }
        }
      }
    }

    // 6. Complete
    return NextLearningAction.complete(
      rationale:
          'All tracked learning objectives have achieved mastery with zero pending reviews.',
    );
  }
}

class _ObjectiveDelta {
  int newAttempts = 0;
  int newCorrect = 0;
}
