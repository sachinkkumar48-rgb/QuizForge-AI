library;

import '../domain/entities/knowledge_link.dart';
import '../domain/repositories/knowledge_graph_repository.dart';
import 'link_validation_result.dart';

/// Validation engine checking Knowledge Links for integrity, duplicate links, cycles, and broken references.
class LinkValidatorEngine {
  /// Validate a proposed or existing [KnowledgeLink].
  static Future<LinkValidationResult> validateLink(
    KnowledgeLink link, {
    KnowledgeGraphRepository? repository,
  }) async {
    final errors = <LinkValidationError>[];

    // 1. Broken Link Check (empty source or target)
    if (link.sourceObject.id.trim().isEmpty) {
      errors.add(const LinkValidationError(
        code: 'BROKEN_LINK_SOURCE',
        message: 'Source object ID cannot be empty.',
      ));
    }

    if (link.targetObject.id.trim().isEmpty) {
      errors.add(const LinkValidationError(
        code: 'BROKEN_LINK_TARGET',
        message: 'Target object ID cannot be empty.',
      ));
    }

    // 2. Self-Referential / Circular Link Check (A -> A)
    if (link.sourceObject.id == link.targetObject.id) {
      errors.add(const LinkValidationError(
        code: 'CIRCULAR_LINK_SELF',
        message: 'Self-referential links are invalid (source equals target).',
      ));
    }

    if (repository != null) {
      // 3. Indirect Circular Cycle Check (B -> A when A -> B exists)
      final reverseLinks = await repository.searchLinks(
        sourceId: link.targetObject.id,
        targetId: link.sourceObject.id,
      );

      if (reverseLinks.isNotEmpty) {
        errors.add(LinkValidationError(
          code: 'CIRCULAR_LINK_CYCLE',
          message: 'Direct circular cycle detected between ${link.sourceObject.id} and ${link.targetObject.id}.',
        ));
      }

      // 4. Duplicate Link Check
      final duplicateLinks = await repository.searchLinks(
        sourceId: link.sourceObject.id,
        targetId: link.targetObject.id,
        relationshipType: link.relationshipType,
      );

      if (duplicateLinks.any((l) => l.id != link.id)) {
        errors.add(LinkValidationError(
          code: 'DUPLICATE_LINK',
          message: 'An identical link between ${link.sourceObject.id} and ${link.targetObject.id} already exists.',
        ));
      }
    }

    // 5. Confidence score range
    if (link.confidenceScore < 0.0 || link.confidenceScore > 1.0) {
      errors.add(const LinkValidationError(
        code: 'INVALID_CONFIDENCE_SCORE',
        message: 'Confidence score must be between 0.0 and 1.0.',
      ));
    }

    if (errors.isNotEmpty) {
      return LinkValidationResult.failure(errors);
    }

    return LinkValidationResult.success();
  }
}
