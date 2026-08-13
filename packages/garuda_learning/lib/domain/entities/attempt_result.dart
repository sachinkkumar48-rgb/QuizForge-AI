/// AttemptResult Entity (TITAN-KO-018.0 P18).
///
/// Immutable evaluation result for a single [QuestionAttempt].
library;

import 'package:meta/meta.dart';

import 'evaluation_method.dart';

@immutable
class AttemptResult {
  /// Reference ID of the evaluated [QuestionAttempt]. Never empty.
  final String attemptId;

  /// Whether the submitted answer was evaluated as correct.
  final bool isCorrect;

  /// Score in the normalized range [0.0, 1.0].
  final double score;

  /// Optional feedback or rationale for the score.
  final String? feedback;

  /// Timestamp when the evaluation was produced.
  final DateTime evaluatedAt;

  /// The deterministic method used to evaluate the attempt.
  final EvaluationMethod evaluationMethod;

  AttemptResult({
    required this.attemptId,
    required this.isCorrect,
    required this.score,
    this.feedback,
    DateTime? evaluatedAt,
    required this.evaluationMethod,
  }) : evaluatedAt = evaluatedAt ?? DateTime.now().toUtc() {
    if (attemptId.trim().isEmpty) {
      throw ArgumentError('AttemptId cannot be empty for an AttemptResult');
    }
    if (score < 0.0 || score > 1.0) {
      throw ArgumentError('Score must be between 0.0 and 1.0 (got $score)');
    }
  }

  Map<String, dynamic> toJson() => {
        'attemptId': attemptId,
        'isCorrect': isCorrect,
        'score': score,
        if (feedback != null) 'feedback': feedback,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'evaluationMethod': evaluationMethod.name,
      };

  factory AttemptResult.fromJson(Map<String, dynamic> json) => AttemptResult(
        attemptId: json['attemptId'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        feedback: json['feedback'] as String?,
        evaluatedAt: json['evaluatedAt'] != null
            ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
            : null,
        evaluationMethod: EvaluationMethod.values.firstWhere(
          (e) => e.name == json['evaluationMethod'],
          orElse: () => EvaluationMethod.multipleChoice,
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttemptResult &&
          attemptId == other.attemptId &&
          isCorrect == other.isCorrect &&
          score == other.score &&
          feedback == other.feedback &&
          evaluationMethod == other.evaluationMethod;

  @override
  int get hashCode =>
      Object.hash(attemptId, isCorrect, score, evaluationMethod);

  @override
  String toString() =>
      'AttemptResult($attemptId, correct: $isCorrect, score: $score)';
}
