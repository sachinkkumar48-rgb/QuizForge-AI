/// Adaptive Learning Plan Executor Service (TITAN-KO-042.0 P42).
///
/// Production orchestration layer translating P41 [LearningContinuationPlan]s into
/// operational learning activities: question selection, session orchestration,
/// practice execution, checkpointing, and crash recovery.
library;

import '../domain/entities/adaptive_decision_policy.dart';
import '../domain/entities/adaptive_practice_session_spec.dart';
import '../domain/entities/execution_audit_trail.dart';
import '../domain/entities/learning_activity_execution_request.dart';
import '../domain/entities/learning_activity_execution_result.dart';
import '../domain/entities/learning_activity_execution_status.dart';
import '../domain/entities/practice_execution_state.dart';
import '../domain/entities/session_checkpoint.dart';
import '../repository/session_checkpoint_repository.dart';
import 'adaptive_practice_execution_engine.dart';
import 'adaptive_practice_session_orchestrator.dart';
import 'adaptive_question_selection_service.dart';
import 'resumable_adaptive_practice_coordinator.dart';

/// Pure deterministic orchestrator executing adaptive learning plans.
class AdaptiveLearningPlanExecutor {
  /// Question selection service (P33).
  final AdaptiveQuestionSelectionService questionSelectionService;

  /// Session orchestrator service (P34).
  final AdaptivePracticeSessionOrchestrator sessionOrchestrator;

  /// Practice execution runtime engine (P35).
  final AdaptivePracticeExecutionEngine executionEngine;

  /// Resumable practice coordinator (P40), if integrated.
  final ResumableAdaptivePracticeCoordinator? practiceCoordinator;

  /// Session checkpoint repository for loading active session checkpoints.
  final SessionCheckpointRepository? checkpointRepository;

  const AdaptiveLearningPlanExecutor({
    this.questionSelectionService = const AdaptiveQuestionSelectionService(),
    this.sessionOrchestrator = const AdaptivePracticeSessionOrchestrator(),
    this.executionEngine = const AdaptivePracticeExecutionEngine(),
    this.practiceCoordinator,
    this.checkpointRepository,
  });

  /// Executes [request] and produces an immutable [LearningActivityExecutionResult].
  Future<LearningActivityExecutionResult> execute(
      LearningActivityExecutionRequest request) async {
    final effectiveNow = request.requestedAt;
    final traceId =
        'trc_${request.requestId}_${effectiveNow.millisecondsSinceEpoch}';
    final steps = <ExecutionAuditStep>[];
    int stepIndex = 0;

    // Helper recording an audit step
    void recordStep({
      required String stepName,
      required bool isSuccess,
      required String message,
      Map<String, dynamic>? details,
    }) {
      stepIndex++;
      steps.add(
        ExecutionAuditStep(
          stepIndex: stepIndex,
          stepName: stepName,
          timestamp: effectiveNow,
          isSuccess: isSuccess,
          message: message,
          details: details,
        ),
      );
    }

    // Helper formulating failure results
    LearningActivityExecutionResult fail({
      required LearningActivityExecutionStatus status,
      required PlanExecutionErrorCode code,
      required String message,
      Map<String, dynamic>? details,
    }) {
      final completedAt = effectiveNow;
      final auditTrail = ExecutionAuditTrail(
        traceId: traceId,
        learnerId: request.learnerId,
        examId: request.examId,
        steps: steps,
        startedAt: effectiveNow,
        completedAt: completedAt,
      );

      return LearningActivityExecutionResult.failure(
        requestId: request.requestId,
        learnerId: request.learnerId,
        examId: request.examId,
        planId: request.plan.planId,
        decisionId: request.plan.decision.decisionId,
        activityType: request.plan.decision.type,
        status: status,
        target: request.plan.target,
        sourceRevision: request.plan.decision.authoritativeStateRevision,
        executionRevision: request.currentState.revision,
        error: PlanExecutionError(
          code: code,
          message: message,
          details: details,
        ),
        auditTrail: auditTrail,
        executedAt: completedAt,
      );
    }

    // 1. Step: PLAN_RECEIVED
    recordStep(
      stepName: 'PLAN_RECEIVED',
      isSuccess: true,
      message:
          'Received execution request for plan ${request.plan.planId} (${request.plan.decision.type.name}).',
      details: {
        'planId': request.plan.planId,
        'decisionId': request.plan.decision.decisionId,
        'activityType': request.plan.decision.type.name,
      },
    );

    // 2. Step: TENANT_VALIDATED
    final planTenantMatches =
        request.learnerId == request.plan.decision.learnerId &&
            request.examId == request.plan.decision.examId;
    final stateTenantMatches =
        request.learnerId == request.currentState.learnerId &&
            request.examId == request.currentState.examId;

    if (!planTenantMatches || !stateTenantMatches) {
      final msg =
          'Tenant mismatch: request (${request.learnerId}:${request.examId}) '
          'vs plan (${request.plan.decision.learnerId}:${request.plan.decision.examId}) '
          'vs state (${request.currentState.learnerId}:${request.currentState.examId}).';
      recordStep(
        stepName: 'TENANT_VALIDATED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.invalidPlan,
        code: PlanExecutionErrorCode.tenantMismatch,
        message: msg,
      );
    }

    recordStep(
      stepName: 'TENANT_VALIDATED',
      isSuccess: true,
      message:
          'Tenant identity verified for ${request.learnerId}:${request.examId}.',
    );

    // 3. Step: REVISION_VALIDATED (Freshness check)
    if (request.plan.isStale(request.currentState)) {
      final msg =
          'Stale plan rejected: state revision ${request.currentState.revision} '
          'has advanced beyond plan revision ${request.plan.decision.authoritativeStateRevision}.';
      recordStep(
        stepName: 'REVISION_VALIDATED',
        isSuccess: false,
        message: msg,
        details: {
          'currentStateRevision': request.currentState.revision,
          'planRevision': request.plan.decision.authoritativeStateRevision,
        },
      );
      return fail(
        status: LearningActivityExecutionStatus.stalePlan,
        code: PlanExecutionErrorCode.stalePlan,
        message: msg,
      );
    }

    if (request.currentState.revision <
        request.plan.decision.authoritativeStateRevision) {
      final msg =
          'Incompatible state revision: currentState revision ${request.currentState.revision} '
          'is behind plan revision ${request.plan.decision.authoritativeStateRevision}.';
      recordStep(
        stepName: 'REVISION_VALIDATED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.invalidPlan,
        code: PlanExecutionErrorCode.invalidPlan,
        message: msg,
      );
    }

    recordStep(
      stepName: 'REVISION_VALIDATED',
      isSuccess: true,
      message:
          'Plan revision ${request.plan.decision.authoritativeStateRevision} matches state revision ${request.currentState.revision}.',
    );

    // 4. Step: CONFLICT_CHECKED
    // If starting a new session (non-continuation), verify no unfinished session is active
    if (request.plan.decision.type != LearningDecisionType.continuation) {
      if (request.activeCheckpoint != null &&
          !request.activeCheckpoint!.isCompleted) {
        final msg =
            'Active session conflict: session ${request.activeCheckpoint!.sessionId} is currently unfinished at question cursor ${request.activeCheckpoint!.questionIndex}.';
        recordStep(
          stepName: 'CONFLICT_CHECKED',
          isSuccess: false,
          message: msg,
          details: {
            'activeSessionId': request.activeCheckpoint!.sessionId,
            'questionIndex': request.activeCheckpoint!.questionIndex,
          },
        );
        return fail(
          status: LearningActivityExecutionStatus.sessionAlreadyActive,
          code: PlanExecutionErrorCode.sessionAlreadyActive,
          message: msg,
        );
      }
    }

    recordStep(
      stepName: 'CONFLICT_CHECKED',
      isSuccess: true,
      message: 'Zero active session conflicts detected.',
    );

    // 5. Step: ACTIVITY_ROUTED & DOWNSTREAM_EXECUTION
    switch (request.plan.decision.type) {
      case LearningDecisionType.continuation:
        return _executeContinuation(
          request: request,
          traceId: traceId,
          steps: steps,
          effectiveNow: effectiveNow,
          recordStep: recordStep,
          fail: fail,
        );

      case LearningDecisionType.complete:
        return _executeComplete(
          request: request,
          traceId: traceId,
          steps: steps,
          effectiveNow: effectiveNow,
          recordStep: recordStep,
        );

      case LearningDecisionType.remediation:
      case LearningDecisionType.review:
      case LearningDecisionType.reinforcement:
      case LearningDecisionType.advancement:
        return _executePracticeActivity(
          request: request,
          traceId: traceId,
          steps: steps,
          effectiveNow: effectiveNow,
          recordStep: recordStep,
          fail: fail,
        );
    }
  }

  // --- PRIVATE ACTIVITY EXECUTORS ---

  Future<LearningActivityExecutionResult> _executeContinuation({
    required LearningActivityExecutionRequest request,
    required String traceId,
    required List<ExecutionAuditStep> steps,
    required DateTime effectiveNow,
    required void Function({
      required String stepName,
      required bool isSuccess,
      required String message,
      Map<String, dynamic>? details,
    }) recordStep,
    required LearningActivityExecutionResult Function({
      required LearningActivityExecutionStatus status,
      required PlanExecutionErrorCode code,
      required String message,
      Map<String, dynamic>? details,
    }) fail,
  }) async {
    recordStep(
      stepName: 'ACTIVITY_ROUTED',
      isSuccess: true,
      message: 'Routing to Session Continuation execution path.',
    );

    // Resolve checkpoint
    SessionCheckpoint? checkpoint = request.activeCheckpoint;
    final sessionId = request.plan.target.metadata['sessionId'] as String? ??
        request.plan.resumableSession?.sessionId;

    if (checkpoint == null &&
        checkpointRepository != null &&
        sessionId != null) {
      checkpoint = await checkpointRepository!.loadCheckpoint(
        learnerId: request.learnerId,
        examId: request.examId,
        sessionId: sessionId,
      );
    }

    if (checkpoint == null) {
      const msg = 'Resumption failed: active session checkpoint is absent.';
      recordStep(
        stepName: 'TARGET_VALIDATED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.recoveryRequired,
        code: PlanExecutionErrorCode.recoveryRequired,
        message: msg,
      );
    }

    if (checkpoint.isCompleted) {
      final msg =
          'Session ${checkpoint.sessionId} has already reached terminal completion and cannot be resumed.';
      recordStep(
        stepName: 'TARGET_VALIDATED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.invalidTarget,
        code: PlanExecutionErrorCode.invalidTarget,
        message: msg,
      );
    }

    // Resolve session specification
    final spec =
        request.existingSessionSpec ?? request.plan.resumableSession?.spec;

    if (spec == null) {
      const msg =
          'Resumption failed: underlying AdaptivePracticeSessionSpec is required to resume execution.';
      recordStep(
        stepName: 'DOWNSTREAM_EXECUTION_STARTED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.recoveryRequired,
        code: PlanExecutionErrorCode.recoveryRequired,
        message: msg,
      );
    }

    recordStep(
      stepName: 'TARGET_VALIDATED',
      isSuccess: true,
      message:
          'Resuming session ${checkpoint.sessionId} at question cursor ${checkpoint.questionIndex}.',
      details: {
        'sessionId': checkpoint.sessionId,
        'questionIndex': checkpoint.questionIndex,
        'checkpointRevision': checkpoint.checkpointRevision,
      },
    );

    recordStep(
      stepName: 'DOWNSTREAM_EXECUTION_STARTED',
      isSuccess: true,
      message:
          'Reconstructing execution state from checkpoint cursor ${checkpoint.questionIndex}.',
    );

    PracticeExecutionState executionState;

    if (practiceCoordinator != null) {
      final recovered = await practiceCoordinator!.recoverAndResumeSession(
        learnerId: request.learnerId,
        examId: request.examId,
        sessionId: checkpoint.sessionId,
        spec: spec,
        resumedAt: effectiveNow,
      );
      executionState = recovered.executionState;
    } else {
      executionState = _reconstructExecutionState(
        spec: spec,
        checkpoint: checkpoint,
        resumedAt: effectiveNow,
      );
    }

    recordStep(
      stepName: 'DOWNSTREAM_EXECUTION_COMPLETED',
      isSuccess: true,
      message:
          'Session ${checkpoint.sessionId} successfully resumed at cursor ${executionState.currentQuestionIndex}.',
    );

    final auditTrail = ExecutionAuditTrail(
      traceId: traceId,
      learnerId: request.learnerId,
      examId: request.examId,
      steps: steps,
      startedAt: effectiveNow,
      completedAt: effectiveNow,
    );

    return LearningActivityExecutionResult.resumed(
      requestId: request.requestId,
      learnerId: request.learnerId,
      examId: request.examId,
      planId: request.plan.planId,
      decisionId: request.plan.decision.decisionId,
      target: request.plan.target,
      sourceRevision: request.plan.decision.authoritativeStateRevision,
      executionRevision: request.currentState.revision,
      sessionSpec: spec,
      executionState: executionState,
      checkpoint: checkpoint,
      auditTrail: auditTrail,
      executedAt: effectiveNow,
    );
  }

  LearningActivityExecutionResult _executeComplete({
    required LearningActivityExecutionRequest request,
    required String traceId,
    required List<ExecutionAuditStep> steps,
    required DateTime effectiveNow,
    required void Function({
      required String stepName,
      required bool isSuccess,
      required String message,
      Map<String, dynamic>? details,
    }) recordStep,
  }) {
    recordStep(
      stepName: 'ACTIVITY_ROUTED',
      isSuccess: true,
      message: 'Routing to Curriculum Complete terminal path.',
    );

    recordStep(
      stepName: 'DOWNSTREAM_EXECUTION_COMPLETED',
      isSuccess: true,
      message:
          'All curriculum objectives achieved; zero practice sessions required.',
    );

    final auditTrail = ExecutionAuditTrail(
      traceId: traceId,
      learnerId: request.learnerId,
      examId: request.examId,
      steps: steps,
      startedAt: effectiveNow,
      completedAt: effectiveNow,
    );

    return LearningActivityExecutionResult.completed(
      requestId: request.requestId,
      learnerId: request.learnerId,
      examId: request.examId,
      planId: request.plan.planId,
      decisionId: request.plan.decision.decisionId,
      target: request.plan.target,
      sourceRevision: request.plan.decision.authoritativeStateRevision,
      executionRevision: request.currentState.revision,
      auditTrail: auditTrail,
      executedAt: effectiveNow,
    );
  }

  Future<LearningActivityExecutionResult> _executePracticeActivity({
    required LearningActivityExecutionRequest request,
    required String traceId,
    required List<ExecutionAuditStep> steps,
    required DateTime effectiveNow,
    required void Function({
      required String stepName,
      required bool isSuccess,
      required String message,
      Map<String, dynamic>? details,
    }) recordStep,
    required LearningActivityExecutionResult Function({
      required LearningActivityExecutionStatus status,
      required PlanExecutionErrorCode code,
      required String message,
      Map<String, dynamic>? details,
    }) fail,
  }) async {
    final activityType = request.plan.decision.type;
    final targetObjectiveId = request.plan.target.objectiveId;

    recordStep(
      stepName: 'ACTIVITY_ROUTED',
      isSuccess: true,
      message: 'Routing to ${activityType.name} practice session path.',
    );

    // Target validation
    if (targetObjectiveId == null || targetObjectiveId.trim().isEmpty) {
      const msg =
          'Execution rejected: target learning objective ID is missing.';
      recordStep(
        stepName: 'TARGET_VALIDATED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.invalidTarget,
        code: PlanExecutionErrorCode.invalidTarget,
        message: msg,
      );
    }

    recordStep(
      stepName: 'TARGET_VALIDATED',
      isSuccess: true,
      message: 'Target objective confirmed: $targetObjectiveId.',
      details: {
        'objectiveId': targetObjectiveId,
        'targetType': request.plan.target.targetType.name,
      },
    );

    // Validate corpus
    if (request.corpus.isEmpty) {
      const msg =
          'Question selection failed: available question corpus is empty.';
      recordStep(
        stepName: 'DOWNSTREAM_EXECUTION_STARTED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.executionFailed,
        code: PlanExecutionErrorCode.corpusEmpty,
        message: msg,
      );
    }

    recordStep(
      stepName: 'DOWNSTREAM_EXECUTION_STARTED',
      isSuccess: true,
      message:
          'Selecting questions from corpus (${request.corpus.length} available).',
    );

    // 1. Question selection (P33)
    final selectionConfig = request.plan.toAdaptiveQuestionSelectionConfig();
    final selectionResult = questionSelectionService.selectQuestions(
      corpus: request.corpus,
      config: selectionConfig,
      progressList: request.currentState.progressMap.values.toList(),
      selectedAt: effectiveNow,
    );

    if (selectionResult.selectedCandidates.isEmpty) {
      final msg =
          'Question selection returned 0 questions for objective $targetObjectiveId.';
      recordStep(
        stepName: 'DOWNSTREAM_EXECUTION_STARTED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.executionFailed,
        code: PlanExecutionErrorCode.selectionFailed,
        message: msg,
      );
    }

    // 2. Session orchestration (P34)
    final sessionConfig = request.plan.toAdaptivePracticeSessionConfig();
    final spec = sessionOrchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: sessionConfig,
      orchestratedAt: effectiveNow,
    );

    if (spec.orderedQuestions.isEmpty) {
      final msg =
          'Session orchestration produced 0 questions for session ${spec.sessionId}.';
      recordStep(
        stepName: 'DOWNSTREAM_EXECUTION_STARTED',
        isSuccess: false,
        message: msg,
      );
      return fail(
        status: LearningActivityExecutionStatus.executionFailed,
        code: PlanExecutionErrorCode.orchestrationFailed,
        message: msg,
      );
    }

    // 3. Session initialization & start (P35/P40)
    PracticeExecutionState executionState;
    SessionCheckpoint? checkpoint;

    if (practiceCoordinator != null) {
      final startStep = await practiceCoordinator!.startSession(
        spec: spec,
        baseState: request.currentState,
        feedbackPolicy: request.feedbackPolicy,
        allowSkip: request.allowSkip,
        startedAt: effectiveNow,
      );
      executionState = startStep.executionState;
      checkpoint = startStep.checkpoint;
    } else {
      final initial = executionEngine.initializeSession(
        spec: spec,
        feedbackPolicy: request.feedbackPolicy,
        allowSkip: request.allowSkip,
      );
      final startResult = executionEngine.startSession(
        state: initial,
        startedAt: effectiveNow,
      );
      executionState = startResult.valueOrThrow;
    }

    recordStep(
      stepName: 'DOWNSTREAM_EXECUTION_COMPLETED',
      isSuccess: true,
      message:
          'Practice session ${spec.sessionId} started with ${spec.totalQuestions} questions across ${spec.totalSections} sections.',
      details: {
        'sessionId': spec.sessionId,
        'totalQuestions': spec.totalQuestions,
        'sessionMode': spec.config.sessionMode.name,
        'hasRemedialLesson': request.plan.remedialLesson != null,
      },
    );

    final auditTrail = ExecutionAuditTrail(
      traceId: traceId,
      learnerId: request.learnerId,
      examId: request.examId,
      steps: steps,
      startedAt: effectiveNow,
      completedAt: effectiveNow,
    );

    return LearningActivityExecutionResult.success(
      requestId: request.requestId,
      learnerId: request.learnerId,
      examId: request.examId,
      planId: request.plan.planId,
      decisionId: request.plan.decision.decisionId,
      activityType: activityType,
      target: request.plan.target,
      sourceRevision: request.plan.decision.authoritativeStateRevision,
      executionRevision: request.currentState.revision,
      sessionSpec: spec,
      executionState: executionState,
      checkpoint: checkpoint,
      remedialLesson: request.plan.remedialLesson,
      selectionResult: selectionResult,
      auditTrail: auditTrail,
      executedAt: effectiveNow,
    );
  }

  /// Reconstructs execution state positioned at checkpoint index for standalone runs.
  PracticeExecutionState _reconstructExecutionState({
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

      if (completedSet.contains(q.id) || i < checkpoint.questionIndex) {
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

    return PracticeExecutionState(
      sessionId: spec.sessionId,
      examId: spec.examId,
      learnerId: spec.learnerId,
      status: checkpoint.isCompleted
          ? PracticeExecutionStatus.completed
          : PracticeExecutionStatus.inProgress,
      feedbackPolicy: PracticeFeedbackPolicy.immediate,
      allowSkip: true,
      currentQuestionIndex: checkpoint.questionIndex,
      questionResults: resultsMap,
      spec: spec,
      startedAt: checkpoint.timestamp,
      completedAt: checkpoint.isCompleted ? checkpoint.timestamp : null,
    );
  }
}
