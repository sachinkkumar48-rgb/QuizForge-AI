import 'package:meta/meta.dart';

/// Outcome of safety validation on an AI prompt or completion.
@immutable
class SafetyValidationResult {
  final bool isSafe;
  final String? violationReason;
  final String? flaggedCategory;

  const SafetyValidationResult.valid()
      : isSafe = true,
        violationReason = null,
        flaggedCategory = null;

  const SafetyValidationResult.invalid({
    required this.violationReason,
    required this.flaggedCategory,
  }) : isSafe = false;

  @override
  String toString() => isSafe
      ? 'SafetyValidationResult.valid'
      : 'SafetyValidationResult.invalid($flaggedCategory: $violationReason)';
}

/// Pure Dart safety validator checking inputs/outputs against prompt injection,
/// forbidden content patterns, and system instruction overrides.
class SafetyValidator {
  final List<RegExp> _promptInjectionPatterns = [
    RegExp(r'ignore\s+(all\s+)?previous\s+instructions', caseSensitive: false),
    RegExp(r'disregard\s+system\s+prompt', caseSensitive: false),
    RegExp(r'you\s+are\s+now\s+DAN', caseSensitive: false),
    RegExp(r'bypass\s+safety\s+filter', caseSensitive: false),
  ];

  final List<String> _forbiddenKeywords = [
    '<script>',
    'javascript:',
    'eval(',
  ];

  /// Validates input user prompt for safety violations.
  SafetyValidationResult validatePrompt(String prompt) {
    if (prompt.trim().isEmpty) {
      return const SafetyValidationResult.invalid(
        violationReason: 'Prompt cannot be empty.',
        flaggedCategory: 'empty_input',
      );
    }

    for (final pattern in _promptInjectionPatterns) {
      if (pattern.hasMatch(prompt)) {
        return SafetyValidationResult.invalid(
          violationReason:
              'Potential prompt injection attempt detected matching: "${pattern.pattern}".',
          flaggedCategory: 'prompt_injection',
        );
      }
    }

    for (final keyword in _forbiddenKeywords) {
      if (prompt.toLowerCase().contains(keyword)) {
        return SafetyValidationResult.invalid(
          violationReason: 'Forbidden script keyword detected: "$keyword".',
          flaggedCategory: 'xss_code_injection',
        );
      }
    }

    return const SafetyValidationResult.valid();
  }

  /// Validates generated output text before rendering to user.
  SafetyValidationResult validateOutput(String output) {
    if (output.contains('API_KEY=') || output.contains('AIzaSy')) {
      return const SafetyValidationResult.invalid(
        violationReason: 'Potential secret/credential leakage in AI output.',
        flaggedCategory: 'credential_leakage',
      );
    }
    return const SafetyValidationResult.valid();
  }
}
