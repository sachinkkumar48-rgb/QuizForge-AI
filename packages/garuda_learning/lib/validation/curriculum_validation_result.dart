/// Curriculum Validation Result model (TITAN-KO-017.0 P17).
///
/// Diagnostic output from [CurriculumValidator] verifying graph integrity,
/// canonical product resolutions, explicit prerequisites, and evidence bounds.
library;

import 'package:meta/meta.dart';

@immutable
class CurriculumValidationResult {
  /// List of validation error messages.
  final List<String> errors;

  /// List of non-fatal warning messages.
  final List<String> warnings;

  /// Number of verified learning objectives.
  final int validatedObjectiveCount;

  /// Number of verified knowledge product references.
  final int validatedReferenceCount;

  /// Number of verified prerequisite relationships.
  final int validatedPrerequisiteCount;

  const CurriculumValidationResult({
    this.errors = const [],
    this.warnings = const [],
    this.validatedObjectiveCount = 0,
    this.validatedReferenceCount = 0,
    this.validatedPrerequisiteCount = 0,
  });

  /// Whether the curriculum configuration is clean and valid (zero errors).
  bool get isValid => errors.isEmpty;

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'errors': errors,
        'warnings': warnings,
        'validatedObjectiveCount': validatedObjectiveCount,
        'validatedReferenceCount': validatedReferenceCount,
        'validatedPrerequisiteCount': validatedPrerequisiteCount,
      };

  @override
  String toString() => 'CurriculumValidationResult('
      'isValid: $isValid, '
      'errors: ${errors.length}, '
      'warnings: ${warnings.length}, '
      'objectives: $validatedObjectiveCount, '
      'refs: $validatedReferenceCount, '
      'prereqs: $validatedPrerequisiteCount)';
}
