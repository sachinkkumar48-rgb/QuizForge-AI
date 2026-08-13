/// Answer Evaluator Interface (TITAN-KO-018.0 P18).
///
/// Abstract contract for deterministic answer evaluators.
library;

import 'package:garuda_case_law/garuda_case_law.dart' show LegalQuestion;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/question_attempt.dart';

abstract interface class AnswerEvaluator {
  /// Evaluates a submitted [QuestionAttempt] against a P15 [LegalQuestion] deterministically.
  AttemptResult evaluate({
    required QuestionAttempt attempt,
    required LegalQuestion question,
  });

  /// The evaluation method supported by this evaluator.
  EvaluationMethod get supportedMethod;
}
