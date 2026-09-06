/// Adaptive Learning Session Orchestrator (TITAN-KO-040.0 P40).
///
/// Production orchestrator coordinating the complete crash-safe adaptive learning
/// session lifecycle: Session Start -> Question Delivery -> Attempt Recording ->
/// Outcome Consolidation -> State Reconciliation -> Authoritative Persistence ->
/// Checkpointing -> Recovery -> Resumption -> Completion.
library;

import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:meta/meta.dart';

import '../domain/entities/adaptive_learning_session.dart';
import '../domain/entities/adaptive_practice_session_config.dart';
import '../domain/entities/adaptive_question_selection_config.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';
import '../domain/entities/practice_execution_state.dart';
import '../domain/entities/pyq_learning_priority_profile.dart';
import '../domain/entities/resumable_learning_session.dart';
import '../domain/entities/session_checkpoint.dart';
import '../domain/entities/session_checkpoint_exceptions.dart';
import '../domain/entities/session_recovery_error.dart';
import '../domain/entities/session_recovery_result.dart';
import '../domain/entities/session_status.dart';
import '../domain/entities/weak_spot_profile.dart';
import '../repository/adaptive_learning_session_repository.dart';
import '../repository/authoritative_learning_state_repository.dart';
import '../service/adaptive_question_selection_service.dart';
import '../service/authoritative_learning_state_recovery_service.dart';

/// Question delivery container returned by [AdaptiveLearningSessionOrchestrator.getNextQuestion].
@immutable
class SessionQuestionDelivery {
  /// The selected question.
  final NormalizedQuestion question;

  /// 0-based question sequence index within this session.
  final int questionIndex;

  /// Total number of questions scheduled in the session.
  final int totalQuestions;

  /// Target learning objective ID for this question.
  final String activeObjectiveId;

  /// Whether this is the final question planned for the session.
  final bool isLastQuestion;

  const SessionQuestionDelivery({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.activeObjectiveId,
    required this.isLastQuestion,
  });
}

/// Result returned by [AdaptiveLearningSessionOrchestrator.recordAttempt].
@immutable
class SessionAttemptResult {
  /// Updated session domain model.
  final AdaptiveLearningSession session;

  /// Newly persisted checkpoint snapshot.
  final SessionCheckpoint checkpoint;

  /// Latest authoritative learner state.
  final AuthoritativeLearnerState authoritativeState;

  /// Whether the submitted answer was correct.
  final bool isCorrect;

  /// Feedback object containing evaluation details.
  final PracticeFeedback feedback;

  /// Whether this attempt finalized the session.
  final bool isSessionCompleted;

  const SessionAttemptResult({
    required this.session,
    required this.checkpoint,
    required this.authoritativeState,
    required this.isCorrect,
    required this.feedback,
    required this.isSessionCompleted,
  });
}

/// Dedicated orchestrator coordinating the adaptive learning session lifecycle.
class AdaptiveLearningSessionOrchestrator {
  final AdaptiveLearningSessionRepository _sessionRepository;
  final AdaptiveQuestionSelectionService _questionSelector;
  final AuthoritativeLearningStateRecoveryService _authoritativeRecoveryService;
  final AuthoritativeLearningStateRepository _authoritativeRepository;

  /// In-memory question cache mapping "$learnerId:$examId:$sessionId" to ordered question sequence.
  final Map<String, List<NormalizedQuestion>> _sessionQuestions = {};

  AdaptiveLearningSessionOrchestrator({
    required AdaptiveLearningSessionRepository sessionRepository,
    AdaptiveQuestionSelectionService questionSelector =
        const AdaptiveQuestionSelectionService(),
    required AuthoritativeLearningStateRecoveryService
        authoritativeRecoveryService,
    required AuthoritativeLearningStateRepository authoritativeRepository,
  })  : _sessionRepository = sessionRepository,
        _questionSelector = questionSelector,
        _authoritativeRecoveryService = authoritativeRecoveryService,
        _authoritativeRepository = authoritativeRepository;

  static String _sessionKey(
          String learnerId, String examId, String sessionId) =>
      '${learnerId.trim()}:${examId.trim().toLowerCase()}:${sessionId.trim()}';

  // ---------------------------------------------------------------------------
  // 1. Session Start
  // ---------------------------------------------------------------------------

  /// Starts a new adaptive learning session, selects questions, and establishes initial checkpoint.
  Future<AdaptiveLearningSession> startSession({
    required String sessionId,
    required String learnerId,
    required String examId,
    required AdaptivePracticeSessionConfig configuration,
    required List<NormalizedQuestion> corpus,
    PyqLearningPriorityProfile? pyqPriorityProfile,
    WeakSpotProfile? weakSpotProfile,
    DateTime? startedAt,
  }) async {
    final effectiveTs = (startedAt ?? DateTime.now()).toUtc();
    final normalizedSessionId = sessionId.trim();
    final normalizedLearnerId = learnerId.trim();
    final normalizedExamId = examId.trim().toLowerCase();

    if (normalizedSessionId.isEmpty) {
      throw ArgumentError('sessionId cannot be empty');
    }
    if (normalizedLearnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (normalizedExamId.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (corpus.isEmpty) {
      throw ArgumentError('Corpus cannot be empty for session start');
    }

    // 1. Recover or initialize authoritative learner state
    final authResult = await _authoritativeRecoveryService.recover(
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      requestedAt: effectiveTs,
      persistInitialIfAbsent: true,
    );

    final baseAuth = authResult.state ??
        AuthoritativeLearnerState.empty(
          learnerId: normalizedLearnerId,
          examId: normalizedExamId,
          createdAt: effectiveTs,
          revision: 1,
        );

    // 2. Select questions via P33 Question Selector
    final selectionConfig = AdaptiveQuestionSelectionConfig(
      examId: normalizedExamId,
      targetQuestionCount: configuration.maxQuestions ?? 5,
    );

    final selectionResult = _questionSelector.selectQuestions(
      corpus: corpus,
      config: selectionConfig,
      pyqPriorityProfile: pyqPriorityProfile,
      weakSpotProfile: weakSpotProfile,
      progressList: baseAuth.progressMap.values.toList(),
      selectedAt: effectiveTs,
    );

    List<NormalizedQuestion> selectedQuestions =
        selectionResult.selectedQuestions;
    if (selectedQuestions.isEmpty) {
      // Fallback to slicing from corpus deterministically
      final limit = (configuration.maxQuestions ?? 5).clamp(1, corpus.length);
      selectedQuestions = corpus.take(limit).toList();
    }

    final totalPlanned = selectedQuestions.length;
    final firstObjectiveId = selectedQuestions.first.objectiveIds.isNotEmpty
        ? selectedQuestions.first.objectiveIds.first
        : 'lo_general';

    // 3. Create Session Entity
    final session = AdaptiveLearningSession(
      sessionId: normalizedSessionId,
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      startedAt: effectiveTs,
      lastActivityAt: effectiveTs,
      status: SessionStatus.created,
      configuration: configuration,
      totalQuestionsPlanned: totalPlanned,
      currentLearningStateRevision: baseAuth.revision,
      checkpointRevision: 1,
    );

    // Transition created -> active
    final activeSession = session.transitionTo(
      SessionStatus.active,
      timestamp: effectiveTs,
    );

    // 4. Persist Session & Initial Checkpoint (revision 1)
    await _sessionRepository.createSession(activeSession);

    final initialCheckpoint = SessionCheckpoint(
      checkpointRevision: 1,
      authoritativeStateRevision: baseAuth.revision,
      sessionId: normalizedSessionId,
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      questionIndex: 0,
      completedQuestionIds: const [],
      activeObjectiveId: firstObjectiveId,
      timestamp: effectiveTs,
      isCompleted: false,
    );

    await _sessionRepository.saveCheckpoint(initialCheckpoint);

    // 5. Cache ordered question sequence
    final key =
        _sessionKey(normalizedLearnerId, normalizedExamId, normalizedSessionId);
    _sessionQuestions[key] =
        List<NormalizedQuestion>.unmodifiable(selectedQuestions);

    return activeSession;
  }

  // ---------------------------------------------------------------------------
  // 2. Question Delivery
  // ---------------------------------------------------------------------------

  /// Delivers the next question for an active session.
  ///
  /// Returns `null` if all planned questions have been answered.
  /// Throws [SessionNotFoundException] if session does not exist.
  /// Throws [SessionOwnershipException] if caller does not own the session.
  /// Throws [CompletedSessionMutationException] if session is already completed.
  Future<SessionQuestionDelivery?> getNextQuestion({
    required String learnerId,
    required String examId,
    required String sessionId,
    List<NormalizedQuestion>? corpus,
  }) async {
    final session = await _validateAndGetSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );

    if (session.isCompleted) {
      throw CompletedSessionMutationException(
        message:
            'Cannot request next question for completed session "$sessionId"',
        sessionId: sessionId,
      );
    }

    final pos = session.currentQuestionPosition;
    if (pos >= session.totalQuestionsPlanned) {
      return null;
    }

    final key = _sessionKey(learnerId, examId, sessionId);
    List<NormalizedQuestion>? questions = _sessionQuestions[key];

    if (questions == null && corpus != null && corpus.isNotEmpty) {
      questions = corpus;
      _sessionQuestions[key] = corpus;
    }

    if (questions == null || pos >= questions.length) {
      return null;
    }

    final q = questions[pos];
    final activeObjective =
        q.objectiveIds.isNotEmpty ? q.objectiveIds.first : 'lo_general';

    return SessionQuestionDelivery(
      question: q,
      questionIndex: pos,
      totalQuestions: session.totalQuestionsPlanned,
      activeObjectiveId: activeObjective,
      isLastQuestion: pos == session.totalQuestionsPlanned - 1,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Attempt Recording & Outcome Consolidation
  // ---------------------------------------------------------------------------

  /// Submits an attempt, reconciles state with P38/P39, saves checkpoint, and advances cursor.
  ///
  /// Throws [DuplicateAttemptException] if attempt for question was already answered.
  /// Throws [CompletedSessionMutationException] if session is already finished.
  Future<SessionAttemptResult> recordAttempt({
    required String learnerId,
    required String examId,
    required String sessionId,
    required String questionId,
    required String submittedAnswer,
    required NormalizedQuestion question,
    DateTime? submittedAt,
    int responseTimeSeconds = 0,
  }) async {
    final effectiveTs = (submittedAt ?? DateTime.now()).toUtc();
    final session = await _validateAndGetSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );

    if (session.isCompleted) {
      throw CompletedSessionMutationException(
        message: 'Cannot submit attempt to completed session "$sessionId"',
        sessionId: sessionId,
      );
    }

    // Deduplication Guard: duplicate attempt on already answered question
    if (session.completedQuestions.contains(questionId)) {
      throw DuplicateAttemptException(
        message:
            'Question "$questionId" was already completed in session "$sessionId"',
        attemptToken: '$sessionId:$questionId:1',
        details: {'sessionId': sessionId, 'questionId': questionId},
      );
    }

    // 1. Evaluate correctness
    final isCorrect = question.officialAnswer.correctOptionKeys
            .contains(submittedAnswer.trim().toUpperCase()) ||
        question.officialAnswer.correctOptionKeys
            .contains(submittedAnswer.trim());

    final correctAnswerStr =
        question.officialAnswer.correctOptionKeys.join(',');
    final feedback = PracticeFeedback(
      questionId: questionId,
      isCorrect: isCorrect,
      submittedAnswer: submittedAnswer,
      correctAnswer: correctAnswerStr,
      explanation: 'Official explanation for question $questionId',
      isExplanationExposed: true,
      evaluationMethod: EvaluationMethod.multipleChoice,
    );

    // 2. Authoritative State Loading & Reconciliation (Phase 7-8)
    final authResult = await _authoritativeRecoveryService.recover(
      learnerId: learnerId,
      examId: examId,
      requestedAt: effectiveTs,
    );
    final authState = authResult.state ??
        AuthoritativeLearnerState.empty(
          learnerId: learnerId,
          examId: examId,
          createdAt: effectiveTs,
        );

    final targetObjectiveId = question.objectiveIds.isNotEmpty
        ? question.objectiveIds.first
        : 'lo_general';
    final existingProgress = authState.progressMap[targetObjectiveId];
    final prevAttempts = existingProgress?.attemptCount ?? 0;
    final prevCorrect = existingProgress?.correctCount ?? 0;
    final newAttempts = prevAttempts + 1;
    final newCorrect = prevCorrect + (isCorrect ? 1 : 0);

    final updatedObjectiveProgress = LearnerProgress(
      learnerId: learnerId,
      objectiveId: targetObjectiveId,
      attemptCount: newAttempts,
      correctCount: newCorrect,
      lastAttemptAt: effectiveTs,
      status: newCorrect >= 3
          ? LearnerObjectiveStatus.achieved
          : LearnerObjectiveStatus.inProgress,
      achievedAt: newCorrect >= 3
          ? (existingProgress?.achievedAt ?? effectiveTs)
          : null,
    );

    final nextAuthRevision = authState.revision + 1;
    final updatedProgressMap =
        Map<String, LearnerProgress>.from(authState.progressMap)
          ..[targetObjectiveId] = updatedObjectiveProgress;

    final updatedAuthState = AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: updatedProgressMap,
      processedSessionIds: authState.processedSessionIds,
      lastUpdatedAt: effectiveTs,
      revision: nextAuthRevision,
    );

    // 3. Persist Authoritative State Atomically
    final persistedAuth =
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(
      updatedAuthState,
      revision: nextAuthRevision,
    );
    await _authoritativeRepository.save(persistedAuth);

    // 4. Advance Session Coordinates
    final advancedSession = session.advanceQuestion(
      questionId: questionId,
      timestamp: effectiveTs,
    );

    final isSessionFinished = advancedSession.currentQuestionPosition >=
        advancedSession.totalQuestionsPlanned;
    final nextCheckpointRevision = session.checkpointRevision + 1;

    final updatedSession = isSessionFinished
        ? advancedSession.copyWith(
            status: SessionStatus.completed,
            currentLearningStateRevision: nextAuthRevision,
            checkpointRevision: nextCheckpointRevision,
            lastActivityAt: effectiveTs,
            completionMetadata: {
              ...advancedSession.completionMetadata,
              'completedAt': effectiveTs.toIso8601String(),
              'reason': 'All planned questions completed',
            },
          )
        : advancedSession.copyWith(
            currentLearningStateRevision: nextAuthRevision,
            checkpointRevision: nextCheckpointRevision,
            lastActivityAt: effectiveTs,
          );

    // 5. Create & Save Checkpoint (Phase 9)
    final checkpoint = SessionCheckpoint(
      checkpointRevision: nextCheckpointRevision,
      authoritativeStateRevision: nextAuthRevision,
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: advancedSession.currentQuestionPosition,
      completedQuestionIds: advancedSession.completedQuestions,
      activeObjectiveId: targetObjectiveId,
      timestamp: effectiveTs,
      isCompleted: isSessionFinished,
    );

    await _sessionRepository.saveCheckpoint(checkpoint);

    // 6. Update Session in Repository
    await _sessionRepository.updateSession(updatedSession);

    return SessionAttemptResult(
      session: updatedSession,
      checkpoint: checkpoint,
      authoritativeState: updatedAuthState,
      isCorrect: isCorrect,
      feedback: feedback,
      isSessionCompleted: isSessionFinished,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Pause & Interruption
  // ---------------------------------------------------------------------------

  /// Pauses an active session and saves durable checkpoint.
  Future<AdaptiveLearningSession> pauseSession({
    required String learnerId,
    required String examId,
    required String sessionId,
    DateTime? pausedAt,
  }) async {
    final effectiveTs = (pausedAt ?? DateTime.now()).toUtc();
    final session = await _validateAndGetSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );

    final pausedSession = session.transitionTo(
      SessionStatus.paused,
      timestamp: effectiveTs,
    );

    final nextCheckpointRevision = session.checkpointRevision + 1;
    final updatedSession = pausedSession.copyWith(
      checkpointRevision: nextCheckpointRevision,
    );

    final latestCheckpoint = await _sessionRepository.getLatestCheckpoint(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );

    final checkpoint = SessionCheckpoint(
      checkpointRevision: nextCheckpointRevision,
      authoritativeStateRevision: session.currentLearningStateRevision,
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: session.currentQuestionPosition,
      completedQuestionIds: session.completedQuestions,
      activeObjectiveId: latestCheckpoint?.activeObjectiveId ?? 'lo_general',
      timestamp: effectiveTs,
      isCompleted: false,
    );

    await _sessionRepository.saveCheckpoint(checkpoint);
    await _sessionRepository.updateSession(updatedSession);

    return updatedSession;
  }

  // ---------------------------------------------------------------------------
  // 5. Recovery
  // ---------------------------------------------------------------------------

  /// Recovers an interrupted session, validating checkpoint integrity and revision alignment.
  Future<SessionRecoveryResult> recoverSession({
    required String learnerId,
    required String examId,
    required String sessionId,
    DateTime? requestedAt,
  }) async {
    final effectiveTs = (requestedAt ?? DateTime.now()).toUtc();
    final normalizedSessionId = sessionId.trim();
    final normalizedLearnerId = learnerId.trim();
    final normalizedExamId = examId.trim().toLowerCase();

    // 1. Load session from repository
    final session = await _sessionRepository.getSession(
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      sessionId: normalizedSessionId,
    );

    if (session == null) {
      return SessionRecoveryResult.coldStart(
        learnerId: normalizedLearnerId,
        examId: normalizedExamId,
        sessionId: normalizedSessionId,
      );
    }

    // 2. Multi-tenant isolation verification
    if (session.learnerId != normalizedLearnerId ||
        session.examId != normalizedExamId) {
      return SessionRecoveryResult.identityMismatch(
        expectedLearner: normalizedLearnerId,
        foundLearner: session.learnerId,
        sessionId: normalizedSessionId,
      );
    }

    // 3. Load latest checkpoint
    final checkpoint = await _sessionRepository.getLatestCheckpoint(
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      sessionId: normalizedSessionId,
    );

    if (checkpoint == null) {
      return SessionRecoveryResult.corrupt(
        sessionId: normalizedSessionId,
        reason: 'Session exists but no valid checkpoint was found',
      );
    }

    // 4. Check for completed or terminal status
    if (session.status == SessionStatus.completed || checkpoint.isCompleted) {
      return SessionRecoveryResult.alreadyCompleted(
        checkpoint: checkpoint,
      );
    }

    if (session.status == SessionStatus.abandoned ||
        session.status == SessionStatus.failed) {
      return SessionRecoveryResult.notRecoverable(
        sessionId: normalizedSessionId,
        reason: 'Session is in non-recoverable state: ${session.status.name}',
      );
    }

    // 5. Recover Authoritative State
    final authResult = await _authoritativeRecoveryService.recover(
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      requestedAt: effectiveTs,
    );

    final authState = authResult.state ??
        AuthoritativeLearnerState.empty(
          learnerId: normalizedLearnerId,
          examId: normalizedExamId,
          createdAt: effectiveTs,
        );

    // 6. Monotonic revision check
    if (checkpoint.checkpointRevision < authState.revision) {
      return SessionRecoveryResult.stale(
        sessionId: normalizedSessionId,
        checkpointRevision: checkpoint.checkpointRevision,
        authoritativeRevision: authState.revision,
      );
    }

    // 7. Reconstruct ResumableLearningSession from checkpoint
    final resumableSession = ResumableLearningSession.fromCheckpoint(
      checkpoint: checkpoint,
      resumedAt: effectiveTs,
    );

    return SessionRecoveryResult.success(
      session: resumableSession,
      authoritativeState: authState,
      checkpoint: checkpoint,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Resumption
  // ---------------------------------------------------------------------------

  /// Resumes a recovered/paused session at the exact cursor position.
  Future<AdaptiveLearningSession> resumeSession({
    required String learnerId,
    required String examId,
    required String sessionId,
    DateTime? resumedAt,
  }) async {
    final effectiveTs = (resumedAt ?? DateTime.now()).toUtc();
    final recovery = await recoverSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
      requestedAt: effectiveTs,
    );

    if (!recovery.isSuccess || recovery.session == null) {
      throw recovery.error ??
          SessionRecoveryException(
            code: SessionRecoveryErrorCode.unknownFailure,
            message: recovery.message,
          );
    }

    final session = await _validateAndGetSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );

    final resumedSession = session.transitionTo(
      SessionStatus.active,
      timestamp: effectiveTs,
    );

    final nextCheckpointRevision = session.checkpointRevision + 1;
    final updatedSession = resumedSession.copyWith(
      checkpointRevision: nextCheckpointRevision,
    );

    final checkpoint = SessionCheckpoint(
      checkpointRevision: nextCheckpointRevision,
      authoritativeStateRevision: session.currentLearningStateRevision,
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: session.currentQuestionPosition,
      completedQuestionIds: session.completedQuestions,
      activeObjectiveId: recovery.checkpoint?.activeObjectiveId ?? 'lo_general',
      timestamp: effectiveTs,
      isCompleted: false,
    );

    await _sessionRepository.saveCheckpoint(checkpoint);
    await _sessionRepository.updateSession(updatedSession);

    return updatedSession;
  }

  // ---------------------------------------------------------------------------
  // 7. Completion
  // ---------------------------------------------------------------------------

  /// Finalizes a session with strict completion ordering guarantees.
  Future<AdaptiveLearningSession> completeSession({
    required String learnerId,
    required String examId,
    required String sessionId,
    DateTime? completedAt,
    Map<String, dynamic>? completionMetadata,
  }) async {
    final effectiveTs = (completedAt ?? DateTime.now()).toUtc();
    final session = await _validateAndGetSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );

    // Idempotent no-op if already completed
    if (session.isCompleted) {
      return session;
    }

    // 1. Authoritative State Incorporation (Ordering Guarantee)
    final authResult = await _authoritativeRecoveryService.recover(
      learnerId: learnerId,
      examId: examId,
      requestedAt: effectiveTs,
    );
    final authState = authResult.state!;
    final nextAuthRevision = authState.revision + 1;

    final updatedAuth = AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: authState.progressMap,
      processedSessionIds: {...authState.processedSessionIds, sessionId},
      lastUpdatedAt: effectiveTs,
      revision: nextAuthRevision,
    );

    await _authoritativeRepository.save(
      PersistedAuthoritativeLearnerState.fromAuthoritativeState(
        updatedAuth,
        revision: nextAuthRevision,
      ),
    );

    // 2. Save Final Checkpoint
    final nextCheckpointRevision = session.checkpointRevision + 1;
    final latestCheckpoint = await _sessionRepository.getLatestCheckpoint(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );

    final finalCheckpoint = SessionCheckpoint(
      checkpointRevision: nextCheckpointRevision,
      authoritativeStateRevision: nextAuthRevision,
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: session.currentQuestionPosition,
      completedQuestionIds: session.completedQuestions,
      activeObjectiveId: latestCheckpoint?.activeObjectiveId ?? 'lo_general',
      timestamp: effectiveTs,
      isCompleted: true,
    );

    await _sessionRepository.saveCheckpoint(finalCheckpoint);

    // 3. Mark Completed in Session Repository
    await _sessionRepository.markCompleted(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
      completedAt: effectiveTs,
      completionMetadata: completionMetadata,
    );

    return (await _sessionRepository.getSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    ))!;
  }

  // ---------------------------------------------------------------------------
  // 8. Abandonment
  // ---------------------------------------------------------------------------

  /// Marks a session as explicitly abandoned.
  Future<AdaptiveLearningSession> abandonSession({
    required String learnerId,
    required String examId,
    required String sessionId,
    DateTime? abandonedAt,
    String? reason,
  }) async {
    final effectiveTs = (abandonedAt ?? DateTime.now()).toUtc();
    await _validateAndGetSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );

    await _sessionRepository.markAbandoned(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
      abandonedAt: effectiveTs,
      reason: reason,
    );

    return (await _sessionRepository.getSession(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    ))!;
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  Future<AdaptiveLearningSession> _validateAndGetSession({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    final normalizedSessionId = sessionId.trim();
    final normalizedLearnerId = learnerId.trim();
    final normalizedExamId = examId.trim().toLowerCase();

    final session = await _sessionRepository.getSession(
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      sessionId: normalizedSessionId,
    );

    if (session == null) {
      throw SessionNotFoundException(
        message:
            'Adaptive learning session "$normalizedSessionId" was not found',
        sessionId: normalizedSessionId,
      );
    }

    if (session.learnerId != normalizedLearnerId ||
        session.examId != normalizedExamId) {
      throw SessionOwnershipException(
        message:
            'Tenant ownership violation: requested by $normalizedLearnerId:$normalizedExamId but owned by ${session.learnerId}:${session.examId}',
        expectedLearner: session.learnerId,
        actualLearner: normalizedLearnerId,
        details: {'sessionId': normalizedSessionId},
      );
    }

    return session;
  }
}
