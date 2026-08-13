/// Multiple Choice Answer Evaluator (TITAN-KO-018.0 P18).
///
/// Deterministic exact-match evaluator for multiple-choice questions.
library;

import 'package:garuda_case_law/garuda_case_law.dart' show LegalQuestion;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/question_attempt.dart';
import 'answer_evaluator.dart';

class MultipleChoiceEvaluator implements AnswerEvaluator {
  const MultipleChoiceEvaluator();

  @override
  EvaluationMethod get supportedMethod => EvaluationMethod.multipleChoice;

  @override
  AttemptResult evaluate({
    required QuestionAttempt attempt,
    required LegalQuestion question,
  }) {
    final sub = attempt.submittedAnswer.trim();
    final expected = question.answer.answerText.trim();

    // Exact string match (case-insensitive & trimmed)
    final isMatch = sub.isNotEmpty &&
        (sub.toLowerCase() == expected.toLowerCase() ||
            _isOptionMatch(sub, expected));

    return AttemptResult(
      attemptId: attempt.attemptId,
      isCorrect: isMatch,
      score: isMatch ? 1.0 : 0.0,
      feedback: isMatch
          ? 'Correct answer selected.'
          : 'Incorrect. Expected: "$expected"',
      evaluatedAt: DateTime.now().toUtc(),
      evaluationMethod: supportedMethod,
    );
  }

  static bool _isOptionMatch(String sub, String expected) {
    // If option keys like 'A', 'B', 'C', 'D' match leading characters or option label
    if (sub.length == 1 &&
        expected.toUpperCase().startsWith(sub.toUpperCase())) {
      return true;
    }
    return false;
  }
}
