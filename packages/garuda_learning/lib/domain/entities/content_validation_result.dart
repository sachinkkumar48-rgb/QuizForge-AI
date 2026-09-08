/// Content Validation Result (TITAN-KO-045.0 P45).
///
/// Structured validation report providing error and warning diagnostics for
/// managed curriculum content prior to publication.
library;

import 'package:meta/meta.dart';

@immutable
class ContentValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ContentValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  const ContentValidationResult.success({this.warnings = const []})
      : isValid = true,
        errors = const [];

  const ContentValidationResult.failure(this.errors,
      {this.warnings = const []})
      : isValid = false;

  String get summary => isValid
      ? 'Content valid and ready for publication.'
      : 'Validation failed with ${errors.length} error(s): ${errors.join("; ")}';

  @override
  String toString() =>
      'ContentValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
}
