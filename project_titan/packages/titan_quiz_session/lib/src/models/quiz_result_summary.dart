import 'package:meta/meta.dart';

/// Immutable model representing the finalized scoring and attempt metrics for a completed quiz session.
@immutable
class QuizResultSummary {
  final int totalQuestions;
  final int attempted;
  final int correct;
  final int wrong;
  final int unanswered;
  final double score;
  final double maxScore;
  final double percentage;
  final Duration timeTaken;

  const QuizResultSummary({
    required this.totalQuestions,
    required this.attempted,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.timeTaken,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizResultSummary &&
          runtimeType == other.runtimeType &&
          totalQuestions == other.totalQuestions &&
          attempted == other.attempted &&
          correct == other.correct &&
          wrong == other.wrong &&
          unanswered == other.unanswered &&
          score == other.score &&
          maxScore == other.maxScore &&
          percentage == other.percentage &&
          timeTaken == other.timeTaken;

  @override
  int get hashCode => Object.hash(
        totalQuestions,
        attempted,
        correct,
        wrong,
        unanswered,
        score,
        maxScore,
        percentage,
        timeTaken,
      );

  @override
  String toString() =>
      'QuizResultSummary(score: $score/$maxScore ($percentage%), attempted: $attempted/$totalQuestions, time: ${timeTaken.inSeconds}s)';
}
