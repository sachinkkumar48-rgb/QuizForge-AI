import '../exceptions/quiz_exception.dart';
import '../models/quiz.dart';
import '../models/quiz_question.dart';
import '../validators/quiz_validator.dart';

/// Domain service enforcing pre-flight validation rules on Quiz entities and Question structures.
class QuizValidationService {
  const QuizValidationService();

  /// Validates a [Quiz] entity. Throws [QuizValidationException] if validation fails.
  void validateQuiz(Quiz quiz) {
    final errors = QuizValidator.validateQuiz(quiz);

    if (errors.isNotEmpty) {
      throw QuizValidationException(
        'Quiz validation failed with ${errors.length} error(s).',
        validationErrors: errors,
      );
    }
  }

  /// Validates a single [QuizQuestion] structure and returns a list of error strings.
  List<String> validateQuestion(QuizQuestion question, {int? questionIndex}) {
    return QuizValidator.validateQuestion(question,
        questionIndex: questionIndex);
  }
}
