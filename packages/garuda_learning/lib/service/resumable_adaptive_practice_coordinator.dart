/// Resumable Adaptive Practice Coordinator Service (TITAN-KO-040.0 P40).
///
/// Production integration orchestrator coordinating P35 Practice Execution,
/// P36 Outcome Consolidation, P38 State Reconciliation, P39 Authoritative
/// Persistence, P40 Session Checkpointing, and Crash Recovery into a single,
/// crash-safe adaptive learning lifecycle.
library;

import '../domain/entities/adaptive_practice_session_spec.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/practice_execution_state.dart';
import '../domain/entities/reconciliation_pipeline_result.dart';
import '../domain/entities/session_checkpoint.dart';
import '../domain/entities/session_recovery_error.dart';
import 'adaptive_learning_state_reconciliation_pipeline.dart';
import 'adaptive_practice_execution_engine.dart';
import 'learning_session_recovery_service.dart';

/// Result container for step execution and checkpoint persistence.
class PracticeStepCheckpointResult {
  /// Updated transient practice execution state.
  final PracticeExecutionState executionState;

  /// Latest authoritative learner state.
  final AuthoritativeLearnerState authoritativeState;

  /// Updated and persisted session checkpoint.
  final SessionCheckpoint checkpoint;

  /// Pipeline reconciliation result, if reconciliation was triggered.
  final ReconciliationPipelineResult? pipelineResult;

  const PracticeStepCheckpointResult({
    required this.executionState,
    required this.authoritativeState,
    required this.checkpoint,
    this.pipelineResult,
  });
}

/// Production coordinator integrating practice execution, reconciliation, and crash recovery.
class ResumableAdaptivePracticeCoordinator {
  final AdaptivePracticeExecutionEngine _engine;
  final AdaptiveLearningStateReconciliationPipeline _pipeline;
  final LearningSessionRecoveryService _recoveryService;

  const ResumableAdaptivePracticeCoordinator({
    required AdaptivePracticeExecutionEngine engine,
    required AdaptiveLearningStateReconciliationPipeline pipeline,
    required LearningSessionRecoveryService recoveryService,
  })  : _engine = engine,
        _pipeline = pipeline,
        _recoveryService = recoveryService;

  /// Starts a new practice session, creates the initial checkpoint, and persists it.
  Future<PracticeStepCheckpointResult> startSession({
    required AdaptivePracticeSessionSpec spec,
    required AuthoritativeLearnerState baseState,
    PracticeFeedbackPolicy feedbackPolicy = PracticeFeedbackPolicy.immediate,
    bool allowSkip = true,
    DateTime? startedAt,
  }) async {
    final effectiveTs = (startedAt ?? DateTime.now()).toUtc();

    // 1. Initialize P35 execution state
    final initial = _engine.initializeSession(
      spec: spec,
      feedbackPolicy: feedbackPolicy,
      allowSkip: allowSkip,
    );

    // 2. Start session
    final startResult = _engine.startSession(
      state: initial,
      startedAt: effectiveTs,
    );
    final activeExecutionState = startResult.valueOrThrow;

    // 3. Formulate initial session checkpoint at revision 1
    final firstObjective = spec.orderedQuestions.isNotEmpty &&
            spec.orderedQuestions.first.objectiveIds.isNotEmpty
        ? spec.orderedQuestions.first.objectiveIds.first
        : 'lo_general';

    final initialCheckpoint = SessionCheckpoint(
      checkpointRevision: 1,
      authoritativeStateRevision: baseState.revision,
      sessionId: spec.sessionId,
      learnerId: spec.learnerId ?? baseState.learnerId,
      examId: spec.examId,
      questionIndex: 0,
      completedQuestionIds: const [],
      activeObjectiveId: firstObjective,
      timestamp: effectiveTs,
      isCompleted:
          activeExecutionState.status == PracticeExecutionStatus.completed,
    );

    // 4. Persist checkpoint
    await _recoveryService.saveCheckpoint(initialCheckpoint);

    return PracticeStepCheckpointResult(
      executionState: activeExecutionState,
      authoritativeState: baseState,
      checkpoint: initialCheckpoint,
    );
  }

  /// Submits an answer, reconciles state with P38/P39, and saves an atomic checkpoint.
  Future<PracticeStepCheckpointResult> submitAnswerAndCheckpoint({
    required PracticeExecutionState executionState,
    required AuthoritativeLearnerState baseState,
    required SessionCheckpoint currentCheckpoint,
    required String questionId,
    required String answer,
    DateTime? submittedAt,
  }) async {
    final effectiveTs = (submittedAt ?? DateTime.now()).toUtc();

    // 1. Execute answer submission in P35 engine
    final submitResult = _engine.submitAnswer(
      state: executionState,
      questionId: questionId,
      answer: answer,
      submittedAt: effectiveTs,
    );
    final updatedExecution = submitResult.valueOrThrow;

    // 2. Formulate incremental step execution for reconciliation
    final stepSessionId =
        '${updatedExecution.sessionId}_step_${updatedExecution.currentQuestionIndex}';
    final stepExecution = PracticeExecutionState(
      sessionId: stepSessionId,
      examId: updatedExecution.examId,
      learnerId: updatedExecution.learnerId,
      spec: updatedExecution.spec,
      feedbackPolicy: updatedExecution.feedbackPolicy,
      allowSkip: updatedExecution.allowSkip,
      status: updatedExecution.status,
      currentQuestionIndex: updatedExecution.currentQuestionIndex,
      questionResults: updatedExecution.questionResults,
      events: updatedExecution.events,
      startedAt: updatedExecution.startedAt,
      lastActionAt: updatedExecution.lastActionAt,
      completedAt: updatedExecution.completedAt,
    );

    final pipelineResult = await _pipeline.reconcileExecutionState(
      baseState: baseState,
      executionState: stepExecution,
      timestamp: effectiveTs,
    );

    // Determine resulting authoritative learner state
    final updatedAuth =
        pipelineResult.resultingState ?? pipelineResult.baseState;

    // 3. Advance checkpoint coordinates
    final completedIds = updatedExecution.orderedResults
        .where((r) => r.isAnswered)
        .map((r) => r.questionId)
        .toList();

    final nextObjective = updatedExecution.currentQuestion != null &&
            updatedExecution.currentQuestion!.objectiveIds.isNotEmpty
        ? updatedExecution.currentQuestion!.objectiveIds.first
        : currentCheckpoint.activeObjectiveId;

    final nextCheckpointRevision = currentCheckpoint.checkpointRevision + 1;
    final isDone = updatedExecution.status == PracticeExecutionStatus.completed;

    final updatedCheckpoint = currentCheckpoint.copyWith(
      checkpointRevision: nextCheckpointRevision,
      authoritativeStateRevision: updatedAuth.revision,
      questionIndex: updatedExecution.currentQuestionIndex,
      completedQuestionIds: completedIds,
      activeObjectiveId: nextObjective,
      timestamp: effectiveTs,
      isCompleted: isDone,
    );

    // 4. Atomically persist checkpoint
    await _recoveryService.saveCheckpoint(updatedCheckpoint);

    return PracticeStepCheckpointResult(
      executionState: updatedExecution,
      authoritativeState: updatedAuth,
      checkpoint: updatedCheckpoint,
      pipelineResult: pipelineResult,
    );
  }

  /// Recovers an interrupted practice session after an application restart/crash.
  ///
  /// Reconstructs the exact [PracticeExecutionState] positioned at the first
  /// uncompleted question cursor so learning continues seamlessly without repeating
  /// completed questions or duplicating progress.
  Future<PracticeStepCheckpointResult> recoverAndResumeSession({
    required String learnerId,
    required String examId,
    required String sessionId,
    required AdaptivePracticeSessionSpec spec,
    DateTime? resumedAt,
  }) async {
    final effectiveTs = (resumedAt ?? DateTime.now()).toUtc();

    // 1. Recover session and authoritative state via recovery service
    final recoveryResult = await _recoveryService.recoverSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
      spec: spec,
      requestedAt: effectiveTs,
    );

    if (recoveryResult.isFailure) {
      throw recoveryResult.error ??
          SessionRecoveryException(
            code: SessionRecoveryErrorCode.unknownFailure,
            message: recoveryResult.message,
          );
    }

    final checkpoint = recoveryResult.checkpoint!;
    final authoritativeState = recoveryResult.authoritativeState!;

    // 2. Reconstruct PracticeExecutionState positioned at checkpoint.questionIndex
    final reconstructedState = reconstructExecutionState(
      spec: spec,
      checkpoint: checkpoint,
      resumedAt: effectiveTs,
    );

    return PracticeStepCheckpointResult(
      executionState: reconstructedState,
      authoritativeState: authoritativeState,
      checkpoint: checkpoint,
    );
  }

  /// Helper reconstructing PracticeExecutionState from a checkpoint and spec.
  PracticeExecutionState reconstructExecutionState({
    required AdaptivePracticeSessionSpec spec,
    required SessionCheckpoint checkpoint,
    required DateTime resumedAt,
  }) {
    final completedSet = checkpoint.completedQuestionIds.toSet();
    final resultsMap = <String, PracticeQuestionResult>{};

    for (int i = 0; i < spec.orderedQuestions.length; i++) {
      final q = spec.orderedQuestions[i];
      final candidate =
          i < spec.orderedCandidates.length ? spec.orderedCandidates[i] : null;

      final isAlreadyCompleted =
          completedSet.contains(q.id) || (checkpoint.questionIndex > i);

      if (isAlreadyCompleted) {
        resultsMap[q.id] = PracticeQuestionResult(
          questionId: q.id,
          questionIndex: i,
          isAnswered: true,
          isSkipped: false,
          submittedAnswer: 'RECOVERED',
          isCorrect: true,
          presentedAt: checkpoint.timestamp,
          answeredAt: checkpoint.timestamp,
          elapsedSeconds: 0,
          candidateMetadata: candidate,
          question: q,
        );
      } else {
        resultsMap[q.id] = PracticeQuestionResult.unattempted(
          index: i,
          question: q,
          candidate: candidate,
          presentedAt: i == checkpoint.questionIndex ? resumedAt : null,
        );
      }
    }

    final isSessionFinished = checkpoint.isCompleted ||
        checkpoint.questionIndex >= spec.totalQuestions;

    final status = isSessionFinished
        ? PracticeExecutionStatus.completed
        : PracticeExecutionStatus.inProgress;

    return PracticeExecutionState(
      sessionId: spec.sessionId,
      examId: spec.examId,
      learnerId: spec.learnerId,
      spec: spec,
      feedbackPolicy: PracticeFeedbackPolicy.immediate,
      allowSkip: true,
      status: status,
      currentQuestionIndex: checkpoint.questionIndex,
      questionResults: resultsMap,
      startedAt: checkpoint.timestamp,
      lastActionAt: resumedAt,
      completedAt: isSessionFinished ? checkpoint.timestamp : null,
      events: [
        PracticeExecutionEvent(
          eventId: 'evt_${spec.sessionId}_resumed',
          sessionId: spec.sessionId,
          type: PracticeExecutionEventType.sessionResumed,
          timestamp: resumedAt,
          payload: {
            'resumedAtIndex': checkpoint.questionIndex,
            'checkpointRevision': checkpoint.checkpointRevision,
            'completedQuestionsCount': checkpoint.completedCount,
          },
        ),
      ],
    );
  }
}
