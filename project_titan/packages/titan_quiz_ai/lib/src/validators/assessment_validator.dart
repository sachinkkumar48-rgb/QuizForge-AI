import '../exceptions/quiz_generation_exception.dart';
import '../models/assessment_generation_request.dart';
import '../models/assessment_question_type.dart';
import '../models/generated_question.dart';

/// Validation service enforcing strict structural integrity, domain correctness,
/// and source grounding verification on smart assessment questions.
class AssessmentValidator {
  const AssessmentValidator();

  /// Validates a list of [GeneratedQuestion]s against an [AssessmentGenerationRequest].
  /// Returns a list of validation error descriptions.
  List<String> validateGeneratedQuestions({
    required List<GeneratedQuestion> questions,
    required AssessmentGenerationRequest request,
  }) {
    final errors = <String>[];
    final validChunkIds = request.sources.map((s) => s.chunkId).toSet();

    if (questions.isEmpty) {
      errors.add('No valid questions could be parsed from the AI response.');
      return errors;
    }

    final seenQuestions = <String>{};

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final prefix = 'Question #${i + 1}: ';

      // 1. Question Text validation
      if (q.questionText.trim().isEmpty) {
        errors.add('${prefix}Question text is empty.');
      }

      final normalizedQ = q.questionText.trim().toLowerCase();
      if (seenQuestions.contains(normalizedQ)) {
        errors.add(
            '${prefix}Duplicate question text detected: "${q.questionText}".');
      } else {
        seenQuestions.add(normalizedQ);
      }

      // 2. Options validation
      if (q.options.length < 2) {
        errors.add('${prefix}Question must have at least 2 options.');
      }

      if (q.metadata.questionType == AssessmentQuestionType.trueFalse &&
          q.options.length != 2) {
        errors.add(
            '${prefix}True/False question must have exactly 2 options (found ${q.options.length}).');
      }

      // Check unique options
      final seenOpts = <String>{};
      for (var j = 0; j < q.options.length; j++) {
        final opt = q.options[j].trim().toLowerCase();
        if (opt.isEmpty) {
          errors.add('${prefix}Option #${j + 1} text is empty.');
        } else if (seenOpts.contains(opt)) {
          errors.add('${prefix}Duplicate option found: "${q.options[j]}".');
        } else {
          seenOpts.add(opt);
        }
      }

      // 3. Correct Answers validation
      if (q.correctAnswers.isEmpty) {
        errors.add('${prefix}No valid correct answer indices specified.');
      } else {
        for (final ansIdx in q.correctAnswers) {
          if (ansIdx < 0 || ansIdx >= q.options.length) {
            errors.add(
                '${prefix}Correct answer index ($ansIdx) is out of bounds [0..${q.options.length - 1}].');
          }
        }
      }

      // 4. Explanation requirement
      if (request.blueprint.explanationRequired &&
          (q.explanation == null || q.explanation!.trim().isEmpty)) {
        errors.add(
            '${prefix}Explanation is required by blueprint but was empty or missing.');
      }

      // 5. Source Grounding validation
      if (q.metadata.sourceChunkId.trim().isEmpty) {
        errors.add('${prefix}Missing source chunk attribution.');
      } else if (!validChunkIds.contains(q.metadata.sourceChunkId)) {
        errors.add(
            '${prefix}Source chunk ID "${q.metadata.sourceChunkId}" does not exist in request sources.');
      }
    }

    return errors;
  }

  /// Validates questions and throws [JsonValidationException] if errors are detected.
  void validateQuestionsOrThrow({
    required List<GeneratedQuestion> questions,
    required AssessmentGenerationRequest request,
  }) {
    final errors = validateGeneratedQuestions(
      questions: questions,
      request: request,
    );
    if (errors.isNotEmpty) {
      throw JsonValidationException(
        'Assessment validation failed with ${errors.length} error(s).',
        validationErrors: errors,
      );
    }
  }
}
