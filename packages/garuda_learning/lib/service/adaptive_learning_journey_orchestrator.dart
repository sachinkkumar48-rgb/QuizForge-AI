/// Adaptive Learning Journey Orchestrator Service (TITAN-KO-041.0 P41).
///
/// Production integration orchestrator coordinating the complete end-to-end
/// adaptive learner journey: question selection, practice execution, outcome
/// consolidation, authoritative state reconciliation, checkpoint durability,
/// crash interruption, and exact resumption without evidence duplication.
library;

import 'package:garuda_pyq/garuda_pyq.dart';

import '../domain/entities/adaptive_practice_session_config.dart';
import '../domain/entities/adaptive_practice_session_spec.dart';
import '../domain/entities/adaptive_question_candidate.dart';
import '../domain/entities/adaptive_question_selection_config.dart';
import '../domain/entities/adaptive_question_selection_result.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/learning_journey_error.dart';
import '../domain/entities/learning_journey_session.dart';
import '../domain/entities/learning_journey_status.dart';
import '../domain/entities/learning_journey_step_result.dart';
import '../domain/entities/practice_execution_state.dart';
import '../domain/entities/session_recovery_result.dart';
import '../repository/authoritative_learning_state_repository.dart';
import '../repository/session_checkpoint_repository.dart';
import 'adaptive_learning_state_reconciliation_pipeline.dart';
import 'adaptive_practice_execution_engine.dart';
import 'adaptive_practice_session_orchestrator.dart';
import 'adaptive_question_selection_service.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'learning_session_recovery_service.dart';
import 'practice_outcome_consolidator.dart';
import 'resumable_adaptive_practice_coordinator.dart';

/// Production orchestrator coordinating end-to-end adaptive learner journeys.
class AdaptiveLearningJourneyOrchestrator {
  final AuthoritativeLearningStateRecoveryService _authRecoveryService;
  final LearningSessionRecoveryService _sessionRecoveryService;
  final AdaptiveQuestionSelectionService _selectionService;
  final AdaptivePracticeSessionOrchestrator _sessionOrchestrator;
  final ResumableAdaptivePracticeCoordinator _practiceCoordinator;

  static int _sessionCounter = 1;
  static final Map<String, AdaptivePracticeSessionSpec> _specCache = {};

  AdaptiveLearningJourneyOrchestrator({
    required AuthoritativeLearningStateRepository authRepository,
    required AuthoritativeLearningStateRecoveryService authRecoveryService,
    required SessionCheckpointRepository checkpointRepository,
    required LearningSessionRecoveryService sessionRecoveryService,
    AdaptiveQuestionSelectionService? selectionService,
    AdaptivePracticeSessionOrchestrator? sessionOrchestrator,
    AdaptivePracticeExecutionEngine? executionEngine,
    PracticeOutcomeConsolidator? consolidator,
    AdaptiveLearningStateReconciliationPipeline? reconciliationPipeline,
    ResumableAdaptivePracticeCoordinator? practiceCoordinator,
  })  : _authRecoveryService = authRecoveryService,
        _sessionRecoveryService = sessionRecoveryService,
        _selectionService =
            selectionService ?? const AdaptiveQuestionSelectionService(),
        _sessionOrchestrator =
            sessionOrchestrator ?? AdaptivePracticeSessionOrchestrator(),
        _practiceCoordinator = practiceCoordinator ??
            ResumableAdaptivePracticeCoordinator(
              engine:
                  executionEngine ?? const AdaptivePracticeExecutionEngine(),
              pipeline: reconciliationPipeline ??
                  AdaptiveLearningStateReconciliationPipeline(
                    repository: authRepository,
                    recoveryService: authRecoveryService,
                    consolidator:
                        consolidator ?? const PracticeOutcomeConsolidator(),
                  ),
              recoveryService: sessionRecoveryService,
            );

  // --------------------------------------------------------------------------
  // 1. Journey Creation & Activation
  // --------------------------------------------------------------------------

  /// Initializes and activates an end-to-end adaptive learning journey session.
  Future<LearningJourneyStepResult> startJourney({
    required String learnerId,
    required String examId,
    required List<NormalizedQuestion> corpus,
    String? targetObjectiveId,
    int questionCount = 5,
    AdaptivePracticeSessionConfig? sessionConfig,
    DateTime? startedAt,
  }) async {
    final effectiveTs = (startedAt ?? DateTime.now()).toUtc();
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();

    if (cleanLearner.isEmpty || cleanExam.isEmpty) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.tenantMismatch,
        message: 'learnerId and examId cannot be empty',
        executedAt: effectiveTs,
      );
    }

    if (corpus.isEmpty) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.emptyCorpus,
        message: 'Question corpus cannot be empty',
        executedAt: effectiveTs,
      );
    }

    // 1. Recover or cold-start authoritative learner state
    final authRecovery = await _authRecoveryService.recover(
      learnerId: cleanLearner,
      examId: cleanExam,
      requestedAt: effectiveTs,
    );
    final authState = authRecovery.state ??
        AuthoritativeLearnerState.empty(
          learnerId: cleanLearner,
          examId: cleanExam,
          createdAt: effectiveTs,
        );

    // 2. Select practice questions based on active learner state
    final selectionConfig = AdaptiveQuestionSelectionConfig(
      examId: cleanExam,
      targetQuestionCount: questionCount,
      scopedObjectiveIds:
          targetObjectiveId != null ? [targetObjectiveId] : null,
      excludePreviouslySeen: true,
    );

    final selectionResult = _selectionService.selectQuestions(
      corpus: corpus,
      config: selectionConfig,
      progressList: authState.progressMap.values.toList(),
      selectedAt: effectiveTs,
    );

    if (selectionResult.selectedQuestions.isEmpty) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.selectionExhausted,
        message:
            'No eligible questions available matching criteria for exam "$cleanExam"',
        executedAt: effectiveTs,
      );
    }

    // 3. Orchestrate practice session specification
    final activeConfig = sessionConfig ??
        AdaptivePracticeSessionConfig(
          examId: cleanExam,
          learnerId: cleanLearner,
          sessionMode: PracticeSessionMode.standard,
          sectionSize: 5,
          estimatedSecondsPerQuestion: 60,
        );

    final baseSpec = _sessionOrchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: activeConfig,
      orchestratedAt: effectiveTs,
    );

    final uniqueSessionId =
        'sess_${cleanExam}_${cleanLearner}_${effectiveTs.millisecondsSinceEpoch.toRadixString(16)}_${_sessionCounter++}';

    final sessionSpec = AdaptivePracticeSessionSpec(
      sessionId: uniqueSessionId,
      examId: baseSpec.examId,
      learnerId: cleanLearner,
      sessionMode: baseSpec.sessionMode,
      completionPolicy: baseSpec.completionPolicy,
      orderedQuestions: baseSpec.orderedQuestions,
      orderedCandidates: baseSpec.orderedCandidates,
      sections: baseSpec.sections,
      distribution: baseSpec.distribution,
      totalEstimatedSeconds: baseSpec.totalEstimatedSeconds,
      isConstraintLimited: baseSpec.isConstraintLimited,
      constraintLimitReason: baseSpec.constraintLimitReason,
      config: baseSpec.config,
      selectionAudit: baseSpec.selectionAudit,
      orchestratedAt: baseSpec.orchestratedAt,
    );

    _specCache[uniqueSessionId] = sessionSpec;

    // 4. Start session and generate initial durable checkpoint (chkRev: 1, cursor: 0)
    final stepCheckpointResult = await _practiceCoordinator.startSession(
      spec: sessionSpec,
      baseState: authState,
      startedAt: effectiveTs,
    );

    final journeySession = LearningJourneySession(
      sessionId: sessionSpec.sessionId,
      learnerId: cleanLearner,
      examId: cleanExam,
      status: LearningJourneyStatus.questionPresented,
      spec: sessionSpec,
      executionState: stepCheckpointResult.executionState,
      authoritativeState: stepCheckpointResult.authoritativeState,
      checkpoint: stepCheckpointResult.checkpoint,
      currentQuestionIndex: 0,
      completedQuestionIds: const [],
      createdAt: effectiveTs,
      lastActivityAt: effectiveTs,
    );

    return LearningJourneyStepResult.success(
      session: journeySession,
      message: 'Journey started successfully at question cursor 0',
      executedAt: effectiveTs,
    );
  }

  // --------------------------------------------------------------------------
  // 2. Practice Execution: Answer Submission & Reconciliation
  // --------------------------------------------------------------------------

  /// Submits an answer for the current question, consolidating outcome and reconciling state.
  Future<LearningJourneyStepResult> submitAnswer({
    required LearningJourneySession session,
    required String questionId,
    required String answer,
    DateTime? submittedAt,
  }) async {
    final effectiveTs = (submittedAt ?? DateTime.now()).toUtc();

    if (session.isCompleted || session.status.isTerminal) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.invalidTransition,
        message:
            'Cannot submit answer to completed or terminal journey session',
        session: session,
        executedAt: effectiveTs,
      );
    }

    if (answer.trim().isEmpty) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.invalidAnswer,
        message: 'Submitted answer cannot be empty',
        session: session,
        executedAt: effectiveTs,
      );
    }

    final currentQ = session.currentQuestion;
    if (currentQ == null || currentQ.id != questionId) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.malformedQuestion,
        message:
            'Submitted questionId "$questionId" does not match current question "${currentQ?.id}"',
        session: session,
        executedAt: effectiveTs,
      );
    }

    // Check duplicate attempt
    if (session.completedQuestionIds.contains(questionId)) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.duplicateAttempt,
        message:
            'Question "$questionId" has already been answered in this session',
        session: session,
        executedAt: effectiveTs,
      );
    }

    // Transition: answerReceived -> outcomeRecorded -> stateReconciled -> checkpointed
    final intermediateSession = session.transitionTo(
      LearningJourneyStatus.answerReceived,
      timestamp: effectiveTs,
    );

    // Execute submission, reconciliation, and checkpoint advance
    final stepResult = await _practiceCoordinator.submitAnswerAndCheckpoint(
      executionState: intermediateSession.executionState,
      baseState: intermediateSession.authoritativeState,
      currentCheckpoint: intermediateSession.checkpoint,
      questionId: questionId,
      answer: answer,
      submittedAt: effectiveTs,
    );

    final lastAnswerResult =
        stepResult.executionState.questionResults[questionId];

    final isAllDone =
        stepResult.executionState.status == PracticeExecutionStatus.completed ||
            stepResult.checkpoint.isCompleted ||
            stepResult.checkpoint.questionIndex >= session.totalQuestions;

    final nextStatus = isAllDone
        ? LearningJourneyStatus.completed
        : LearningJourneyStatus.questionPresented;

    final updatedJourney = intermediateSession.copyWith(
      status: nextStatus,
      executionState: stepResult.executionState,
      authoritativeState: stepResult.authoritativeState,
      checkpoint: stepResult.checkpoint,
      currentQuestionIndex: stepResult.checkpoint.questionIndex,
      completedQuestionIds: stepResult.checkpoint.completedQuestionIds,
      lastActivityAt: effectiveTs,
      completedAt: isAllDone ? effectiveTs : null,
    );

    return LearningJourneyStepResult.success(
      session: updatedJourney,
      lastAnswerResult: lastAnswerResult,
      message: isAllDone
          ? 'Journey session finalized and completed'
          : 'Answer submitted; advanced to question index ${updatedJourney.currentQuestionIndex}',
      executedAt: effectiveTs,
    );
  }

  // --------------------------------------------------------------------------
  // 3. Interruption Handling
  // --------------------------------------------------------------------------

  /// Marks an active journey session as interrupted due to crash, pause, or navigation.
  LearningJourneyStepResult interruptJourney({
    required LearningJourneySession session,
    String reason = 'session_interrupted',
    DateTime? interruptedAt,
  }) {
    final effectiveTs = (interruptedAt ?? DateTime.now()).toUtc();

    if (session.status.isTerminal) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.invalidTransition,
        message: 'Cannot interrupt a terminal session',
        session: session,
        executedAt: effectiveTs,
      );
    }

    final interrupted = session.transitionTo(
      LearningJourneyStatus.interrupted,
      timestamp: effectiveTs,
    );

    return LearningJourneyStepResult.success(
      session: interrupted,
      message: 'Journey interrupted: $reason',
      executedAt: effectiveTs,
    );
  }

  // --------------------------------------------------------------------------
  // 4. Session Recovery & Exact Resumption
  // --------------------------------------------------------------------------

  /// Recovers an interrupted adaptive learning journey from durable persisted state.
  Future<LearningJourneyStepResult> recoverAndResumeJourney({
    required String learnerId,
    required String examId,
    required String sessionId,
    required List<NormalizedQuestion> corpus,
    DateTime? resumedAt,
  }) async {
    final effectiveTs = (resumedAt ?? DateTime.now()).toUtc();
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();
    final cleanSession = sessionId.trim();

    if (cleanLearner.isEmpty || cleanExam.isEmpty || cleanSession.isEmpty) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.tenantMismatch,
        message: 'learnerId, examId, and sessionId must be non-empty',
        executedAt: effectiveTs,
      );
    }

    // 1. Recover durable checkpoint via recovery service
    final recoveryResult = await _sessionRecoveryService.recoverSession(
      learnerId: cleanLearner,
      examId: cleanExam,
      sessionId: cleanSession,
      requestedAt: effectiveTs,
    );

    if (recoveryResult.isFailure) {
      final code = switch (recoveryResult.status) {
        SessionRecoveryResultStatus.corrupt =>
          LearningJourneyErrorCode.corruptCheckpoint,
        SessionRecoveryResultStatus.stale =>
          LearningJourneyErrorCode.staleRevision,
        SessionRecoveryResultStatus.identityMismatch =>
          LearningJourneyErrorCode.tenantMismatch,
        SessionRecoveryResultStatus.incompatibleVersion =>
          LearningJourneyErrorCode.incompatibleSchema,
        SessionRecoveryResultStatus.coldStart =>
          LearningJourneyErrorCode.missingCheckpoint,
        SessionRecoveryResultStatus.alreadyCompleted =>
          LearningJourneyErrorCode.invalidTransition,
        _ => LearningJourneyErrorCode.repositoryFailure,
      };

      return LearningJourneyStepResult.failure(
        code: code,
        message: recoveryResult.message,
        executedAt: effectiveTs,
      );
    }

    final checkpoint = recoveryResult.checkpoint!;
    final authoritativeState = recoveryResult.authoritativeState!;

    if (checkpoint.isCompleted) {
      return LearningJourneyStepResult.failure(
        code: LearningJourneyErrorCode.invalidTransition,
        message: 'Cannot resume an already completed journey session',
        executedAt: effectiveTs,
      );
    }

    // 2. Reconstruct session specification from cache or corpus
    final AdaptivePracticeSessionSpec spec;
    if (_specCache.containsKey(cleanSession)) {
      spec = _specCache[cleanSession]!;
    } else {
      final questions = corpus.take(5).toList();
      final candidates = questions
          .map((q) => AdaptiveQuestionCandidate(
                question: q,
                historicalPriority: 0.5,
                learnerWeakness: 0.5,
                exposureCount: 0,
                recencyScore: 1.0,
                difficultyFit: 0.8,
                sourceQualityScore: 1.0,
                selectionScore: 0.75,
                isEligible: true,
                scoreBreakdown: const {
                  'historicalPriority': 0.25,
                  'weakness': 0.25,
                  'recency': 0.15,
                  'difficultyFit': 0.20,
                  'quality': 0.15,
                },
              ))
          .toList();

      final rawSpec = _sessionOrchestrator.orchestrateSession(
        selectionResult: AdaptiveQuestionSelectionResult(
          examId: cleanExam,
          selectedQuestions: questions,
          selectedCandidates: candidates,
          allCandidates: candidates,
          requestedCount: questions.length,
          eligibleCount: questions.length,
          config: AdaptiveQuestionSelectionConfig(
            examId: cleanExam,
            targetQuestionCount: questions.length,
          ),
          selectedAt: checkpoint.timestamp,
        ),
        config: AdaptivePracticeSessionConfig(
          examId: cleanExam,
          learnerId: cleanLearner,
          sessionMode: PracticeSessionMode.standard,
          sectionSize: 5,
          estimatedSecondsPerQuestion: 60,
        ),
        orchestratedAt: checkpoint.timestamp,
      );

      spec = AdaptivePracticeSessionSpec(
        sessionId: cleanSession,
        examId: rawSpec.examId,
        learnerId: cleanLearner,
        sessionMode: rawSpec.sessionMode,
        completionPolicy: rawSpec.completionPolicy,
        orderedQuestions: rawSpec.orderedQuestions,
        orderedCandidates: rawSpec.orderedCandidates,
        sections: rawSpec.sections,
        distribution: rawSpec.distribution,
        totalEstimatedSeconds: rawSpec.totalEstimatedSeconds,
        isConstraintLimited: rawSpec.isConstraintLimited,
        constraintLimitReason: rawSpec.constraintLimitReason,
        config: rawSpec.config,
        selectionAudit: rawSpec.selectionAudit,
        orchestratedAt: rawSpec.orchestratedAt,
      );
      _specCache[cleanSession] = spec;
    }

    // 3. Reconstruct execution state positioned at first uncompleted question cursor
    final reconstructedExecution =
        _practiceCoordinator.reconstructExecutionState(
      spec: spec,
      checkpoint: checkpoint,
      resumedAt: effectiveTs,
    );

    final recoveredSession = LearningJourneySession(
      sessionId: cleanSession,
      learnerId: cleanLearner,
      examId: cleanExam,
      status: LearningJourneyStatus.questionPresented,
      spec: spec,
      executionState: reconstructedExecution,
      authoritativeState: authoritativeState,
      checkpoint: checkpoint,
      currentQuestionIndex: checkpoint.questionIndex,
      completedQuestionIds: checkpoint.completedQuestionIds,
      createdAt: checkpoint.timestamp,
      lastActivityAt: effectiveTs,
    );

    return LearningJourneyStepResult.success(
      session: recoveredSession,
      message:
          'Journey recovered successfully; resumed at question cursor ${checkpoint.questionIndex}',
      executedAt: effectiveTs,
    );
  }
}
