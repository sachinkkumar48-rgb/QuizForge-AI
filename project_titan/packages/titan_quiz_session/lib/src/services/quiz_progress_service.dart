import 'package:titan_quiz/titan_quiz.dart';
import '../models/quiz_session.dart';

/// Service tracking progress, completion status, and question attempt metrics.
class QuizProgressService {
  const QuizProgressService();

  /// Calculates the completion progress ratio (between 0.0 and 1.0).
  double calculateProgressRatio(QuizSession session, Quiz quiz) {
    if (quiz.questions.isEmpty) return 0.0;
    final answered = getAnsweredCount(session);
    return (answered / quiz.questions.length).clamp(0.0, 1.0);
  }

  /// Calculates completion progress percentage (0.0 to 100.0).
  double calculateProgressPercentage(QuizSession session, Quiz quiz) {
    return calculateProgressRatio(session, quiz) * 100.0;
  }

  /// Returns the total number of questions answered in the session.
  int getAnsweredCount(QuizSession session) {
    return session.answers.where((a) => a.isAnswered).length;
  }

  /// Returns the number of remaining (unanswered) questions for the session.
  int getRemainingCount(QuizSession session, Quiz quiz) {
    final total = quiz.questions.length;
    final answered = getAnsweredCount(session);
    final remaining = total - answered;
    return remaining < 0 ? 0 : remaining;
  }

  /// Returns true if all questions in the quiz have been answered.
  bool isCompleted(QuizSession session, Quiz quiz) {
    if (quiz.questions.isEmpty) return false;
    return getAnsweredCount(session) >= quiz.questions.length;
  }
}
