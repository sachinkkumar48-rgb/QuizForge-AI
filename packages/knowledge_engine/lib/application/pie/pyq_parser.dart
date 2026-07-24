import '../pipeline/text_normalizer.dart';
import 'previous_year_question.dart';
import 'pyq_validation_result.dart';

/// Validator, normalizer, and parser component for Previous Year Questions in TITAN PIE.
class PYQParser {
  final TextNormalizer _normalizer;

  /// Constructs a [PYQParser] with optional [TextNormalizer].
  PYQParser({TextNormalizer? normalizer})
      : _normalizer = normalizer ?? TextNormalizer();

  /// Parses raw structured map data into a [PreviousYearQuestion].
  PreviousYearQuestion parse(Map<String, dynamic> rawData) {
    final item = PreviousYearQuestion.fromMap(rawData);
    return normalize(item);
  }

  /// Validates a [PreviousYearQuestion] and returns a [PYQValidationResult].
  PYQValidationResult validate(PreviousYearQuestion question) {
    final errors = <String>[];
    final warnings = <String>[];

    if (question.id.trim().isEmpty) {
      errors.add('PreviousYearQuestion id cannot be empty or whitespace.');
    }

    if (question.question.trim().isEmpty) {
      errors.add('Question text cannot be empty or whitespace.');
    }

    if (question.options.isEmpty) {
      errors.add('Question options list cannot be empty.');
    } else if (question.options.length < 2) {
      warnings.add('Question has fewer than 2 options.');
    }

    if (question.answer.trim().isEmpty) {
      errors.add('Answer key cannot be empty or whitespace.');
    }

    if (question.exam.trim().isEmpty) {
      errors.add('Exam name cannot be empty.');
    }

    if (question.year < 1900 || question.year > DateTime.now().year + 1) {
      warnings.add('Exam year ${question.year} is outside standard range.');
    }

    if (question.explanation.trim().isEmpty) {
      warnings.add('Explanation is blank.');
    }

    if (question.topics.isEmpty) {
      warnings.add('No topics associated with question.');
    }

    return PYQValidationResult(
      success: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      statistics: {
        'questionId': question.id,
        'optionCount': question.options.length,
        'hasExplanation': question.explanation.trim().isNotEmpty,
      },
    );
  }

  /// Normalizes question text, options, explanation, topics, and tags.
  PreviousYearQuestion normalize(PreviousYearQuestion question) {
    final normalizedPrompt = _normalizer.normalize(question.question);
    final normalizedExplanation = _normalizer.normalize(question.explanation);
    final normalizedExam = question.exam.trim();
    final normalizedPaper = question.paper.trim();
    final normalizedSubject = question.subject.trim();
    final normalizedDifficulty = question.difficulty.trim();
    final normalizedAnswer = question.answer.trim();

    final cleanOptions = question.options
        .map((opt) => _normalizer.normalize(opt))
        .where((opt) => opt.isNotEmpty)
        .toList();

    final cleanTopics = question.topics
        .map((topic) => _normalizer.normalize(topic))
        .where((topic) => topic.isNotEmpty)
        .toSet()
        .toList();

    final cleanTags = question.tags
        .map((tag) => _normalizer.normalize(tag))
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    return question.copyWith(
      question: normalizedPrompt,
      explanation: normalizedExplanation,
      options: cleanOptions,
      answer: normalizedAnswer,
      exam: normalizedExam,
      paper: normalizedPaper,
      subject: normalizedSubject,
      topics: cleanTopics,
      difficulty: normalizedDifficulty,
      tags: cleanTags,
    );
  }
}
