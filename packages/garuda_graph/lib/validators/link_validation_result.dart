library;

import 'package:meta/meta.dart';

/// Single validation error for Knowledge Links.
@immutable
class LinkValidationError {
  final String code;
  final String message;

  const LinkValidationError({required this.code, required this.message});

  Map<String, dynamic> toJson() => {'code': code, 'message': message};

  @override
  String toString() => '[$code] $message';
}

/// Structured validation output for Knowledge Link validation.
@immutable
class LinkValidationResult {
  final bool isValid;
  final List<LinkValidationError> errors;

  const LinkValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  factory LinkValidationResult.success() => const LinkValidationResult(isValid: true);

  factory LinkValidationResult.failure(List<LinkValidationError> errors) =>
      LinkValidationResult(isValid: false, errors: errors);

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'errors': errors.map((e) => e.toJson()).toList(),
      };
}
