/// Learning Activity Completion Service (TITAN-KO-043.0 P43).
///
/// Orchestrates the deterministic finalization boundary for learning activities:
/// validates requests and attempts, normalizes performance into [LearningActivityOutcome],
/// bridges into P36 consolidation and P38/P39 state reconciliation, and enforces dual-layer
/// idempotency and monotonic revision safety.
library;

import 'dart:async';

import '../domain/entities/activity_completion_audit_trail.dart';
import '../domain/entities/activity_outcome_evidence.dart';
import '../domain/entities/adaptive_decision_policy.dart';
import '../domain/entities/attempt_result.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/learning_activity_completion_request.dart';
import '../domain/entities/learning_activity_completion_result.dart';
import '../domain/entities/learning_activity_completion_status.dart';
import '../domain/entities/learning_activity_outcome.dart';
import '../domain/entities/practice_outcome_consolidation.dart';
import '../domain/entities/practice_outcome_evidence.dart';
import '../domain/entities/question_attempt.dart';
import '../domain/entities/reconciliation_pipeline_result.dart';
import '../repository/authoritative_learning_state_repository.dart';
import '../repository/learning_activity_completion_repository.dart';
import 'adaptive_learning_state_reconciliation_pipeline.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'practice_outcome_consolidator.dart';

/// Service coordinating activity completion, normalization, consolidation, and state updates.
class LearningActivityCompletionService {
  final AuthoritativeLearningStateRepository _stateRepository;
  final AuthoritativeLearningStateRecoveryService _recoveryService;
  final AdaptiveLearningStateReconciliationPipeline _reconciliationPipeline;
  final PracticeOutcomeConsolidator _consolidator;
  final LearningActivityCompletionRepository _completionRepository;

  LearningActivityCompletionService({
    required AuthoritativeLearningStateRepository stateRepository,
    required AuthoritativeLearningStateRecoveryService recoveryService,
    required AdaptiveLearningStateReconciliationPipeline reconciliationPipeline,
    PracticeOutcomeConsolidator? consolidator,
    required LearningActivityCompletionRepository completionRepository,
  })  : _stateRepository = stateRepository,
        _recoveryService = recoveryService,
        _reconciliationPipeline = reconciliationPipeline,
        _consolidator = consolidator ?? const PracticeOutcomeConsolidator(),
        _completionRepository = completionRepository;

  /// Exposes the underlying authoritative learner state repository.
  AuthoritativeLearningStateRepository get stateRepository => _stateRepository;

  /// Completes an executed learning activity with deterministic outcome normalization,
  /// evidence synthesis, P36 consolidation, P38/P39 reconciliation, and idempotency protection.
  Future<LearningActivityCompletionResult> completeActivity(
    LearningActivityCompletionRequest request,
  ) async {
    var auditTrail = const ActivityCompletionAuditTrail.empty();
    final effectiveTs = request.completedAt.toUtc();

    // ------------------------------------------------------------------------
    // Step 1: Request & Tenant Validation
    // ------------------------------------------------------------------------
    if (request.requestId.isEmpty ||
        request.learnerId.isEmpty ||
        request.examId.isEmpty ||
        request.activityId.isEmpty ||
        request.planId.isEmpty) {
      final error = ActivityCompletionError(
        code: ActivityCompletionErrorCode.preconditionFailed,
        message: 'Required identifiers cannot be empty.',
        timestamp: effectiveTs,
      );
      auditTrail = auditTrail.logFailure('requestValidated', details: {
        'error': error.message,
      });
      return LearningActivityCompletionResult(
        requestId: request.requestId,
        activityId: request.activityId,
        status: LearningActivityCompletionStatus.invalidRequest,
        auditTrail: auditTrail,
        error: error,
        completedAt: effectiveTs,
      );
    }
    auditTrail = auditTrail.logSuccess('requestValidated', details: {
      'activityId': request.activityId,
      'activityType': request.activityType.name,
      'planId': request.planId,
      'planRevision': request.planRevision,
    });

    // Multi-tenant check against execution state if present
    if (request.executionState != null) {
      final exec = request.executionState!;
      if (exec.learnerId != null &&
          exec.learnerId!.isNotEmpty &&
          exec.learnerId != request.learnerId) {
        final error = ActivityCompletionError(
          code: ActivityCompletionErrorCode.tenantMismatch,
          message:
              'Learner mismatch: request (${request.learnerId}) != executionState (${exec.learnerId})',
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('tenantValidated', details: {
          'error': error.message,
        });
        return LearningActivityCompletionResult(
          requestId: request.requestId,
          activityId: request.activityId,
          status: LearningActivityCompletionStatus.invalidRequest,
          auditTrail: auditTrail,
          error: error,
          completedAt: effectiveTs,
        );
      }
      if (exec.examId.toLowerCase().trim() !=
          request.examId.toLowerCase().trim()) {
        final error = ActivityCompletionError(
          code: ActivityCompletionErrorCode.tenantMismatch,
          message:
              'Exam mismatch: request (${request.examId}) != executionState (${exec.examId})',
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('tenantValidated', details: {
          'error': error.message,
        });
        return LearningActivityCompletionResult(
          requestId: request.requestId,
          activityId: request.activityId,
          status: LearningActivityCompletionStatus.invalidRequest,
          auditTrail: auditTrail,
          error: error,
          completedAt: effectiveTs,
        );
      }
    }
    auditTrail = auditTrail.logSuccess('tenantValidated');

    // ------------------------------------------------------------------------
    // Step 2: Idempotency Guard (Activity-Level)
    // ------------------------------------------------------------------------
    final idempotencyKey = request.resolvedIdempotencyKey;
    final existingRecord =
        await _completionRepository.findByIdempotencyKey(idempotencyKey);

    if (existingRecord != null) {
      // Conflict check: Ensure the existing record belongs to the same tenant and activity
      if (existingRecord.learnerId != request.learnerId ||
          existingRecord.examId != request.examId) {
        final error = ActivityCompletionError(
          code: ActivityCompletionErrorCode.conflictingCompletion,
          message:
              'Idempotency key "$idempotencyKey" exists with different tenant coordinates.',
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('idempotencyChecked', details: {
          'error': error.message,
        });
        return LearningActivityCompletionResult(
          requestId: request.requestId,
          activityId: request.activityId,
          status: LearningActivityCompletionStatus.invalidRequest,
          auditTrail: auditTrail,
          error: error,
          completedAt: effectiveTs,
        );
      }

      auditTrail = auditTrail.logSuccess('idempotencyChecked', details: {
        'isIdempotentReplay': true,
        'idempotencyKey': idempotencyKey,
      });

      // Return cached outcome without re-consolidating or advancing state
      return LearningActivityCompletionResult(
        requestId: request.requestId,
        activityId: request.activityId,
        status: LearningActivityCompletionStatus.alreadyCompleted,
        outcome: existingRecord.outcome,
        resultingAuthoritativeState: request.currentState,
        auditTrail: auditTrail,
        completedAt: existingRecord.completedAt,
      );
    }
    auditTrail = auditTrail.logSuccess('idempotencyChecked', details: {
      'isIdempotentReplay': false,
      'idempotencyKey': idempotencyKey,
    });

    // ------------------------------------------------------------------------
    // Step 3: Authoritative State Resolution & Stale-Plan Protection
    // ------------------------------------------------------------------------
    AuthoritativeLearnerState currentAuthState;
    if (request.currentState != null) {
      currentAuthState = request.currentState!;
    } else {
      final recovery = await _recoveryService.recover(
        learnerId: request.learnerId,
        examId: request.examId,
        requestedAt: effectiveTs,
      );
      if (recovery.state == null) {
        final error = ActivityCompletionError(
          code: ActivityCompletionErrorCode.preconditionFailed,
          message:
              'Failed to resolve authoritative learner state for learner "${request.learnerId}".',
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('stateResolved', details: {
          'error': error.message,
        });
        return LearningActivityCompletionResult(
          requestId: request.requestId,
          activityId: request.activityId,
          status: LearningActivityCompletionStatus.invalidRequest,
          auditTrail: auditTrail,
          error: error,
          completedAt: effectiveTs,
        );
      }
      currentAuthState = recovery.state!;
    }

    // Monotonic revision safety
    if (request.planRevision < currentAuthState.revision) {
      final error = ActivityCompletionError(
        code: ActivityCompletionErrorCode.stalePlan,
        message:
            'Continuation plan revision ${request.planRevision} is stale relative to authoritative state revision ${currentAuthState.revision}.',
        timestamp: effectiveTs,
        details: {
          'planRevision': request.planRevision,
          'currentStateRevision': currentAuthState.revision,
        },
      );
      auditTrail = auditTrail.logFailure('planValidated', details: {
        'error': error.message,
      });
      return LearningActivityCompletionResult(
        requestId: request.requestId,
        activityId: request.activityId,
        status: LearningActivityCompletionStatus.stalePlan,
        auditTrail: auditTrail,
        error: error,
        completedAt: effectiveTs,
      );
    }

    if (request.planRevision > currentAuthState.revision) {
      final error = ActivityCompletionError(
        code: ActivityCompletionErrorCode.futurePlanRevision,
        message:
            'Continuation plan revision ${request.planRevision} is ahead of authoritative state revision ${currentAuthState.revision}.',
        timestamp: effectiveTs,
        details: {
          'planRevision': request.planRevision,
          'currentStateRevision': currentAuthState.revision,
        },
      );
      auditTrail = auditTrail.logFailure('planValidated', details: {
        'error': error.message,
      });
      return LearningActivityCompletionResult(
        requestId: request.requestId,
        activityId: request.activityId,
        status: LearningActivityCompletionStatus.futurePlanRevision,
        auditTrail: auditTrail,
        error: error,
        completedAt: effectiveTs,
      );
    }
    auditTrail = auditTrail.logSuccess('planValidated', details: {
      'planRevision': request.planRevision,
      'stateRevision': currentAuthState.revision,
    });

    // ------------------------------------------------------------------------
    // Step 4: Session & Attempt Invariant Validation
    // ------------------------------------------------------------------------
    final ActivityCompletionError? attemptError = _validateAttempts(request);
    if (attemptError != null) {
      auditTrail = auditTrail.logFailure('attemptsValidated', details: {
        'error': attemptError.message,
        'code': attemptError.code.name,
      });
      final status =
          attemptError.code == ActivityCompletionErrorCode.missingSession
              ? LearningActivityCompletionStatus.missingSession
              : LearningActivityCompletionStatus.invalidAttempts;
      return LearningActivityCompletionResult(
        requestId: request.requestId,
        activityId: request.activityId,
        status: status,
        auditTrail: auditTrail,
        error: attemptError,
        completedAt: effectiveTs,
      );
    }
    auditTrail = auditTrail.logSuccess('attemptsValidated');

    // ------------------------------------------------------------------------
    // Step 5: Outcome Normalization
    // ------------------------------------------------------------------------
    final LearningActivityOutcome outcome =
        _normalizeOutcome(request, effectiveTs);
    auditTrail = auditTrail.logSuccess('outcomeNormalized', details: {
      'score': outcome.score,
      'accuracy': outcome.accuracy,
      'completionRate': outcome.completionRate,
      'fingerprint': outcome.fingerprint,
    });

    // ------------------------------------------------------------------------
    // Step 6: Evidence Generation
    // ------------------------------------------------------------------------
    final ActivityOutcomeEvidence evidence =
        _buildEvidence(request, effectiveTs);
    auditTrail = auditTrail.logSuccess('evidenceCreated', details: {
      'questionCount': evidence.questionEvidence.length,
      'attemptCount': evidence.attempts.length,
    });

    // ------------------------------------------------------------------------
    // Step 7: Downstream P36 Consolidation & P38/P39 Reconciliation
    // ------------------------------------------------------------------------
    ConsolidatedPracticeOutcome? consolidatedOutcome;
    ReconciliationPipelineResult? reconciliationResult;
    AuthoritativeLearnerState resultingState = currentAuthState;

    if (request.activityType != LearningDecisionType.complete &&
        request.executionState != null) {
      // P36 Outcome Consolidation
      final consolidation = _consolidator.consolidate(
        state: request.executionState!,
        consolidatedAt: effectiveTs,
      );

      if (consolidation.isFailure) {
        final error = ActivityCompletionError(
          code: ActivityCompletionErrorCode.consolidationFailed,
          message: consolidation.error!.message,
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('outcomeConsolidated', details: {
          'error': error.message,
        });
        return LearningActivityCompletionResult(
          requestId: request.requestId,
          activityId: request.activityId,
          status: LearningActivityCompletionStatus.consolidationFailed,
          outcome: outcome,
          evidence: evidence,
          auditTrail: auditTrail,
          error: error,
          completedAt: effectiveTs,
        );
      }
      consolidatedOutcome = consolidation.valueOrThrow;
      auditTrail = auditTrail.logSuccess('outcomeConsolidated', details: {
        'sessionId': consolidatedOutcome.sessionId,
        'accuracy': consolidatedOutcome.accuracy,
      });

      // P38/P39 State Reconciliation & Atomic Persistence
      final reconResult =
          await _reconciliationPipeline.reconcilePracticeOutcome(
        baseState: currentAuthState,
        outcome: consolidatedOutcome,
        timestamp: effectiveTs,
      );

      if (!reconResult.isSuccess) {
        final error = ActivityCompletionError(
          code: ActivityCompletionErrorCode.reconciliationFailed,
          message: reconResult.message,
          cause: reconResult.persistenceError,
          timestamp: effectiveTs,
        );
        auditTrail = auditTrail.logFailure('stateReconciled', details: {
          'error': error.message,
        });
        return LearningActivityCompletionResult(
          requestId: request.requestId,
          activityId: request.activityId,
          status: LearningActivityCompletionStatus.reconciliationFailed,
          outcome: outcome,
          evidence: evidence,
          consolidatedOutcome: consolidatedOutcome,
          reconciliationResult: reconResult,
          auditTrail: auditTrail,
          error: error,
          completedAt: effectiveTs,
        );
      }
      reconciliationResult = reconResult;
      resultingState = reconResult.resultingState ?? currentAuthState;
      auditTrail = auditTrail.logSuccess('stateReconciled', details: {
        'resultingRevision': resultingState.revision,
        'isIdempotentReplay': reconResult.isIdempotentReplay,
      });
    } else {
      auditTrail = auditTrail.logSuccess('stateReconciled', details: {
        'note':
            'Non-session or terminal activity, zero practice consolidation needed.',
      });
    }

    // ------------------------------------------------------------------------
    // Step 8: Completion Record Persistence (Idempotency Key Stored)
    // ------------------------------------------------------------------------
    final completionRecord = LearningActivityCompletionRecord(
      idempotencyKey: idempotencyKey,
      learnerId: request.learnerId,
      examId: request.examId,
      activityId: request.activityId,
      sessionId: request.sessionId ?? request.executionState?.sessionId,
      planId: request.planId,
      planRevision: request.planRevision,
      outcome: outcome,
      completedAt: effectiveTs,
      fingerprint: outcome.fingerprint,
    );
    await _completionRepository.saveCompletionRecord(completionRecord);
    auditTrail = auditTrail.logSuccess('persistenceRequested', details: {
      'idempotencyKey': idempotencyKey,
    });

    auditTrail = auditTrail.logSuccess('completionAccepted', details: {
      'status': LearningActivityCompletionStatus.success.name,
    });

    return LearningActivityCompletionResult(
      requestId: request.requestId,
      activityId: request.activityId,
      status: LearningActivityCompletionStatus.success,
      outcome: outcome,
      evidence: evidence,
      consolidatedOutcome: consolidatedOutcome,
      reconciliationResult: reconciliationResult,
      resultingAuthoritativeState: resultingState,
      auditTrail: auditTrail,
      completedAt: effectiveTs,
    );
  }

  // --------------------------------------------------------------------------
  // Private Helper Methods
  // --------------------------------------------------------------------------

  ActivityCompletionError? _validateAttempts(
      LearningActivityCompletionRequest request) {
    if (request.activityType == LearningDecisionType.complete) {
      return null;
    }

    if (request.executionState == null &&
        (request.attempts == null || request.attempts!.isEmpty)) {
      return ActivityCompletionError(
        code: ActivityCompletionErrorCode.missingSession,
        message:
            'Practice activity "${request.activityId}" requires either executionState or non-empty attempts.',
      );
    }

    // Check duplicate questions and unknown question IDs in explicit attempts
    if (request.attempts != null) {
      final seenQuestions = <String>{};
      for (final attempt in request.attempts!) {
        if (!seenQuestions.add(attempt.questionId)) {
          return ActivityCompletionError(
            code: ActivityCompletionErrorCode.duplicateAttempt,
            message:
                'Duplicate attempt detected for questionId "${attempt.questionId}".',
          );
        }
        if (attempt.submittedAnswer.trim().isEmpty) {
          return ActivityCompletionError(
            code: ActivityCompletionErrorCode.invalidAttempts,
            message:
                'Attempt for questionId "${attempt.questionId}" has empty submittedAnswer.',
          );
        }
      }

      // Check against executionState spec if present
      if (request.executionState != null) {
        final allowedIds =
            request.executionState!.spec.orderedQuestionIds.toSet();
        for (final attempt in request.attempts!) {
          if (!allowedIds.contains(attempt.questionId)) {
            return ActivityCompletionError(
              code: ActivityCompletionErrorCode.unknownQuestion,
              message:
                  'Attempt for questionId "${attempt.questionId}" is not part of session specification.',
            );
          }
        }
      }
    }

    // Validate attempt results if present
    if (request.attemptResults != null) {
      for (final res in request.attemptResults!) {
        if (res.isCorrect && res.score <= 0.0) {
          return ActivityCompletionError(
            code: ActivityCompletionErrorCode.invalidAttempts,
            message:
                'Contradictory attempt result for "${res.attemptId}": isCorrect=true with score <= 0.0.',
          );
        }
        if (!res.isCorrect && res.score >= 1.0) {
          return ActivityCompletionError(
            code: ActivityCompletionErrorCode.invalidAttempts,
            message:
                'Contradictory attempt result for "${res.attemptId}": isCorrect=false with score >= 1.0.',
          );
        }
      }
    }

    return null;
  }

  LearningActivityOutcome _normalizeOutcome(
    LearningActivityCompletionRequest request,
    DateTime effectiveTs,
  ) {
    if (request.activityType == LearningDecisionType.complete) {
      return LearningActivityOutcome.calculate(
        activityId: request.activityId,
        activityType: request.activityType,
        learnerId: request.learnerId,
        examId: request.examId,
        sessionId: request.sessionId,
        questionsPresented: 0,
        questionsAttempted: 0,
        correctAnswers: 0,
        incorrectAnswers: 0,
        skippedAnswers: 0,
        unansweredCount: 0,
        completedAt: effectiveTs,
      );
    }

    if (request.executionState != null) {
      final exec = request.executionState!;
      final presented = exec.spec.totalQuestions;
      final results = exec.questionResults.values;
      final attempted = results.where((r) => r.isAnswered).length;
      final correct = results.where((r) => r.isCorrect).length;
      final incorrect =
          results.where((r) => r.isAnswered && !r.isCorrect).length;
      final skipped = results.where((r) => r.isSkipped).length;
      final unanswered =
          (presented - (attempted + skipped)).clamp(0, presented);

      final durationSec = (exec.completedAt ?? effectiveTs)
          .difference(exec.startedAt ?? effectiveTs)
          .inSeconds
          .clamp(0, 86400 * 7);

      final topicMap = <String, dynamic>{};
      final objMap = <String, dynamic>{};

      for (final r in results) {
        final t = r.question.topic;
        topicMap[t] = (topicMap[t] as int? ?? 0) + (r.isCorrect ? 1 : 0);

        for (final objId in r.question.objectiveIds) {
          objMap[objId] = (objMap[objId] as int? ?? 0) + (r.isCorrect ? 1 : 0);
        }
      }

      Map<String, dynamic>? remedialEv;
      if (request.activityType == LearningDecisionType.remediation) {
        remedialEv = {
          'remedialLessonId': request.remedialLessonId,
          'isCompleted': request.remedialLessonCompleted ?? true,
        };
      }

      return LearningActivityOutcome.calculate(
        activityId: request.activityId,
        activityType: request.activityType,
        learnerId: request.learnerId,
        examId: request.examId,
        sessionId: exec.sessionId,
        questionsPresented: presented,
        questionsAttempted: attempted,
        correctAnswers: correct,
        incorrectAnswers: incorrect,
        skippedAnswers: skipped,
        unansweredCount: unanswered,
        totalDurationSeconds: durationSec,
        topicEvidence: topicMap,
        objectiveEvidence: objMap,
        remedialEvidence: remedialEv,
        completedAt: effectiveTs,
      );
    }

    // Fallback if executionState is null but explicit attempts provided
    final attempts = request.attempts ?? const [];
    final results = request.attemptResults ?? const [];
    final attempted = attempts.length;
    final correct = results.isNotEmpty
        ? results.where((r) => r.isCorrect).length
        : attempted;
    final incorrect = attempted - correct;

    return LearningActivityOutcome.calculate(
      activityId: request.activityId,
      activityType: request.activityType,
      learnerId: request.learnerId,
      examId: request.examId,
      sessionId: request.sessionId,
      questionsPresented: attempted,
      questionsAttempted: attempted,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
      skippedAnswers: 0,
      unansweredCount: 0,
      completedAt: effectiveTs,
    );
  }

  ActivityOutcomeEvidence _buildEvidence(
    LearningActivityCompletionRequest request,
    DateTime effectiveTs,
  ) {
    final List<PracticeQuestionEvidence> qEvidence = [];
    final List<QuestionAttempt> attempts = [];
    final List<AttemptResult> attemptResults = [];

    if (request.executionState != null) {
      for (final r in request.executionState!.orderedResults) {
        final status = r.isCorrect
            ? PracticeQuestionStatus.answeredCorrect
            : r.isAnswered
                ? PracticeQuestionStatus.answeredIncorrect
                : r.isSkipped
                    ? PracticeQuestionStatus.skipped
                    : PracticeQuestionStatus.unanswered;

        final officialCorrect =
            r.question.officialAnswer.correctOptionKeys.isNotEmpty
                ? r.question.officialAnswer.correctOptionKeys.join(', ')
                : r.question.options
                    .where((o) => o.isCorrect)
                    .map((o) => o.key)
                    .join(', ');

        qEvidence.add(
          PracticeQuestionEvidence(
            questionId: r.questionId,
            examId: r.question.examId,
            year: r.question.year,
            paper: r.question.paper,
            subject: r.question.subject,
            topic: r.question.topic,
            objectiveIds: r.question.objectiveIds,
            difficulty: r.question.difficulty,
            questionIndex: r.questionIndex,
            status: status,
            submittedAnswer: r.submittedAnswer,
            correctAnswer: officialCorrect,
            isCorrect: r.isCorrect,
            isAnswered: r.isAnswered,
            isSkipped: r.isSkipped,
            elapsedSeconds: r.elapsedSeconds,
            presentedAt: r.presentedAt,
            answeredAt: r.answeredAt,
          ),
        );

        if (r.isAnswered && r.submittedAnswer != null) {
          final firstObj = r.question.objectiveIds.isNotEmpty
              ? r.question.objectiveIds.first
              : 'lo_general';
          final attemptId =
              'att_${request.activityId}_${r.questionId}_${r.questionIndex}';
          attempts.add(
            QuestionAttempt(
              attemptId: attemptId,
              learnerId: request.learnerId,
              questionId: r.questionId,
              objectiveId: firstObj,
              submittedAnswer: r.submittedAnswer!,
              attemptedAt: r.answeredAt ?? effectiveTs,
              sessionId: request.executionState!.sessionId,
            ),
          );

          attemptResults.add(
            AttemptResult(
              attemptId: attemptId,
              isCorrect: r.isCorrect,
              score: r.isCorrect ? 1.0 : 0.0,
              evaluatedAt: r.answeredAt ?? effectiveTs,
              evaluationMethod: r.feedback?.evaluationMethod ??
                  EvaluationMethod.multipleChoice,
            ),
          );
        }
      }
    } else if (request.attempts != null) {
      attempts.addAll(request.attempts!);
      if (request.attemptResults != null) {
        attemptResults.addAll(request.attemptResults!);
      }
    }

    return ActivityOutcomeEvidence(
      activityId: request.activityId,
      activityType: request.activityType,
      learnerId: request.learnerId,
      examId: request.examId,
      planId: request.planId,
      planRevision: request.planRevision,
      sessionId: request.sessionId ?? request.executionState?.sessionId,
      questionEvidence: qEvidence,
      attempts: attempts,
      attemptResults: attemptResults,
      remedialLessonId: request.remedialLessonId,
      remedialLessonCompleted: request.remedialLessonCompleted,
      timestamp: effectiveTs,
    );
  }
}
