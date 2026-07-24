import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../models/user_answer.dart';
import '../utils/quiz_utils.dart';
import 'quiz_scoring_service.dart';

/// Domain service generating detailed statistics and metrics from quiz attempts.
class QuizStatisticsService {
  final QuizScoringService _scoringService;

  const QuizStatisticsService({
    QuizScoringService scoringService = const QuizScoringService(),
  }) : _scoringService = scoringService;

  /// Compiles a complete [QuizResult] summarizing attempt statistics.
  QuizResult generateStatistics({
    required Quiz quiz,
    required List<UserAnswer> answers,
  }) {
    final eval = _scoringService.evaluateAnswers(quiz: quiz, answers: answers);

    final score = eval['score'] as double;
    final maxScore = eval['maxScore'] as double;
    final percentage = QuizUtils.calculatePercentage(score, maxScore);

    return QuizResult(
      quizId: quiz.id,
      attempted: eval['attempted'] as int,
      correct: eval['correct'] as int,
      wrong: eval['wrong'] as int,
      unanswered: eval['unanswered'] as int,
      score: score,
      maxScore: maxScore,
      percentage: percentage,
      answers: answers,
    );
  }
}
