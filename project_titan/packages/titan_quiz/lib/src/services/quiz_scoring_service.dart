import '../models/quiz.dart';
import '../models/user_answer.dart';
import '../utils/quiz_utils.dart';

/// Domain service evaluating user responses and calculating net scores.
class QuizScoringService {
  const QuizScoringService();

  /// Evaluates user [answers] for a [quiz] and returns raw score components.
  Map<String, dynamic> evaluateAnswers({
    required Quiz quiz,
    required List<UserAnswer> answers,
  }) {
    var correctCount = 0;
    var wrongCount = 0;
    var unansweredCount = 0;
    var totalScore = 0.0;
    final maxPossibleScore = QuizUtils.calculateMaxScore(quiz.questions);

    final answerMap = {for (final a in answers) a.questionId: a};

    for (final question in quiz.questions) {
      final userAnswer = answerMap[question.id];

      if (userAnswer == null || !userAnswer.isAnswered) {
        unansweredCount++;
      } else if (userAnswer.selectedOptionIndex ==
          question.correctAnswerIndex) {
        correctCount++;
        totalScore += question.marks;
      } else {
        wrongCount++;
        totalScore -= question.negativeMarks;
      }
    }

    return {
      'attempted': correctCount + wrongCount,
      'correct': correctCount,
      'wrong': wrongCount,
      'unanswered': unansweredCount,
      'score': totalScore,
      'maxScore': maxPossibleScore,
    };
  }
}
