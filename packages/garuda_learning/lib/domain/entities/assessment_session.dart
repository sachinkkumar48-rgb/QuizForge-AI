/// Assessment Session Entity (TITAN-KO-018.0 P18).
///
/// Represents an optional, lifecycle-managed grouping of question attempts.
library;

import 'package:meta/meta.dart';

@immutable
class AssessmentSession {
  /// Unique session identifier.
  final String sessionId;

  /// Identifier of the learner conducting the session.
  final String learnerId;

  /// Target learning objective IDs included in this session.
  final List<String> objectiveIds;

  /// Target P15 question IDs included in this session.
  final List<String> questionIds;

  /// Timestamp when the session was started.
  final DateTime startedAt;

  /// Timestamp when the session was completed, if finished.
  final DateTime? completedAt;

  /// List of submitted attempt IDs associated with this session.
  final List<String> attemptIds;

  AssessmentSession({
    required this.sessionId,
    required this.learnerId,
    List<String>? objectiveIds,
    List<String>? questionIds,
    DateTime? startedAt,
    this.completedAt,
    List<String>? attemptIds,
  })  : objectiveIds = List<String>.unmodifiable(objectiveIds ?? const []),
        questionIds = List<String>.unmodifiable(questionIds ?? const []),
        startedAt = startedAt ?? DateTime.now().toUtc(),
        attemptIds = List<String>.unmodifiable(attemptIds ?? const []) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('SessionId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }
  }

  /// Whether the session has been formally completed.
  bool get isCompleted => completedAt != null;

  /// Returns a new updated copy of this session with added attempt IDs.
  AssessmentSession addAttempt(String attemptId) {
    if (isCompleted) {
      throw StateError('Cannot add attempt to a completed session');
    }
    return AssessmentSession(
      sessionId: sessionId,
      learnerId: learnerId,
      objectiveIds: objectiveIds,
      questionIds: questionIds,
      startedAt: startedAt,
      completedAt: completedAt,
      attemptIds: [...attemptIds, attemptId],
    );
  }

  /// Returns a new completed session instance.
  AssessmentSession complete({DateTime? completionTime}) {
    if (isCompleted) {
      throw StateError('Session is already completed');
    }
    return AssessmentSession(
      sessionId: sessionId,
      learnerId: learnerId,
      objectiveIds: objectiveIds,
      questionIds: questionIds,
      startedAt: startedAt,
      completedAt: completionTime ?? DateTime.now().toUtc(),
      attemptIds: attemptIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'learnerId': learnerId,
        'objectiveIds': objectiveIds,
        'questionIds': questionIds,
        'startedAt': startedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'attemptIds': attemptIds,
      };

  factory AssessmentSession.fromJson(Map<String, dynamic> json) =>
      AssessmentSession(
        sessionId: json['sessionId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        objectiveIds: (json['objectiveIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        questionIds: (json['questionIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String).toUtc()
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toUtc()
            : null,
        attemptIds: (json['attemptIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentSession &&
          sessionId == other.sessionId &&
          learnerId == other.learnerId &&
          _listEquals(objectiveIds, other.objectiveIds) &&
          _listEquals(questionIds, other.questionIds) &&
          _listEquals(attemptIds, other.attemptIds) &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(sessionId, learnerId, attemptIds.length);

  @override
  String toString() =>
      'AssessmentSession($sessionId, learner: $learnerId, attempts: ${attemptIds.length})';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
