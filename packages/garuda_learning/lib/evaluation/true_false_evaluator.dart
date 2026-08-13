/// True/False Answer Evaluator (TITAN-KO-018.0 P18).
///
/// Deterministic normalized boolean match evaluator for True/False questions.
library;

import 'package:garuda_case_law/garuda_case_law.dart' show LegalQuestion;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/question_attempt.dart';
import 'answer_evaluator.dart';

class TrueFalseEvaluator implements AnswerEvaluator {
  const TrueFalseEvaluator();

  @override
  EvaluationMethod get supportedMethod => EvaluationMethod.trueFalse;

  @override
  AttemptResult evaluate({
    required QuestionAttempt attempt,
    required LegalQuestion question,
  }) {
    final subBool = _parseBool(attempt.submittedAnswer);
    final expBool = _parseBool(question.answer.answerText);

    bool isMatch = false;
    if (subBool != null && expBool != null) {
      isMatch = (subBool == expBool);
    } else {
      // Fallback exact normalized text match
      final subNorm = attempt.submittedAnswer.trim().toLowerCase();
      final expNorm = question.answer.answerText.trim().toLowerCase();
      isMatch = subNorm.isNotEmpty && subNorm == expNorm;
    }

    return AttemptResult(
      attemptId: attempt.attemptId,
      isCorrect: isMatch,
      score: isMatch ? 1.0 : 0.0,
      feedback: isMatch
          ? 'Correct True/False evaluation.'
          : 'Incorrect True/False response.',
      evaluatedAt: DateTime.now().toUtc(),
      evaluationMethod: supportedMethod,
    );
  }

  static bool? _parseBool(String text) {
    final norm = text.trim().toLowerCase();
    if (norm == 'true' || norm == 't' || norm == 'yes' || norm == '1') {
      return true;
    }
    if (norm == 'false' || norm == 'f' || norm == 'no' || norm == '0') {
      return false;
    }
    return null;
  }
}
