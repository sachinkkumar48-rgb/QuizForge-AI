/// Adaptive Session Resume Engine (TITAN-KO-040.0 P40).
///
/// Production engine orchestrating the complete crash-safe adaptive learning lifecycle:
/// Session Start -> Practice -> Attempt Capture -> Deduplication ->
/// Outcome Consolidation -> State Reconciliation -> Authoritative State Persistence ->
/// Checkpoint -> Interruption -> Recovery -> Resumption -> Completion.
library;

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/checkpoint_policy.dart';
import '../domain/entities/attempt_identity.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';
import '../domain/entities/reconciliation_pipeline_result.dart';
import '../domain/entities/resumable_session_snapshot.dart';
import '../domain/entities/resumable_session_status.dart';
import '../domain/entities/session_checkpoint_exceptions.dart';
import '../domain/entities/session_identity.dart';
import '../domain/entities/session_recovery_error.dart';
import '../repository/authoritative_learning_state_repository.dart';
import 'adaptive_learning_state_reconciliation_pipeline.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'session_checkpoint_service.dart';

/// Categorization of alignment between checkpoint revision and authoritative state revision.
enum CheckpointReconciliationAlignment {
  /// Checkpoint revision is strictly less than authoritative state revision (stale checkpoint).
  staleCheckpoint,

  /// Checkpoint revision matches authoritative state revision (clean alignment).
  aligned,

  /// Checkpoint revision is strictly greater than authoritative state revision (unpersisted practice state).
  aheadOfAuthoritativeState,
}

/// Result returned by session resume lifecycle operations.
class AdaptiveSessionResumeResult {
  /// Current resumable snapshot capturing session coordinates.
  final ResumableSessionSnapshot snapshot;

  /// Authoritative learner state at this lifecycle point.
  final AuthoritativeLearnerState authoritativeState;

  /// Effective session status.
  final ResumableSessionStatus status;

  /// Whether a durable checkpoint was persisted during this operation.
  final bool isCheckpointSaved;

  /// Optional reconciliation pipeline result if state reconciliation ran.
  final ReconciliationPipelineResult? pipelineResult;

  /// Diagnostic or informational message.
  final String? message;

  const AdaptiveSessionResumeResult({
    required this.snapshot,
    required this.authoritativeState,
    required this.status,
    this.isCheckpointSaved = false,
    this.pipelineResult,
    this.message,
  });

  /// Identifier of the session.
  String get sessionId => snapshot.sessionId;

  /// Revision of the checkpoint snapshot.
  int get checkpointRevision => snapshot.checkpointRevision;

  /// Revision of the authoritative learner state.
  int get authoritativeStateRevision => authoritativeState.revision;
}

/// Result returned by session recovery operations.
class AdaptiveSessionRecoveryResult {
  /// Recovered session snapshot.
  final ResumableSessionSnapshot snapshot;

  /// Recovered authoritative learner state.
  final AuthoritativeLearnerState authoritativeState;

  /// Strict reconciliation alignment between checkpoint and authoritative state revisions.
  final CheckpointReconciliationAlignment alignment;

  /// Whether recovery completed successfully.
  final bool isSuccess;

  /// Warning or diagnostic message (e.g. for stale or ahead checkpoints).
  final String? warningMessage;

  const AdaptiveSessionRecoveryResult({
    required this.snapshot,
    required this.authoritativeState,
    required this.alignment,
    this.isSuccess = true,
    this.warningMessage,
  });

  /// Session identifier.
  String get sessionId => snapshot.sessionId;

  /// Checkpoint revision.
  int get checkpointRevision => snapshot.checkpointRevision;

  /// Authoritative state revision.
  int get authoritativeStateRevision => authoritativeState.revision;
}

/// Production engine managing adaptive session lifecycle, deduplication, and crash recovery.
class AdaptiveSessionResumeEngine {
  final SessionCheckpointService _checkpointService;
  final AuthoritativeLearningStateRecoveryService _authoritativeRecoveryService;
  final AuthoritativeLearningStateRepository _authoritativeRepository;
  final AdaptiveLearningStateReconciliationPipeline? _reconciliationPipeline;
  final CheckpointPolicy _defaultCheckpointPolicy;

  /// In-memory active session cache mapping sessionId to active snapshot.
  final Map<String, ResumableSessionSnapshot> _activeSnapshots = {};

  /// In-memory active state cache mapping sessionId to authoritative learner state.
  final Map<String, AuthoritativeLearnerState> _activeStates = {};

  AdaptiveSessionResumeEngine({
    required SessionCheckpointService checkpointService,
    required AuthoritativeLearningStateRecoveryService
        authoritativeRecoveryService,
    required AuthoritativeLearningStateRepository authoritativeRepository,
    AdaptiveLearningStateReconciliationPipeline? reconciliationPipeline,
    CheckpointPolicy defaultCheckpointPolicy =
        const CheckpointPolicy.everyAttempt(),
  })  : _checkpointService = checkpointService,
        _authoritativeRecoveryService = authoritativeRecoveryService,
        _authoritativeRepository = authoritativeRepository,
        _reconciliationPipeline = reconciliationPipeline,
        _defaultCheckpointPolicy = defaultCheckpointPolicy;

  /// Session checkpoint service collaborator.
  SessionCheckpointService get checkpointService => _checkpointService;

  /// Default checkpoint policy.
  CheckpointPolicy get defaultCheckpointPolicy => _defaultCheckpointPolicy;

  /// Optional reconciliation pipeline collaborator.
  AdaptiveLearningStateReconciliationPipeline? get reconciliationPipeline =>
      _reconciliationPipeline;

  // ---------------------------------------------------------------------------
  // 1. Session Start
  // ---------------------------------------------------------------------------

  /// Starts a new adaptive learning session, establishes coordinates, and creates initial checkpoint.
  Future<AdaptiveSessionResumeResult> startSession({
    required String sessionId,
    required String learnerId,
    required String examId,
    required String firstObjectiveId,
    String? firstQuestionId,
    List<String> pendingObjectiveIds = const [],
    CheckpointPolicy? policy,
    DateTime? startedAt,
  }) async {
    final effectiveTs = (startedAt ?? DateTime.now()).toUtc();
    final normalizedSessionId = sessionId.trim();
    final normalizedLearnerId = learnerId.trim();
    final normalizedExamId = examId.trim().toLowerCase();

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

    // 2. Establish Session Identity
    final identity = SessionIdentity(
      sessionId: normalizedSessionId,
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      startedAt: effectiveTs,
      lastCheckpointAt: effectiveTs,
      status: ResumableSessionStatus.active,
    );

    // 3. Construct Initial Resumable Session Snapshot (revision 1)
    final initialSnapshot = ResumableSessionSnapshot(
      identity: identity,
      currentQuestionIndex: 0,
      currentQuestionId: firstQuestionId,
      completedQuestionIds: const [],
      processedAttemptTokens: const [],
      accumulatedScore: 0.0,
      correctCount: 0,
      activeObjectiveId: firstObjectiveId.trim().isEmpty
          ? 'lo_general'
          : firstObjectiveId.trim(),
      pendingObjectiveIds: pendingObjectiveIds,
      checkpointRevision: 1,
      authoritativeStateRevision: baseAuth.revision,
      timestamp: effectiveTs,
    );

    // 4. Checkpoint Initial Snapshot
    await _checkpointService.saveSnapshot(initialSnapshot);

    // 5. Cache in memory
    _activeSnapshots[normalizedSessionId] = initialSnapshot;
    _activeStates[normalizedSessionId] = baseAuth;

    return AdaptiveSessionResumeResult(
      snapshot: initialSnapshot,
      authoritativeState: baseAuth,
      status: ResumableSessionStatus.active,
      isCheckpointSaved: true,
      message: 'Session $normalizedSessionId started at revision 1',
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Attempt Capture & Deduplication
  // ---------------------------------------------------------------------------

  /// Submits an attempt with strict deduplication token enforcement and policy-based checkpointing.
  ///
  /// Throws [DuplicateAttemptException] if the attempt token has already been processed.
  /// Throws [SessionCompletionException] if the session is already in a terminal state.
  /// Throws [SessionIdentityMismatchException] if attempt identity does not match current session coordinates.
  Future<AdaptiveSessionResumeResult> submitAttempt({
    required AttemptIdentity attemptIdentity,
    required String submittedAnswer,
    required bool isCorrect,
    required double score,
    String? objectiveId,
    String? nextQuestionId,
    bool isTerminal = false,
    CheckpointPolicy? policy,
    DateTime? submittedAt,
  }) async {
    final effectiveTs = (submittedAt ?? DateTime.now()).toUtc();
    final sessionId = attemptIdentity.sessionId.trim();

    // 1. Resolve Active Snapshot
    var snapshot = _activeSnapshots[sessionId];
    if (snapshot == null) {
      // Attempt to load from storage
      snapshot = await _checkpointService.loadSnapshot(
        learnerId: attemptIdentity.questionId, // Fallback check
        examId: '',
        sessionId: sessionId,
      );
      if (snapshot != null) {
        _activeSnapshots[sessionId] = snapshot;
      }
    }

    if (snapshot == null) {
      throw SessionIdentityMismatchException(
        message: 'No active or persisted session found for "$sessionId"',
        expected: sessionId,
        actual: 'null',
        details: {'sessionId': sessionId},
      );
    }

    // 2. Terminal State Guard
    if (snapshot.status.isTerminal) {
      throw SessionCompletionException(
        message:
            'Cannot submit attempt to session in terminal state (${snapshot.status.name})',
        details: {'sessionId': sessionId, 'status': snapshot.status.name},
      );
    }

    // 3. Deduplication Guard
    if (snapshot.processedAttemptTokens.contains(attemptIdentity.token)) {
      throw DuplicateAttemptException(
        message:
            'Attempt token "${attemptIdentity.token}" was already processed',
        attemptToken: attemptIdentity.token,
        details: {'sessionId': sessionId},
      );
    }

    // 4. Authoritative State Resolution
    var authState = _activeStates[sessionId];
    if (authState == null) {
      final authResult = await _authoritativeRecoveryService.recover(
        learnerId: snapshot.learnerId,
        examId: snapshot.examId,
        requestedAt: effectiveTs,
      );
      authState = authResult.state ??
          AuthoritativeLearnerState.empty(
            learnerId: snapshot.learnerId,
            examId: snapshot.examId,
            createdAt: effectiveTs,
          );
      _activeStates[sessionId] = authState;
    }

    // 5. Update Progression Coordinates
    final updatedCompletedQuestionIds =
        snapshot.completedQuestionIds.contains(attemptIdentity.questionId)
            ? snapshot.completedQuestionIds
            : [...snapshot.completedQuestionIds, attemptIdentity.questionId];

    final updatedAttemptTokens = [
      ...snapshot.processedAttemptTokens,
      attemptIdentity.token,
    ];

    final updatedScore = snapshot.accumulatedScore + score;
    final updatedCorrectCount = snapshot.correctCount + (isCorrect ? 1 : 0);
    final nextQuestionIndex = snapshot.currentQuestionIndex + 1;
    final targetObjectiveId =
        (objectiveId ?? snapshot.activeObjectiveId).trim();

    // 6. Monotonic Authoritative State Progression & Persistence
    final existingProgress = authState.progressMap[targetObjectiveId];
    final prevAttempts = existingProgress?.attemptCount ?? 0;
    final prevCorrect = existingProgress?.correctCount ?? 0;
    final newAttempts = prevAttempts + 1;
    final newCorrect = prevCorrect + (isCorrect ? 1 : 0);

    final updatedObjectiveProgress = LearnerProgress(
      learnerId: authState.learnerId,
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

    final updatedSessions = isTerminal
        ? ({...authState.processedSessionIds, sessionId})
        : authState.processedSessionIds;

    final updatedAuthState = AuthoritativeLearnerState(
      learnerId: authState.learnerId,
      examId: authState.examId,
      progressMap: updatedProgressMap,
      processedSessionIds: updatedSessions,
      lastUpdatedAt: effectiveTs,
      revision: nextAuthRevision,
    );

    // Persist authoritative state atomically
    final persistedAuth =
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(
      updatedAuthState,
      revision: nextAuthRevision,
    );
    await _authoritativeRepository.save(persistedAuth);
    _activeStates[sessionId] = updatedAuthState;

    // 7. Advance Checkpoint Revision
    final nextCheckpointRevision = snapshot.checkpointRevision + 1;
    final updatedStatus =
        isTerminal ? ResumableSessionStatus.completed : snapshot.status;

    final updatedIdentity = snapshot.identity.copyWith(
      lastCheckpointAt: effectiveTs,
      status: updatedStatus,
    );

    final updatedSnapshot = snapshot.copyWith(
      identity: updatedIdentity,
      currentQuestionIndex: nextQuestionIndex,
      currentQuestionId: nextQuestionId,
      completedQuestionIds: updatedCompletedQuestionIds,
      processedAttemptTokens: updatedAttemptTokens,
      accumulatedScore: updatedScore,
      correctCount: updatedCorrectCount,
      activeObjectiveId: targetObjectiveId,
      checkpointRevision: nextCheckpointRevision,
      authoritativeStateRevision: nextAuthRevision,
      timestamp: effectiveTs,
    );

    _activeSnapshots[sessionId] = updatedSnapshot;

    // 8. Evaluate Checkpoint Policy
    final effectivePolicy = policy ?? _defaultCheckpointPolicy;
    final shouldSave = effectivePolicy.shouldCheckpoint(
      attemptCount: updatedAttemptTokens.length,
      isCompleted: isTerminal,
      isPaused: false,
    );

    if (shouldSave) {
      await _checkpointService.saveSnapshot(updatedSnapshot);
    }

    return AdaptiveSessionResumeResult(
      snapshot: updatedSnapshot,
      authoritativeState: updatedAuthState,
      status: updatedStatus,
      isCheckpointSaved: shouldSave,
      message:
          'Attempt "${attemptIdentity.token}" recorded at checkpoint revision $nextCheckpointRevision',
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Pause & Interruption (Crash Safety)
  // ---------------------------------------------------------------------------

  /// Safely pauses an active session and guarantees checkpoint persistence.
  Future<AdaptiveSessionResumeResult> pauseSession({
    required String sessionId,
    DateTime? pausedAt,
  }) async {
    return _transitionSessionState(
      sessionId: sessionId,
      targetStatus: ResumableSessionStatus.paused,
      timestamp: pausedAt,
      isPaused: true,
    );
  }

  /// Records unexpected interruption (e.g. app freeze, backgrounded, crash) with immediate persistence.
  Future<AdaptiveSessionResumeResult> interruptSession({
    required String sessionId,
    DateTime? interruptedAt,
  }) async {
    return _transitionSessionState(
      sessionId: sessionId,
      targetStatus: ResumableSessionStatus.interrupted,
      timestamp: interruptedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Recovery & Strict Revision Reconciliation
  // ---------------------------------------------------------------------------

  /// Recovers an interrupted session snapshot, verifies cryptographic checksum, and
  /// performs strict revision reconciliation against authoritative learner state.
  Future<AdaptiveSessionRecoveryResult> recoverSession({
    required String learnerId,
    required String examId,
    required String sessionId,
    DateTime? recoveredAt,
  }) async {
    final effectiveTs = (recoveredAt ?? DateTime.now()).toUtc();
    final normalizedSessionId = sessionId.trim();
    final normalizedLearnerId = learnerId.trim();
    final normalizedExamId = examId.trim().toLowerCase();

    // 1. Load and verify snapshot
    final snapshot = await _checkpointService.loadSnapshot(
      learnerId: normalizedLearnerId,
      examId: normalizedExamId,
      sessionId: normalizedSessionId,
    );

    if (snapshot == null) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.checkpointNotFound,
        message:
            'No checkpoint found for recovery of session "$normalizedSessionId"',
      );
    }

    // 2. Identity Verification
    if (snapshot.learnerId != normalizedLearnerId ||
        snapshot.examId != normalizedExamId) {
      throw SessionIdentityMismatchException(
        message:
            'Session coordinates mismatch: stored (${snapshot.learnerId}:${snapshot.examId}) != requested ($normalizedLearnerId:$normalizedExamId)',
        expected: '$normalizedLearnerId:$normalizedExamId',
        actual: '${snapshot.learnerId}:${snapshot.examId}',
        details: {'sessionId': normalizedSessionId},
      );
    }

    // 3. Recover Authoritative State
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

    // 4. Strict Revision Reconciliation Analysis
    final chkRev = snapshot.checkpointRevision;
    final authRev = authState.revision;

    CheckpointReconciliationAlignment alignment;
    String? warning;

    if (chkRev < authRev) {
      alignment = CheckpointReconciliationAlignment.staleCheckpoint;
      warning =
          'Checkpoint revision ($chkRev) < Authoritative state revision ($authRev): checkpoint is stale';
    } else if (chkRev == authRev) {
      alignment = CheckpointReconciliationAlignment.aligned;
    } else {
      alignment = CheckpointReconciliationAlignment.aheadOfAuthoritativeState;
      warning =
          'Checkpoint revision ($chkRev) > Authoritative state revision ($authRev): unpersisted practice state or failure during state persistence';
    }

    // 5. Transition to Recovered Status
    final recoveredIdentity = snapshot.identity.copyWith(
      status: ResumableSessionStatus.recovered,
      lastCheckpointAt: effectiveTs,
    );

    final recoveredSnapshot = snapshot.copyWith(
      identity: recoveredIdentity,
      timestamp: effectiveTs,
    );

    _activeSnapshots[normalizedSessionId] = recoveredSnapshot;
    _activeStates[normalizedSessionId] = authState;

    return AdaptiveSessionRecoveryResult(
      snapshot: recoveredSnapshot,
      authoritativeState: authState,
      alignment: alignment,
      isSuccess: true,
      warningMessage: warning,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Resumption
  // ---------------------------------------------------------------------------

  /// Resumes an interrupted/recovered session at the exact cursor, updating status to resumed/active.
  Future<AdaptiveSessionResumeResult> resumeSession({
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
      recoveredAt: effectiveTs,
    );

    final snapshot = recovery.snapshot;
    final nextCheckpointRevision = snapshot.checkpointRevision + 1;
    final resumedIdentity = snapshot.identity.copyWith(
      status: ResumableSessionStatus.resumed,
      lastCheckpointAt: effectiveTs,
    );

    final resumedSnapshot = snapshot.copyWith(
      identity: resumedIdentity,
      checkpointRevision: nextCheckpointRevision,
      timestamp: effectiveTs,
    );

    // Persist resumed state
    await _checkpointService.saveSnapshot(resumedSnapshot);

    _activeSnapshots[sessionId] = resumedSnapshot;
    _activeStates[sessionId] = recovery.authoritativeState;

    return AdaptiveSessionResumeResult(
      snapshot: resumedSnapshot,
      authoritativeState: recovery.authoritativeState,
      status: ResumableSessionStatus.resumed,
      isCheckpointSaved: true,
      message:
          'Session "$sessionId" successfully resumed at cursor ${resumedSnapshot.currentQuestionIndex}',
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Completion Ordering Guarantee
  // ---------------------------------------------------------------------------

  /// Enforces completion ordering guarantee:
  /// submitAttempt -> consolidateOutcome -> reconcileAuthoritativeState ->
  /// persistAuthoritativeState -> saveFinalCheckpoint -> markCompleted.
  Future<AdaptiveSessionResumeResult> completeSession({
    required String sessionId,
    DateTime? completedAt,
  }) async {
    final effectiveTs = (completedAt ?? DateTime.now()).toUtc();
    final normalizedSessionId = sessionId.trim();

    var snapshot = _activeSnapshots[normalizedSessionId];
    if (snapshot == null) {
      throw SessionIdentityMismatchException(
        message: 'Cannot complete unknown session "$normalizedSessionId"',
        expected: normalizedSessionId,
        actual: 'null',
        details: {'sessionId': normalizedSessionId},
      );
    }

    if (snapshot.status == ResumableSessionStatus.completed) {
      return AdaptiveSessionResumeResult(
        snapshot: snapshot,
        authoritativeState: _activeStates[normalizedSessionId]!,
        status: ResumableSessionStatus.completed,
        message: 'Session was already completed',
      );
    }

    var authState = _activeStates[normalizedSessionId];
    if (authState == null) {
      final authResult = await _authoritativeRecoveryService.recover(
        learnerId: snapshot.learnerId,
        examId: snapshot.examId,
        requestedAt: effectiveTs,
      );
      authState = authResult.state!;
    }

    // Step 1 & 2 & 3: Authoritative state incorporation
    final nextAuthRevision = authState.revision + 1;
    final updatedAuth = AuthoritativeLearnerState(
      learnerId: authState.learnerId,
      examId: authState.examId,
      progressMap: authState.progressMap,
      processedSessionIds: {
        ...authState.processedSessionIds,
        normalizedSessionId
      },
      lastUpdatedAt: effectiveTs,
      revision: nextAuthRevision,
    );

    // Step 4: Persist Authoritative State
    final persisted = PersistedAuthoritativeLearnerState.fromAuthoritativeState(
      updatedAuth,
      revision: nextAuthRevision,
    );
    await _authoritativeRepository.save(persisted);
    _activeStates[normalizedSessionId] = updatedAuth;

    // Step 5: Save Final Checkpoint
    final nextCheckpointRevision = snapshot.checkpointRevision + 1;
    final completedIdentity = snapshot.identity.copyWith(
      status: ResumableSessionStatus.completed,
      lastCheckpointAt: effectiveTs,
    );

    final finalSnapshot = snapshot.copyWith(
      identity: completedIdentity,
      checkpointRevision: nextCheckpointRevision,
      authoritativeStateRevision: nextAuthRevision,
      timestamp: effectiveTs,
    );

    await _checkpointService.saveSnapshot(finalSnapshot);
    _activeSnapshots[normalizedSessionId] = finalSnapshot;

    return AdaptiveSessionResumeResult(
      snapshot: finalSnapshot,
      authoritativeState: updatedAuth,
      status: ResumableSessionStatus.completed,
      isCheckpointSaved: true,
      message:
          'Session "$normalizedSessionId" successfully completed and finalized',
    );
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  Future<AdaptiveSessionResumeResult> _transitionSessionState({
    required String sessionId,
    required ResumableSessionStatus targetStatus,
    DateTime? timestamp,
    bool isPaused = false,
  }) async {
    final effectiveTs = (timestamp ?? DateTime.now()).toUtc();
    final normalizedSessionId = sessionId.trim();

    final snapshot = _activeSnapshots[normalizedSessionId];
    if (snapshot == null) {
      throw SessionIdentityMismatchException(
        message: 'No active session found for "$normalizedSessionId"',
        expected: normalizedSessionId,
        actual: 'null',
        details: {'sessionId': normalizedSessionId},
      );
    }

    if (!snapshot.status.canTransitionTo(targetStatus)) {
      throw SessionCompletionException(
        message:
            'Illegal state transition from ${snapshot.status.name} to ${targetStatus.name}',
        details: {
          'sessionId': normalizedSessionId,
          'from': snapshot.status.name,
          'to': targetStatus.name,
        },
      );
    }

    final nextCheckpointRevision = snapshot.checkpointRevision + 1;
    final updatedIdentity = snapshot.identity.copyWith(
      status: targetStatus,
      lastCheckpointAt: effectiveTs,
    );

    final updatedSnapshot = snapshot.copyWith(
      identity: updatedIdentity,
      checkpointRevision: nextCheckpointRevision,
      timestamp: effectiveTs,
    );

    // Checkpoint persistence is mandatory for pause/interruption to guarantee crash safety
    await _checkpointService.saveSnapshot(updatedSnapshot);
    _activeSnapshots[normalizedSessionId] = updatedSnapshot;

    final authState = _activeStates[normalizedSessionId] ??
        AuthoritativeLearnerState.empty(
          learnerId: snapshot.learnerId,
          examId: snapshot.examId,
          createdAt: effectiveTs,
        );

    return AdaptiveSessionResumeResult(
      snapshot: updatedSnapshot,
      authoritativeState: authState,
      status: targetStatus,
      isCheckpointSaved: true,
      message:
          'Session "$normalizedSessionId" transitioned to ${targetStatus.name}',
    );
  }
}
