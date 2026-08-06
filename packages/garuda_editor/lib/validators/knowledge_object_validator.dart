library;

import 'package:meta/meta.dart';
import '../domain/entities/knowledge_object.dart';

@immutable
class KnowledgeObjectValidationError {
  final String field;
  final String message;

  const KnowledgeObjectValidationError({
    required this.field,
    required this.message,
  });

  @override
  String toString() => '[$field] $message';
}

@immutable
class KnowledgeObjectValidationResult {
  final bool isValid;
  final List<KnowledgeObjectValidationError> errors;

  const KnowledgeObjectValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  factory KnowledgeObjectValidationResult.success() =>
      const KnowledgeObjectValidationResult(isValid: true);

  factory KnowledgeObjectValidationResult.failure(
          List<KnowledgeObjectValidationError> errors) =>
      KnowledgeObjectValidationResult(isValid: false, errors: errors);
}

/// Validator for checking completeness and integrity of Knowledge Objects.
class KnowledgeObjectValidator {
  static KnowledgeObjectValidationResult validate(KnowledgeObject object) {
    final errors = <KnowledgeObjectValidationError>[];

    if (object.id.trim().isEmpty) {
      errors.add(const KnowledgeObjectValidationError(
        field: 'id',
        message: 'Knowledge Object ID cannot be empty.',
      ));
    }

    if (object.title.trim().length < 3) {
      errors.add(const KnowledgeObjectValidationError(
        field: 'title',
        message: 'Title must be at least 3 characters long.',
      ));
    }

    if (object.subject.trim().isEmpty) {
      errors.add(const KnowledgeObjectValidationError(
        field: 'subject',
        message: 'Subject classification is required.',
      ));
    }

    if (object.topic.trim().isEmpty) {
      errors.add(const KnowledgeObjectValidationError(
        field: 'topic',
        message: 'Topic classification is required.',
      ));
    }

    if (object.summary.trim().isEmpty) {
      errors.add(const KnowledgeObjectValidationError(
        field: 'summary',
        message: 'Summary executive summary is required.',
      ));
    }

    if (object.content.trim().isEmpty) {
      errors.add(const KnowledgeObjectValidationError(
        field: 'content',
        message: 'Content body cannot be empty.',
      ));
    }

    if (errors.isNotEmpty) {
      return KnowledgeObjectValidationResult.failure(errors);
    }

    return KnowledgeObjectValidationResult.success();
  }
}
