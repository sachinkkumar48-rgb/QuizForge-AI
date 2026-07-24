import '../models/quiz_question.dart';

/// Pure utility class for Quiz calculations, formatting, and helper routines.
class QuizUtils {
  const QuizUtils._();

  /// Generates a unique quiz identifier with a prefix and timestamp.
  static String generateQuizId([String prefix = 'quiz']) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp';
  }

  /// Calculates the maximum possible score for a list of [questions].
  static double calculateMaxScore(List<QuizQuestion> questions) {
    return questions.fold(0.0, (sum, q) => sum + q.marks);
  }

  /// Calculates the percentage given [score] and [maxScore].
  static double calculatePercentage(double score, double maxScore) {
    if (maxScore <= 0) return 0.0;
    final pct = (score / maxScore) * 100.0;
    return double.parse(pct.toStringAsFixed(2));
  }

  /// Estimates duration in minutes based on total question count and average time per question.
  static int estimateDurationMinutes(int questionCount,
      {int minutesPerQuestion = 2}) {
    if (questionCount <= 0) return 0;
    return questionCount * minutesPerQuestion;
  }
}
