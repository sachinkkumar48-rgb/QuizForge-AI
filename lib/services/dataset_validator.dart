import '../models/validation_report.dart';

class DatasetValidator {
  static const int minValidYear = 1950;
  static const int maxValidYear = 2035;

  /// Validate a raw questions array payload and return a detailed [ValidationReport].
  static ValidationReport validateQuestions(List rawQuestions) {
    final List<ValidationIssue> issues = [];
    final Set<String> seenIds = {};
    int validCount = 0;
    int invalidCount = 0;

    for (int i = 0; i < rawQuestions.length; i++) {
      final item = rawQuestions[i];
      final List<ValidationIssue> itemIssues = [];

      if (item is! Map<String, dynamic>) {
        issues.add(ValidationIssue(
          index: i,
          field: 'root',
          message: 'Invalid question object format at index $i',
          severity: ValidationSeverity.error,
        ));
        invalidCount++;
        continue;
      }

      final String? id = item['id'] as String?;
      final String? questionText = item['question'] as String?;
      final String? exam = item['exam'] as String?;
      final dynamic yearVal = item['year'];
      final dynamic optionsVal = item['options'];
      final String? correctAnswer = item['correctAnswer'] as String?;
      final String? language = item['language'] as String?;

      // 1. Validate Question ID & Check Duplicates
      if (id == null || id.trim().isEmpty) {
        itemIssues.add(ValidationIssue(
          index: i,
          field: 'id',
          message: 'Required field "id" is missing or empty',
          severity: ValidationSeverity.error,
        ));
      } else {
        final trimmedId = id.trim();
        if (int.tryParse(trimmedId) != null) {
          itemIssues.add(ValidationIssue(
            questionId: trimmedId,
            index: i,
            field: 'id',
            message:
                'Plain numeric ID "$trimmedId" is invalid. Must use structured stable ID (e.g. UPSC_PRE_GS1_2025_Q001)',
            severity: ValidationSeverity.error,
          ));
        } else if (seenIds.contains(trimmedId)) {
          itemIssues.add(ValidationIssue(
            questionId: trimmedId,
            index: i,
            field: 'id',
            message: 'Duplicate question ID "$trimmedId"',
            severity: ValidationSeverity.error,
          ));
        } else {
          seenIds.add(trimmedId);
        }
      }

      // 2. Validate Question Text
      if (questionText == null || questionText.trim().isEmpty) {
        itemIssues.add(ValidationIssue(
          questionId: id,
          index: i,
          field: 'question',
          message: 'Question text is empty',
          severity: ValidationSeverity.error,
        ));
      }

      // 3. Validate Options
      List<String> validOptionsList = [];
      if (optionsVal == null || optionsVal is! List) {
        itemIssues.add(ValidationIssue(
          questionId: id,
          index: i,
          field: 'options',
          message: 'Options list is missing or invalid format',
          severity: ValidationSeverity.error,
        ));
      } else {
        final List rawOptionsList = optionsVal;
        if (rawOptionsList.length < 2) {
          itemIssues.add(ValidationIssue(
            questionId: id,
            index: i,
            field: 'options',
            message: 'Question must have at least 2 options',
            severity: ValidationSeverity.error,
          ));
        }

        for (int optIdx = 0; optIdx < rawOptionsList.length; optIdx++) {
          final opt = rawOptionsList[optIdx];
          if (opt == null || opt.toString().trim().isEmpty) {
            itemIssues.add(ValidationIssue(
              questionId: id,
              index: i,
              field: 'options[$optIdx]',
              message: 'Option #${optIdx + 1} is empty',
              severity: ValidationSeverity.error,
            ));
          } else {
            validOptionsList.add(opt.toString().trim());
          }
        }
      }

      // 4. Validate Correct Answer
      if (correctAnswer == null || correctAnswer.trim().isEmpty) {
        itemIssues.add(ValidationIssue(
          questionId: id,
          index: i,
          field: 'correctAnswer',
          message: 'Correct answer is missing or empty',
          severity: ValidationSeverity.error,
        ));
      } else if (validOptionsList.isNotEmpty) {
        final trimmedAnswer = correctAnswer.trim();
        bool isAnswerFound = false;

        // Check exact option string match
        if (validOptionsList
            .any((opt) => opt.toLowerCase() == trimmedAnswer.toLowerCase())) {
          isAnswerFound = true;
        }

        // Check index letter match ('A', 'B', 'C', 'D')
        if (!isAnswerFound && trimmedAnswer.length == 1) {
          final charCode = trimmedAnswer.toUpperCase().codeUnitAt(0);
          final indexFromChar = charCode - 65; // 'A' -> 0
          if (indexFromChar >= 0 && indexFromChar < validOptionsList.length) {
            isAnswerFound = true;
          }
        }

        // Check 0-based integer index match
        if (!isAnswerFound && int.tryParse(trimmedAnswer) != null) {
          final idx = int.parse(trimmedAnswer);
          if (idx >= 0 && idx < validOptionsList.length) {
            isAnswerFound = true;
          }
        }

        if (!isAnswerFound) {
          itemIssues.add(ValidationIssue(
            questionId: id,
            index: i,
            field: 'correctAnswer',
            message:
                'Correct answer "$trimmedAnswer" does not match any available option',
            severity: ValidationSeverity.error,
          ));
        }
      }

      // 5. Validate Year
      if (yearVal != null) {
        int? yearInt =
            (yearVal is int) ? yearVal : int.tryParse(yearVal.toString());
        if (yearInt == null ||
            yearInt < minValidYear ||
            yearInt > maxValidYear) {
          itemIssues.add(ValidationIssue(
            questionId: id,
            index: i,
            field: 'year',
            message:
                'Invalid year "$yearVal". Must be between $minValidYear and $maxValidYear',
            severity: ValidationSeverity.error,
          ));
        }
      }

      // 6. Validate Exam Type
      if (exam != null && exam.trim().isEmpty) {
        itemIssues.add(ValidationIssue(
          questionId: id,
          index: i,
          field: 'exam',
          message: 'Exam type specified but empty',
          severity: ValidationSeverity.error,
        ));
      }

      // 7. Validate Language
      if (language != null && language.trim().isEmpty) {
        itemIssues.add(ValidationIssue(
          questionId: id,
          index: i,
          field: 'language',
          message: 'Language field specified but empty',
          severity: ValidationSeverity.error,
        ));
      }

      // 8. Validate Explanations (Warning level)
      bool hasExplanation = false;
      if (item.containsKey('explanations') &&
          item['explanations'] is List &&
          (item['explanations'] as List).isNotEmpty) {
        hasExplanation = true;
      } else if (item.containsKey('explanation')) {
        final exp = item['explanation'];
        if (exp is Map &&
            (exp['official']?.toString().trim().isNotEmpty == true ||
                exp['ai']?.toString().trim().isNotEmpty == true)) {
          hasExplanation = true;
        } else if (exp is String && exp.trim().isNotEmpty) {
          hasExplanation = true;
        }
      }

      if (!hasExplanation) {
        itemIssues.add(ValidationIssue(
          questionId: id,
          index: i,
          field: 'explanation',
          message: 'Question ${id ?? "#$i"} missing explanation',
          severity: ValidationSeverity.warning,
        ));
      }

      // Categorize question item
      final hasError =
          itemIssues.any((issue) => issue.severity == ValidationSeverity.error);
      if (hasError) {
        invalidCount++;
      } else {
        validCount++;
      }

      issues.addAll(itemIssues);
    }

    return ValidationReport(
      totalQuestions: rawQuestions.length,
      validQuestionsCount: validCount,
      invalidQuestionsCount: invalidCount,
      issues: issues,
    );
  }
}
