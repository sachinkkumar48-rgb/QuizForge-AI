/// Resumable Learning Session Domain Entity (TITAN-KO-040.0 P40).
///
/// Immutable domain model representing a resumable adaptive learning session,
/// maintaining session coordinates, lifecycle status, completed question lineage,
/// and reference to authoritative learner state without duplicating learner progress maps.
library;

import 'package:meta/meta.dart';

import 'adaptive_practice_session_config.dart';
import 'adaptive_practice_session_spec.dart';
import 'resumable_session_status.dart';
import 'session_checkpoint.dart';
import 'session_recovery_error.dart';

/// Immutable domain entity representing an active, paused, or resumable learning session.
@immutable
class ResumableLearningSession {
  /// Session identifier matching the underlying practice execution.
  final String sessionId;

  /// Target learner identifier.
  final String learnerId;

  /// Examination identifier (lowercase).
  final String examId;

  /// Orchestration mode of this practice session.
  final PracticeSessionMode sessionMode;

  /// Identifier of the currently active learning objective.
  final String currentObjectiveId;

  /// 0-based index of the currently active/presented question.
  final int currentQuestionIndex;

  /// Sequence of completed question IDs processed in this session.
  final List<String> completedQuestionIds;

  /// Current lifecycle execution and recovery status.
  final ResumableSessionStatus status;

  /// Authoritative learner state revision associated with this session (>= 1).
  final int authoritativeStateRevision;

  /// Last persisted checkpoint revision number (>= 1).
  final int lastPersistedRevision;

  /// Timestamp when the session was created.
  final DateTime createdAt;

  /// Timestamp of the last learner or system activity.
  final DateTime lastActivityTimestamp;

  /// Timestamp when the session reached a terminal completion state, if applicable.
  final DateTime? completedAt;

  /// Optional underlying session specification containing ordered questions.
  final AdaptivePracticeSessionSpec? spec;

  /// Contextual recovery metadata and diagnostics.
  final Map<String, dynamic> recoveryMetadata;

  ResumableLearningSession({
    required String sessionId,
    required String learnerId,
    required String examId,
    this.sessionMode = PracticeSessionMode.standard,
    required String currentObjectiveId,
    this.currentQuestionIndex = 0,
    List<String>? completedQuestionIds,
    this.status = ResumableSessionStatus.created,
    this.authoritativeStateRevision = 1,
    this.lastPersistedRevision = 1,
    required DateTime createdAt,
    required DateTime lastActivityTimestamp,
    DateTime? completedAt,
    this.spec,
    Map<String, dynamic>? recoveryMetadata,
  })  : sessionId = sessionId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        currentObjectiveId = currentObjectiveId.trim(),
        completedQuestionIds = List<String>.unmodifiable(
          List<String>.from(completedQuestionIds ?? const <String>[]),
        ),
        createdAt = createdAt.toUtc(),
        lastActivityTimestamp = lastActivityTimestamp.toUtc(),
        completedAt = completedAt?.toUtc(),
        recoveryMetadata =
            Map<String, dynamic>.unmodifiable(recoveryMetadata ?? const {}) {
    if (this.sessionId.isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message: 'sessionId cannot be empty',
      );
    }
    if (this.learnerId.isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.identityMismatch,
        message: 'learnerId cannot be empty',
      );
    }
    if (this.examId.isEmpty) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.identityMismatch,
        message: 'examId cannot be empty',
      );
    }
    if (currentQuestionIndex < 0) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message: 'currentQuestionIndex cannot be negative',
      );
    }
    if (authoritativeStateRevision < 1) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message: 'authoritativeStateRevision must be >= 1',
      );
    }
    if (lastPersistedRevision < 1) {
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message: 'lastPersistedRevision must be >= 1',
      );
    }
  }

  /// Total count of completed questions so far.
  int get completedQuestionCount => completedQuestionIds.length;

  /// Whether the session has completed execution.
  bool get isCompleted => status == ResumableSessionStatus.completed;

  /// Whether the session can be resumed from its current state.
  bool get canResume => status.isRecoverable;

  /// Whether the session is in a terminal state.
  bool get isTerminal => status.isTerminal;

  /// Total questions in the session specification, or 0 if spec is not attached.
  int get totalQuestions => spec?.totalQuestions ?? 0;

  /// Transitions this session to a [target] status enforcing domain transition rules.
  ResumableLearningSession transitionTo(
    ResumableSessionStatus target, {
    DateTime? timestamp,
    Map<String, dynamic>? additionalMetadata,
  }) {
    if (!status.canTransitionTo(target)) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message:
            'Invalid session state transition: cannot transition from "${status.name}" to "${target.name}".',
        details: {
          'currentStatus': status.name,
          'targetStatus': target.name,
          'sessionId': sessionId,
        },
      );
    }

    final effectiveTs = (timestamp ?? DateTime.now()).toUtc();
    final updatedMeta = Map<String, dynamic>.from(recoveryMetadata);
    if (additionalMetadata != null) {
      updatedMeta.addAll(additionalMetadata);
    }

    return copyWith(
      status: target,
      lastActivityTimestamp: effectiveTs,
      completedAt:
          target == ResumableSessionStatus.completed ? effectiveTs : null,
      recoveryMetadata: updatedMeta,
    );
  }

  /// Advances cursor to the next question after answering [completedQuestionId].
  ResumableLearningSession advanceQuestion({
    required String completedQuestionId,
    required String nextObjectiveId,
    DateTime? timestamp,
  }) {
    final effectiveTs = (timestamp ?? DateTime.now()).toUtc();
    final updatedList = List<String>.from(completedQuestionIds)
      ..add(completedQuestionId);

    return copyWith(
      currentQuestionIndex: currentQuestionIndex + 1,
      completedQuestionIds: updatedList,
      currentObjectiveId: nextObjectiveId,
      lastActivityTimestamp: effectiveTs,
    );
  }

  /// Creates a [SessionCheckpoint] representing the current session snapshot.
  SessionCheckpoint createCheckpoint({
    required int nextCheckpointRevision,
    required int nextAuthoritativeRevision,
    DateTime? timestamp,
    bool? isCompleted,
    Map<String, dynamic>? metadata,
  }) {
    if (nextCheckpointRevision <= lastPersistedRevision) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.staleCheckpoint,
        message:
            'nextCheckpointRevision ($nextCheckpointRevision) must be strictly greater than lastPersistedRevision ($lastPersistedRevision)',
        details: {
          'nextCheckpointRevision': nextCheckpointRevision,
          'lastPersistedRevision': lastPersistedRevision,
          'sessionId': sessionId,
        },
      );
    }

    final effectiveTs = (timestamp ?? lastActivityTimestamp).toUtc();
    final mergedMetadata = Map<String, dynamic>.from(recoveryMetadata);
    if (metadata != null) {
      mergedMetadata.addAll(metadata);
    }

    return SessionCheckpoint(
      checkpointRevision: nextCheckpointRevision,
      authoritativeStateRevision: nextAuthoritativeRevision,
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: currentQuestionIndex,
      completedQuestionIds: completedQuestionIds,
      activeObjectiveId: currentObjectiveId,
      timestamp: effectiveTs,
      isCompleted: isCompleted ?? this.isCompleted,
      metadata: mergedMetadata,
    );
  }

  /// Reconstructs a resumed session directly from a persisted [SessionCheckpoint].
  factory ResumableLearningSession.fromCheckpoint({
    required SessionCheckpoint checkpoint,
    AdaptivePracticeSessionSpec? spec,
    DateTime? resumedAt,
  }) {
    final effectiveTs = (resumedAt ?? DateTime.now()).toUtc();
    final resumedStatus = checkpoint.isCompleted
        ? ResumableSessionStatus.completed
        : ResumableSessionStatus.resumed;

    return ResumableLearningSession(
      sessionId: checkpoint.sessionId,
      learnerId: checkpoint.learnerId,
      examId: checkpoint.examId,
      sessionMode: spec?.sessionMode ?? PracticeSessionMode.standard,
      currentObjectiveId: checkpoint.activeObjectiveId,
      currentQuestionIndex: checkpoint.questionIndex,
      completedQuestionIds: checkpoint.completedQuestionIds,
      status: resumedStatus,
      authoritativeStateRevision: checkpoint.authoritativeStateRevision,
      lastPersistedRevision: checkpoint.checkpointRevision,
      createdAt: checkpoint.timestamp,
      lastActivityTimestamp: effectiveTs,
      completedAt: checkpoint.isCompleted ? checkpoint.timestamp : null,
      spec: spec,
      recoveryMetadata: {
        ...checkpoint.metadata,
        'recoveredFromCheckpointRevision': checkpoint.checkpointRevision,
        'resumedAt': effectiveTs.toIso8601String(),
      },
    );
  }

  /// Creates a copy of this session with modified fields.
  ResumableLearningSession copyWith({
    String? currentObjectiveId,
    int? currentQuestionIndex,
    List<String>? completedQuestionIds,
    ResumableSessionStatus? status,
    int? authoritativeStateRevision,
    int? lastPersistedRevision,
    DateTime? lastActivityTimestamp,
    DateTime? completedAt,
    AdaptivePracticeSessionSpec? spec,
    Map<String, dynamic>? recoveryMetadata,
  }) {
    return ResumableLearningSession(
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      sessionMode: sessionMode,
      currentObjectiveId: currentObjectiveId ?? this.currentObjectiveId,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      completedQuestionIds: completedQuestionIds ?? this.completedQuestionIds,
      status: status ?? this.status,
      authoritativeStateRevision:
          authoritativeStateRevision ?? this.authoritativeStateRevision,
      lastPersistedRevision:
          lastPersistedRevision ?? this.lastPersistedRevision,
      createdAt: createdAt,
      lastActivityTimestamp:
          lastActivityTimestamp ?? this.lastActivityTimestamp,
      completedAt: completedAt ?? this.completedAt,
      spec: spec ?? this.spec,
      recoveryMetadata: recoveryMetadata ?? this.recoveryMetadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResumableLearningSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          currentQuestionIndex == other.currentQuestionIndex &&
          status == other.status &&
          authoritativeStateRevision == other.authoritativeStateRevision &&
          lastPersistedRevision == other.lastPersistedRevision;

  @override
  int get hashCode => Object.hash(
        sessionId,
        learnerId,
        examId,
        currentQuestionIndex,
        status,
        authoritativeStateRevision,
        lastPersistedRevision,
      );

  @override
  String toString() =>
      'ResumableLearningSession($sessionId [$learnerId:$examId] status: ${status.name}, cursor: $currentQuestionIndex, authRev: $authoritativeStateRevision, chkRev: $lastPersistedRevision)';
}
