/// Short Answer Keyword Evaluator (TITAN-KO-018.0 P18).
///
/// Deterministic keyword / pattern evaluator for short text answers.
/// Strictly non-AI, non-LLM, rule-based matching.
library;

import 'package:garuda_case_law/garuda_case_law.dart' show LegalQuestion;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/question_attempt.dart';
import 'answer_evaluator.dart';

class ShortAnswerEvaluator implements AnswerEvaluator {
  /// Custom required keywords to check if provided by caller; otherwise derived from question principles/answer.
  final List<String>? requiredKeywords;

  const ShortAnswerEvaluator({this.requiredKeywords});

  @override
  EvaluationMethod get supportedMethod => EvaluationMethod.shortAnswerKeyword;

  @override
  AttemptResult evaluate({
    required QuestionAttempt attempt,
    required LegalQuestion question,
  }) {
    final sub = attempt.submittedAnswer.trim().toLowerCase();
    if (sub.isEmpty) {
      return AttemptResult(
        attemptId: attempt.attemptId,
        isCorrect: false,
        score: 0.0,
        feedback: 'No answer submitted.',
        evaluatedAt: DateTime.now().toUtc(),
        evaluationMethod: supportedMethod,
      );
    }

    // Canonical answer precedence: a submission matching the recorded
    // answer text is deterministically correct, independent of keyword
    // ratio (principle-derived keywords must not dilute an exact answer).
    final exp = question.answer.answerText.trim().toLowerCase();
    if (sub == exp || sub.contains(exp) || exp.contains(sub)) {
      return AttemptResult(
        attemptId: attempt.attemptId,
        isCorrect: true,
        score: 1.0,
        feedback: 'Exact answer match.',
        evaluatedAt: DateTime.now().toUtc(),
        evaluationMethod: supportedMethod,
      );
    }

    final keywords = requiredKeywords ?? _extractKeywords(question);
    if (keywords.isEmpty) {
      return AttemptResult(
        attemptId: attempt.attemptId,
        isCorrect: false,
        score: 0.0,
        feedback: 'Answer does not match.',
        evaluatedAt: DateTime.now().toUtc(),
        evaluationMethod: supportedMethod,
      );
    }

    var matchedCount = 0;
    for (final kw in keywords) {
      if (sub.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }

    final ratio = (matchedCount / keywords.length).clamp(0.0, 1.0);
    final isCorrect = ratio >= 0.75;

    return AttemptResult(
      attemptId: attempt.attemptId,
      isCorrect: isCorrect,
      score: ratio,
      feedback:
          'Keyword match ratio: ${(ratio * 100).toStringAsFixed(0)}% ($matchedCount/${keywords.length} keywords matched)',
      evaluatedAt: DateTime.now().toUtc(),
      evaluationMethod: supportedMethod,
    );
  }

  static List<String> _extractKeywords(LegalQuestion question) {
    final kwSet = <String>{};
    for (final p in question.answer.principles) {
      for (final word in p.split(RegExp(r'\W+'))) {
        if (word.length > 3) kwSet.add(word.toLowerCase());
      }
    }
    for (final word in question.answer.answerText.split(RegExp(r'\W+'))) {
      if (word.length > 4) kwSet.add(word.toLowerCase());
    }
    return kwSet.toList()..sort();
  }
}
