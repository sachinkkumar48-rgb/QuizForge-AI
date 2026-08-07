import 'package:meta/meta.dart';

/// Single validation error detail.
@immutable
class ValidationError {
  final String code;
  final String field;
  final String message;

  const ValidationError({
    required this.code,
    required this.field,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'field': field,
        'message': message,
      };

  factory ValidationError.fromJson(Map<String, dynamic> json) => ValidationError(
        code: json['code'] as String? ?? 'UNKNOWN',
        field: json['field'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  @override
  String toString() => '[$code] $field: $message';
}

/// Single validation warning detail.
@immutable
class ValidationWarning {
  final String code;
  final String field;
  final String message;

  const ValidationWarning({
    required this.code,
    required this.field,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'field': field,
        'message': message,
      };

  factory ValidationWarning.fromJson(Map<String, dynamic> json) => ValidationWarning(
        code: json['code'] as String? ?? 'UNKNOWN',
        field: json['field'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  @override
  String toString() => '[$code] $field: $message';
}

/// Result container for structured evidence object validation.
@immutable
class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidationResult.success({List<ValidationWarning> warnings = const []}) {
    return ValidationResult(
      isValid: true,
      errors: const [],
      warnings: warnings,
    );
  }

  factory ValidationResult.failure({
    required List<ValidationError> errors,
    List<ValidationWarning> warnings = const [],
  }) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'errors': errors.map((e) => e.toJson()).toList(),
        'warnings': warnings.map((w) => w.toJson()).toList(),
      };

  @override
  String toString() =>
      'ValidationResult(isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
}
