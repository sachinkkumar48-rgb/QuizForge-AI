import '../exceptions/quiz_generation_exception.dart';

/// Service validating the structural integrity and domain rules of AI-generated JSON maps.
class QuizJsonValidator {
  const QuizJsonValidator();

  /// Validates a decoded JSON [data] map and returns a list of error descriptions.
  List<String> validateQuizJson(Map<String, dynamic> data) {
    final errors = <String>[];

    final title = data['title'];
    if (title == null || title is! String || title.trim().isEmpty) {
      errors.add(
          'Top-level JSON missing required non-empty string field "title".');
    }

    final questionsRaw = data['questions'];
    if (questionsRaw == null || questionsRaw is! List || questionsRaw.isEmpty) {
      errors.add(
          'Top-level JSON missing required non-empty list field "questions".');
      return errors;
    }

    for (var i = 0; i < questionsRaw.length; i++) {
      final qItem = questionsRaw[i];
      final prefix = 'Question #${i + 1}: ';

      if (qItem is! Map<String, dynamic>) {
        errors.add('${prefix}Item is not a valid JSON object.');
        continue;
      }

      // 1. Question text non-empty
      final qText = qItem['question'];
      if (qText == null || qText is! String || qText.trim().isEmpty) {
        errors.add(
            '${prefix}Missing required non-empty string field "question".');
      }

      // 2. Options list >= 2
      final optionsRaw = qItem['options'];
      if (optionsRaw == null || optionsRaw is! List) {
        errors.add('${prefix}Missing required list field "options".');
        continue;
      }

      if (optionsRaw.length < 2) {
        errors.add(
            '${prefix}Must contain at least 2 options (found ${optionsRaw.length}).');
      }

      // 3. Check option text non-empty and unique
      final seenOptions = <String>{};
      final optionTexts = <String>[];

      for (var j = 0; j < optionsRaw.length; j++) {
        final opt = optionsRaw[j];
        final optText =
            opt is String ? opt : (opt is Map ? opt['text']?.toString() : null);

        if (optText == null || optText.trim().isEmpty) {
          errors.add('${prefix}Option #${j + 1} text cannot be empty.');
        } else {
          final trimmed = optText.trim();
          if (seenOptions.contains(trimmed)) {
            errors.add('${prefix}Duplicate option found: "$trimmed".');
          } else {
            seenOptions.add(trimmed);
          }
          optionTexts.add(trimmed);
        }
      }

      // 4. Correct answer check
      final correctAnswer = qItem['correctAnswer'];
      if (correctAnswer == null) {
        errors.add('${prefix}Missing required field "correctAnswer".');
      } else if (correctAnswer is num) {
        final idx = correctAnswer.toInt();
        if (idx < 0 || idx >= optionsRaw.length) {
          errors.add(
              '${prefix}correctAnswer index ($idx) is out of bounds for options count (${optionsRaw.length}).');
        }
      } else if (correctAnswer is String) {
        final trimmedAns = correctAnswer.trim();
        if (!optionTexts.contains(trimmedAns)) {
          errors.add(
              '${prefix}correctAnswer text "$trimmedAns" does not match any existing option text.');
        }
      } else {
        errors.add(
            '${prefix}correctAnswer must be an integer index or matching option string.');
      }
    }

    return errors;
  }

  /// Validates [data] and throws [JsonValidationException] if errors are found.
  void validateQuizJsonOrThrow(Map<String, dynamic> data) {
    final errors = validateQuizJson(data);
    if (errors.isNotEmpty) {
      throw JsonValidationException(
        'AI JSON schema validation failed with ${errors.length} error(s).',
        validationErrors: errors,
      );
    }
  }
}
