/// Learning Session Entity (TITAN-KO-019.0 P19).
///
/// Immutable domain model representing an orchestrated practice session.
library;

import 'package:meta/meta.dart';

import 'learning_session_state.dart';
import 'session_configuration.dart';

@immutable
class LearningSession {
  /// Unique learning session identifier.
  final String sessionId;

  /// Target learner identifier.
  final String learnerId;

  /// Session configuration settings.
  final SessionConfiguration configuration;

  /// Deterministically selected and ordered sequence of P15 question IDs.
  final List<String> orderedQuestionIds;

  /// 0-based index of the currently presented question in [orderedQuestionIds].
  final int currentQuestionIndex;

  /// Sequence of submitted attempt IDs produced in this session.
  final List<String> submittedAttemptIds;

  /// Current session lifecycle state.
  final LearningSessionState state;

  /// Timestamp when session was created/started.
  final DateTime startedAt;

  /// Timestamp when session was paused, if applicable.
  final DateTime? pausedAt;

  /// Timestamp when session reached a terminal state (completed/cancelled).
  final DateTime? completedAt;

  /// Optional reference ID to P18 [AssessmentSession].
  final String? assessmentSessionId;

  LearningSession({
    required this.sessionId,
    required this.learnerId,
    required this.configuration,
    required List<String> orderedQuestionIds,
    this.currentQuestionIndex = 0,
    List<String>? submittedAttemptIds,
    this.state = LearningSessionState.created,
    DateTime? startedAt,
    this.pausedAt,
    this.completedAt,
    this.assessmentSessionId,
  })  : orderedQuestionIds = List<String>.unmodifiable(orderedQuestionIds),
        submittedAttemptIds =
            List<String>.unmodifiable(submittedAttemptIds ?? const []),
        startedAt = startedAt ?? DateTime.now().toUtc() {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('SessionId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }
    if (currentQuestionIndex < 0) {
      throw ArgumentError(
          'CurrentQuestionIndex cannot be negative ($currentQuestionIndex)');
    }
  }

  /// Total number of questions scheduled in this session.
  int get totalQuestions => orderedQuestionIds.length;

  /// Total number of attempts submitted so far.
  int get answeredCount => submittedAttemptIds.length;

  /// Whether all scheduled questions have been attempted or session index is at end.
  bool get isFinished =>
      currentQuestionIndex >= totalQuestions || state.isTerminal;

  /// Returns the current question ID presented to the learner, or null if finished.
  String? get currentQuestionId =>
      (currentQuestionIndex >= 0 && currentQuestionIndex < totalQuestions)
          ? orderedQuestionIds[currentQuestionIndex]
          : null;

  /// Returns a copy of this session transitioned to [LearningSessionState.active].
  LearningSession start() {
    if (!state.canTransitionTo(LearningSessionState.active)) {
      throw StateError('Cannot transition session from $state to active');
    }
    return _copyWith(
      state: LearningSessionState.active,
    );
  }

  /// Returns a copy of this session with a recorded attempt ID, advancing the question index.
  LearningSession recordAttempt(String attemptId) {
    if (state != LearningSessionState.active) {
      throw StateError('Cannot record attempt in session with state $state');
    }
    final nextIndex = currentQuestionIndex + 1;
    final isDone = nextIndex >= totalQuestions;
    return _copyWith(
      submittedAttemptIds: [...submittedAttemptIds, attemptId],
      currentQuestionIndex: nextIndex,
      state:
          isDone ? LearningSessionState.completed : LearningSessionState.active,
      completedAt: isDone ? DateTime.now().toUtc() : completedAt,
    );
  }

  /// Returns a copy of this session transitioned to [LearningSessionState.paused].
  LearningSession pause() {
    if (!state.canTransitionTo(LearningSessionState.paused)) {
      throw StateError('Cannot pause session in state $state');
    }
    return _copyWith(
      state: LearningSessionState.paused,
      pausedAt: DateTime.now().toUtc(),
    );
  }

  /// Returns a copy of this session transitioned back to [LearningSessionState.active] from paused.
  LearningSession resume() {
    if (!state.canTransitionTo(LearningSessionState.active)) {
      throw StateError('Cannot resume session in state $state');
    }
    return _copyWith(
      state: LearningSessionState.active,
      pausedAt: null,
    );
  }

  /// Returns a copy of this session completed manually.
  LearningSession complete({DateTime? completionTime}) {
    if (!state.canTransitionTo(LearningSessionState.completed)) {
      throw StateError('Cannot complete session in state $state');
    }
    return _copyWith(
      state: LearningSessionState.completed,
      completedAt: completionTime ?? DateTime.now().toUtc(),
    );
  }

  /// Returns a copy of this session cancelled manually.
  LearningSession cancel() {
    if (!state.canTransitionTo(LearningSessionState.cancelled)) {
      throw StateError('Cannot cancel session in state $state');
    }
    return _copyWith(
      state: LearningSessionState.cancelled,
      completedAt: DateTime.now().toUtc(),
    );
  }

  LearningSession _copyWith({
    int? currentQuestionIndex,
    List<String>? submittedAttemptIds,
    LearningSessionState? state,
    DateTime? pausedAt,
    DateTime? completedAt,
    String? assessmentSessionId,
  }) {
    return LearningSession(
      sessionId: sessionId,
      learnerId: learnerId,
      configuration: configuration,
      orderedQuestionIds: orderedQuestionIds,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      submittedAttemptIds: submittedAttemptIds ?? this.submittedAttemptIds,
      state: state ?? this.state,
      startedAt: startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      completedAt: completedAt ?? this.completedAt,
      assessmentSessionId: assessmentSessionId ?? this.assessmentSessionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'learnerId': learnerId,
        'configuration': configuration.toJson(),
        'orderedQuestionIds': orderedQuestionIds,
        'currentQuestionIndex': currentQuestionIndex,
        'submittedAttemptIds': submittedAttemptIds,
        'state': state.name,
        'startedAt': startedAt.toIso8601String(),
        if (pausedAt != null) 'pausedAt': pausedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (assessmentSessionId != null)
          'assessmentSessionId': assessmentSessionId,
      };

  factory LearningSession.fromJson(Map<String, dynamic> json) =>
      LearningSession(
        sessionId: json['sessionId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        configuration: json['configuration'] != null
            ? SessionConfiguration.fromJson(
                json['configuration'] as Map<String, dynamic>)
            : SessionConfiguration(learnerId: '', objectiveIds: const ['lo_1']),
        orderedQuestionIds:
            (json['orderedQuestionIds'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
        submittedAttemptIds:
            (json['submittedAttemptIds'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        state: LearningSessionState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => LearningSessionState.created,
        ),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String).toUtc()
            : null,
        pausedAt: json['pausedAt'] != null
            ? DateTime.parse(json['pausedAt'] as String).toUtc()
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toUtc()
            : null,
        assessmentSessionId: json['assessmentSessionId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningSession &&
          sessionId == other.sessionId &&
          learnerId == other.learnerId &&
          currentQuestionIndex == other.currentQuestionIndex &&
          state == other.state &&
          _listEquals(orderedQuestionIds, other.orderedQuestionIds) &&
          _listEquals(submittedAttemptIds, other.submittedAttemptIds);

  @override
  int get hashCode => Object.hash(
        sessionId,
        learnerId,
        currentQuestionIndex,
        state,
        Object.hashAll(orderedQuestionIds),
      );

  @override
  String toString() =>
      'LearningSession($sessionId, learner: $learnerId, progress: $currentQuestionIndex/$totalQuestions, state: ${state.name})';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
