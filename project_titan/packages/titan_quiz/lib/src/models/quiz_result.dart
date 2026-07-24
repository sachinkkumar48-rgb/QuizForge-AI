import 'package:meta/meta.dart';
import 'user_answer.dart';

/// Immutable model representing the evaluation metrics of a quiz attempt.
@immutable
class QuizResult {
  final String quizId;
  final int attempted;
  final int correct;
  final int wrong;
  final int unanswered;
  final double score;
  final double maxScore;
  final double percentage;
  final List<UserAnswer> answers;

  QuizResult({
    required this.quizId,
    required this.attempted,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.score,
    required this.maxScore,
    required this.percentage,
    List<UserAnswer>? answers,
  }) : answers = List<UserAnswer>.unmodifiable(answers ?? const []);

  const QuizResult.constResult({
    required this.quizId,
    required this.attempted,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.answers,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuizResult || runtimeType != other.runtimeType) return false;
    if (quizId != other.quizId ||
        attempted != other.attempted ||
        correct != other.correct ||
        wrong != other.wrong ||
        unanswered != other.unanswered ||
        score != other.score ||
        maxScore != other.maxScore ||
        percentage != other.percentage) {
      return false;
    }
    if (answers.length != other.answers.length) return false;
    for (var i = 0; i < answers.length; i++) {
      if (answers[i] != other.answers[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        quizId,
        attempted,
        correct,
        wrong,
        unanswered,
        score,
        maxScore,
        percentage,
        Object.hashAll(answers),
      );

  @override
  String toString() =>
      'QuizResult(quiz:$quizId, score: $score/$maxScore (${percentage.toStringAsFixed(1)}%), correct: $correct, wrong: $wrong, unans: $unanswered)';
}
