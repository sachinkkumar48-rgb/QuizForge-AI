import '../models/quiz.dart';
import '../models/quiz_question.dart';

/// Pure validation logic for Quiz entities and Question structures.
class QuizValidator {
  const QuizValidator._();

  /// Validates a [Quiz] entity and returns a list of error strings.
  static List<String> validateQuiz(Quiz quiz) {
    final errors = <String>[];

    if (quiz.title.trim().isEmpty) {
      errors.add('Quiz title cannot be empty.');
    }

    if (quiz.questions.isEmpty) {
      errors.add('Quiz must contain at least one question.');
    }

    for (var i = 0; i < quiz.questions.length; i++) {
      final questionErrors =
          validateQuestion(quiz.questions[i], questionIndex: i);
      errors.addAll(questionErrors);
    }

    return errors;
  }

  /// Validates a single [QuizQuestion] structure and returns a list of error strings.
  static List<String> validateQuestion(QuizQuestion question,
      {int? questionIndex}) {
    final errors = <String>[];
    final prefix =
        questionIndex != null ? 'Question #${questionIndex + 1}: ' : '';

    if (question.question.trim().isEmpty) {
      errors.add('${prefix}Question text cannot be empty.');
    }

    if (question.options.length < 2) {
      errors.add(
          '${prefix}Question must have at least 2 options (found ${question.options.length}).');
    }

    final correctOptionsCount =
        question.options.where((o) => o.isCorrect).length;
    if (correctOptionsCount != 1) {
      errors.add(
          '${prefix}Question must have exactly one correct option (found $correctOptionsCount).');
    }

    if (question.correctAnswerIndex < 0 ||
        question.correctAnswerIndex >= question.options.length) {
      errors.add(
        '${prefix}Correct answer index (${question.correctAnswerIndex}) is out of bounds for options count (${question.options.length}).',
      );
    } else if (!question.options[question.correctAnswerIndex].isCorrect) {
      errors.add(
        '${prefix}Option at correctAnswerIndex (${question.correctAnswerIndex}) is not marked as isCorrect=true.',
      );
    }

    if (question.marks < 0) {
      errors.add(
          '${prefix}Marks must be non-negative (found ${question.marks}).');
    }

    if (question.negativeMarks < 0) {
      errors.add(
          '${prefix}Negative marks must be non-negative (found ${question.negativeMarks}).');
    }

    return errors;
  }
}
