enum ValidationSeverity { info, warning, error }

class ValidationIssue {
  final String code;
  final String message;
  final String? objectId;
  final ValidationSeverity severity;

  const ValidationIssue({
    required this.code,
    required this.message,
    this.objectId,
    this.severity = ValidationSeverity.error,
  });

  @override
  String toString() => '[$severity] $code: $message (${objectId ?? 'global'})';
}

class ValidationResult {
  final List<ValidationIssue> issues;

  const ValidationResult({this.issues = const []});

  bool get isValid => issues.every((i) => i.severity != ValidationSeverity.error);

  List<ValidationIssue> get errors =>
      issues.where((i) => i.severity == ValidationSeverity.error).toList();

  List<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == ValidationSeverity.warning).toList();
}
