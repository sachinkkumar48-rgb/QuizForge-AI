/// Manual Answer Evaluator (TITAN-KO-018.0 P18).
///
/// Evaluator for essay / case analysis questions requiring manual review.
/// Explicitly non-automated; does NOT fabricate score or AI evaluation.
library;

import 'package:garuda_case_law/garuda_case_law.dart' show LegalQuestion;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/question_attempt.dart';
import 'answer_evaluator.dart';

class ManualEvaluator implements AnswerEvaluator {
  const ManualEvaluator();

  @override
  EvaluationMethod get supportedMethod => EvaluationMethod.manual;

  @override
  AttemptResult evaluate({
    required QuestionAttempt attempt,
    required LegalQuestion question,
  }) {
    return AttemptResult(
      attemptId: attempt.attemptId,
      isCorrect: false,
      score: 0.0,
      feedback:
          'Manual evaluation required for essay / case analysis question. Automated AI evaluation is disabled.',
      evaluatedAt: DateTime.now().toUtc(),
      evaluationMethod: supportedMethod,
    );
  }
}
