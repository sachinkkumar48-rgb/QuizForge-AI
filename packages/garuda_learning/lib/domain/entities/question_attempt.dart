/// QuestionAttempt Event (TITAN-KO-018.0 P18).
///
/// Immutable event representing a learner's submitted answer to a question.
library;

import 'package:meta/meta.dart';

@immutable
class QuestionAttempt {
  /// Unique identifier for this question attempt.
  final String attemptId;

  /// Identifier of the learner submitting the attempt.
  final String learnerId;

  /// Canonical P15 question ID.
  final String questionId;

  /// Canonical P17 learning objective ID.
  final String objectiveId;

  /// The answer submitted by the learner.
  final String submittedAnswer;

  /// Timestamp when the attempt was submitted.
  final DateTime attemptedAt;

  /// Optional assessment session identifier.
  final String? sessionId;

  QuestionAttempt({
    required this.attemptId,
    required this.learnerId,
    required this.questionId,
    required this.objectiveId,
    required this.submittedAnswer,
    DateTime? attemptedAt,
    this.sessionId,
  }) : attemptedAt = attemptedAt ?? DateTime.now().toUtc() {
    if (attemptId.trim().isEmpty) {
      throw ArgumentError('Attempt ID cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('Learner ID cannot be empty');
    }
    if (questionId.trim().isEmpty) {
      throw ArgumentError('Question ID cannot be empty');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError('Objective ID cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'attemptId': attemptId,
        'learnerId': learnerId,
        'questionId': questionId,
        'objectiveId': objectiveId,
        'submittedAnswer': submittedAnswer,
        'attemptedAt': attemptedAt.toIso8601String(),
        if (sessionId != null) 'sessionId': sessionId,
      };

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) =>
      QuestionAttempt(
        attemptId: json['attemptId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        questionId: json['questionId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String? ?? '',
        submittedAnswer: json['submittedAnswer'] as String? ?? '',
        attemptedAt: json['attemptedAt'] != null
            ? DateTime.parse(json['attemptedAt'] as String).toUtc()
            : null,
        sessionId: json['sessionId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAttempt &&
          attemptId == other.attemptId &&
          learnerId == other.learnerId &&
          questionId == other.questionId &&
          objectiveId == other.objectiveId &&
          submittedAnswer == other.submittedAnswer &&
          sessionId == other.sessionId;

  @override
  int get hashCode =>
      Object.hash(attemptId, learnerId, questionId, objectiveId);

  @override
  String toString() =>
      'QuestionAttempt($attemptId, learner: $learnerId, q: $questionId)';
}
