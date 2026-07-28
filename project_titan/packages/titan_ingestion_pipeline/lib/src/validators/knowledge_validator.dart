import '../models/knowledge_object.dart';

/// Validation result container for Knowledge Object validation.
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  factory ValidationResult.success({List<String> warnings = const []}) {
    return ValidationResult(
      isValid: true,
      errors: const [],
      warnings: warnings,
    );
  }

  factory ValidationResult.failure(List<String> errors,
      {List<String> warnings = const []}) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// Knowledge Validator ensuring high-quality Knowledge Objects.
class KnowledgeValidator {
  /// Validates a [KnowledgeObject] against all structural & completeness rules.
  ValidationResult validate(KnowledgeObject obj,
      {List<KnowledgeObject> existingObjects = const []}) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Empty Lessons Validation
    if (obj.contentBlocks.isEmpty) {
      errors.add('Empty Lesson: KnowledgeObject has zero content blocks.');
    }

    // 2. Duplicate Lessons Validation
    final isDuplicate = existingObjects.any(
      (e) =>
          e.id != obj.id &&
          (e.title.toLowerCase() == obj.title.toLowerCase() &&
              e.source == obj.source),
    );
    if (isDuplicate) {
      errors.add(
          'Duplicate Lesson: Existing KnowledgeObject found with title "${obj.title}" from source "${obj.source}".');
    }

    // 3. Broken Structure Validation
    if (obj.title.trim().isEmpty) {
      errors.add('Broken Structure: KnowledgeObject has an empty title.');
    }

    // 4. Missing Metadata Validation
    if (obj.metadata.title.trim().isEmpty) {
      warnings.add('Missing Metadata: Document metadata title is blank.');
    }
    if (obj.metadata.author == 'Unknown') {
      warnings.add('Missing Metadata: Author is unspecified or Unknown.');
    }

    // 5. Invalid References Validation
    for (final ref in obj.references) {
      if (ref.trim().isEmpty) {
        warnings
            .add('Invalid Reference: Empty or blank reference entry detected.');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}
