/// Learning Journey Session Domain Aggregate (TITAN-KO-041.0 P41).
///
/// Immutable domain aggregate maintaining coordinates, runtime execution state,
/// durable checkpoint metadata, and reference to authoritative learner state
/// across the complete adaptive learning journey lifecycle.
library;

import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:meta/meta.dart';

import 'adaptive_practice_session_spec.dart';
import 'authoritative_learner_state.dart';
import 'learning_journey_error.dart';
import 'learning_journey_status.dart';
import 'practice_execution_state.dart';
import 'session_checkpoint.dart';

/// Immutable domain aggregate representing an active, paused, or completed learner journey.
@immutable
class LearningJourneySession {
  /// Unique session identifier.
  final String sessionId;

  /// Target learner identifier.
  final String learnerId;

  /// Examination code (lowercase).
  final String examId;

  /// Current discrete lifecycle execution status.
  final LearningJourneyStatus status;

  /// Underlying adaptive practice session specification containing ordered questions.
  final AdaptivePracticeSessionSpec spec;

  /// Transient runtime practice execution state.
  final PracticeExecutionState executionState;

  /// Current authoritative learner state.
  final AuthoritativeLearnerState authoritativeState;

  /// Most recently persisted session checkpoint.
  final SessionCheckpoint checkpoint;

  /// 0-based cursor for the currently presented or next unattempted question.
  final int currentQuestionIndex;

  /// Immutable list of completed question IDs.
  final List<String> completedQuestionIds;

  /// Timestamp when the journey was initialized.
  final DateTime createdAt;

  /// Timestamp of the most recent learner interaction or state transition.
  final DateTime lastActivityAt;

  /// Timestamp of session finalization, if completed.
  final DateTime? completedAt;

  /// Contextual diagnostic and audit metadata.
  final Map<String, dynamic> metadata;

  LearningJourneySession({
    required String sessionId,
    required String learnerId,
    required String examId,
    this.status = LearningJourneyStatus.created,
    required this.spec,
    required this.executionState,
    required this.authoritativeState,
    required this.checkpoint,
    this.currentQuestionIndex = 0,
    List<String>? completedQuestionIds,
    required DateTime createdAt,
    required DateTime lastActivityAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  })  : sessionId = sessionId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        completedQuestionIds =
            List<String>.unmodifiable(completedQuestionIds ?? const <String>[]),
        createdAt = createdAt.toUtc(),
        lastActivityAt = lastActivityAt.toUtc(),
        completedAt = completedAt?.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (this.sessionId.isEmpty) {
      throw const LearningJourneyException(
        code: LearningJourneyErrorCode.missingSession,
        message: 'sessionId cannot be empty',
      );
    }
    if (this.learnerId.isEmpty) {
      throw const LearningJourneyException(
        code: LearningJourneyErrorCode.tenantMismatch,
        message: 'learnerId cannot be empty',
      );
    }
    if (this.examId.isEmpty) {
      throw const LearningJourneyException(
        code: LearningJourneyErrorCode.tenantMismatch,
        message: 'examId cannot be empty',
      );
    }
    if (currentQuestionIndex < 0) {
      throw const LearningJourneyException(
        code: LearningJourneyErrorCode.invalidTransition,
        message: 'currentQuestionIndex cannot be negative',
      );
    }
  }

  /// Currently presented question based on [currentQuestionIndex], or null if out of bounds.
  NormalizedQuestion? get currentQuestion {
    if (currentQuestionIndex >= 0 &&
        currentQuestionIndex < spec.orderedQuestions.length) {
      return spec.orderedQuestions[currentQuestionIndex];
    }
    return null;
  }

  /// Total questions planned in this session.
  int get totalQuestions => spec.orderedQuestions.length;

  /// Number of questions successfully answered and consolidated.
  int get answeredCount => completedQuestionIds.length;

  /// Fractional progress completed [0.0, 1.0].
  double get progressPercentage => totalQuestions == 0
      ? 1.0
      : (answeredCount / totalQuestions).clamp(0.0, 1.0);

  /// Whether all questions in this session have been answered.
  bool get isCompleted =>
      status == LearningJourneyStatus.completed ||
      (totalQuestions > 0 && answeredCount >= totalQuestions);

  /// Whether the session is currently interrupted.
  bool get isInterrupted => status == LearningJourneyStatus.interrupted;

  /// Active learning objective ID currently targeted.
  String get activeObjectiveId => checkpoint.activeObjectiveId;

  /// Current checkpoint revision number.
  int get checkpointRevision => checkpoint.checkpointRevision;

  /// Authoritative learner state revision number.
  int get authoritativeStateRevision => authoritativeState.revision;

  /// Transitions the session to a new lifecycle [newStatus], validating legality.
  LearningJourneySession transitionTo(
    LearningJourneyStatus newStatus, {
    required DateTime timestamp,
  }) {
    if (!status.canTransitionTo(newStatus)) {
      throw LearningJourneyException(
        code: LearningJourneyErrorCode.invalidTransition,
        message:
            'Illegal lifecycle transition from "${status.name}" to "${newStatus.name}" in session "$sessionId".',
      );
    }

    return copyWith(
      status: newStatus,
      lastActivityAt: timestamp,
      completedAt: newStatus == LearningJourneyStatus.completed
          ? (completedAt ?? timestamp)
          : completedAt,
    );
  }

  /// Creates a copy of this session with specified fields updated.
  LearningJourneySession copyWith({
    LearningJourneyStatus? status,
    AdaptivePracticeSessionSpec? spec,
    PracticeExecutionState? executionState,
    AuthoritativeLearnerState? authoritativeState,
    SessionCheckpoint? checkpoint,
    int? currentQuestionIndex,
    List<String>? completedQuestionIds,
    DateTime? lastActivityAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LearningJourneySession(
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      status: status ?? this.status,
      spec: spec ?? this.spec,
      executionState: executionState ?? this.executionState,
      authoritativeState: authoritativeState ?? this.authoritativeState,
      checkpoint: checkpoint ?? this.checkpoint,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      completedQuestionIds: completedQuestionIds ?? this.completedQuestionIds,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'learnerId': learnerId,
        'examId': examId,
        'status': status.name,
        'currentQuestionIndex': currentQuestionIndex,
        'completedQuestionIds': completedQuestionIds,
        'checkpointRevision': checkpoint.checkpointRevision,
        'authoritativeStateRevision': authoritativeState.revision,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'lastActivityAt': lastActivityAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}
