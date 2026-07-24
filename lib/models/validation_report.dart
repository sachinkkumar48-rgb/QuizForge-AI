enum ValidationSeverity { error, warning }

enum ImportMode { strict, safe }

class ValidationIssue {
  final String? questionId;
  final int? index;
  final String field;
  final String message;
  final ValidationSeverity severity;

  ValidationIssue({
    this.questionId,
    this.index,
    required this.field,
    required this.message,
    this.severity = ValidationSeverity.error,
  });

  @override
  String toString() {
    final prefix = severity == ValidationSeverity.error ? 'Error' : 'Warning';
    final target =
        questionId != null ? 'Question $questionId' : 'Item #${index ?? '?'}';
    return '$prefix [$target - $field]: $message';
  }
}

class ValidationReport {
  final int totalQuestions;
  final int validQuestionsCount;
  final int invalidQuestionsCount;
  final List<ValidationIssue> issues;

  ValidationReport({
    required this.totalQuestions,
    required this.validQuestionsCount,
    required this.invalidQuestionsCount,
    required this.issues,
  });

  bool get isValid => invalidQuestionsCount == 0 && errors.isEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  List<ValidationIssue> get errors =>
      issues.where((i) => i.severity == ValidationSeverity.error).toList();

  List<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == ValidationSeverity.warning).toList();

  String generateSummaryText() {
    final buffer = StringBuffer();
    buffer.writeln('Import Summary');
    buffer.writeln('$totalQuestions Questions');
    buffer.writeln('$validQuestionsCount Valid');
    buffer.writeln('$invalidQuestionsCount Invalid');

    if (warnings.isNotEmpty) {
      buffer.writeln('\nWarnings:');
      for (final w in warnings) {
        buffer.writeln(w.toString());
      }
    }

    if (errors.isNotEmpty) {
      buffer.writeln('\nErrors:');
      for (final e in errors) {
        buffer.writeln(e.toString());
      }
    }

    return buffer.toString();
  }
}
