/// Session Progress Summary (TITAN-KO-019.0 P19).
///
/// Read-only summary object aggregating progress metrics for an active or completed session.
library;

import 'package:meta/meta.dart';

import 'learning_session_state.dart';

@immutable
class SessionProgressSummary {
  /// Session identifier.
  final String sessionId;

  /// Learner identifier.
  final String learnerId;

  /// Total number of scheduled questions in session.
  final int totalQuestions;

  /// Number of questions answered so far.
  final int answeredCount;

  /// Number of correctly answered questions.
  final int correctCount;

  /// Calculated score ratio in normalized range [0.0, 1.0].
  final double currentScore;

  /// Current session state.
  final LearningSessionState state;

  /// Whether all questions have been answered or session is finished.
  final bool isCompleted;

  const SessionProgressSummary({
    required this.sessionId,
    required this.learnerId,
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.currentScore,
    required this.state,
    required this.isCompleted,
  })  : assert(sessionId.length > 0, 'SessionId cannot be empty'),
        assert(learnerId.length > 0, 'LearnerId cannot be empty'),
        assert(totalQuestions >= 0, 'TotalQuestions cannot be negative'),
        assert(answeredCount >= 0, 'AnsweredCount cannot be negative'),
        assert(correctCount >= 0 && correctCount <= answeredCount,
            'CorrectCount must be between 0 and answeredCount'),
        assert(currentScore >= 0.0 && currentScore <= 1.0,
            'CurrentScore must be between 0.0 and 1.0');

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'learnerId': learnerId,
        'totalQuestions': totalQuestions,
        'answeredCount': answeredCount,
        'correctCount': correctCount,
        'currentScore': currentScore,
        'state': state.name,
        'isCompleted': isCompleted,
      };

  factory SessionProgressSummary.fromJson(Map<String, dynamic> json) =>
      SessionProgressSummary(
        sessionId: json['sessionId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        answeredCount: json['answeredCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        currentScore: (json['currentScore'] as num?)?.toDouble() ?? 0.0,
        state: LearningSessionState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => LearningSessionState.created,
        ),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionProgressSummary &&
          sessionId == other.sessionId &&
          learnerId == other.learnerId &&
          totalQuestions == other.totalQuestions &&
          answeredCount == other.answeredCount &&
          correctCount == other.correctCount &&
          currentScore == other.currentScore &&
          state == other.state &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(
        sessionId,
        learnerId,
        totalQuestions,
        answeredCount,
        correctCount,
        currentScore,
        state,
        isCompleted,
      );

  @override
  String toString() =>
      'SessionProgressSummary($sessionId, answered: $answeredCount/$totalQuestions, score: ${(currentScore * 100).toStringAsFixed(1)}%, state: ${state.name})';
}
