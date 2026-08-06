import '../concepts/concept_model.dart';
import '../concepts/concept_relationship_model.dart';
import '../mappings/question_concept_mapping_model.dart';

enum ConceptValidationErrorCode {
  duplicateConcept,
  duplicateMapping,
  invalidConfidence,
  brokenKnowledgeLink,
  circularRelationship,
}

class ConceptValidationError {
  final ConceptValidationErrorCode code;
  final String message;
  final String targetId;

  const ConceptValidationError({
    required this.code,
    required this.message,
    required this.targetId,
  });

  @override
  String toString() => '[$code] Target $targetId: $message';
}

class ConceptValidationService {
  /// Validates concept details and checks against existing concepts for duplicates & link integrity.
  static List<ConceptValidationError> validateConcept(
    Concept concept, {
    List<Concept> existingConcepts = const [],
  }) {
    final errors = <ConceptValidationError>[];

    // 1. Check for Duplicate Concepts
    final normName = concept.name.trim().toLowerCase();
    for (final existing in existingConcepts) {
      if (existing.id != concept.id &&
          existing.subject.toLowerCase() == concept.subject.toLowerCase()) {
        if (existing.name.trim().toLowerCase() == normName) {
          errors.add(ConceptValidationError(
            code: ConceptValidationErrorCode.duplicateConcept,
            message: 'Duplicate concept name "${concept.name}" in subject ${concept.subject}',
            targetId: concept.id,
          ));
        }
      }
    }

    // 2. Check for Broken Knowledge Links
    for (final kId in concept.knowledgeObjectIds) {
      if (kId.trim().isEmpty || kId.contains(' ')) {
        errors.add(ConceptValidationError(
          code: ConceptValidationErrorCode.brokenKnowledgeLink,
          message: 'Malformed or broken Knowledge Object link: "$kId"',
          targetId: concept.id,
        ));
      }
    }

    return errors;
  }

  /// Validates question-concept mapping score bounds and auto-rejection rule.
  static List<ConceptValidationError> validateMapping(
    QuestionConceptMapping mapping, {
    List<QuestionConceptMapping> existingMappings = const [],
  }) {
    final errors = <ConceptValidationError>[];

    // 1. Invalid Confidence Bounds
    if (mapping.confidenceScore < 0.0 || mapping.confidenceScore > 1.0) {
      errors.add(ConceptValidationError(
        code: ConceptValidationErrorCode.invalidConfidence,
        message: 'Confidence score ${mapping.confidenceScore} is out of bounds [0.0, 1.0]',
        targetId: '${mapping.questionId}_${mapping.conceptId}',
      ));
    }

    // 2. Auto-rejection warning / rule for score < 0.50
    if (mapping.confidenceScore < 0.50 && mapping.reviewStatus == ReviewStatus.approved) {
      errors.add(ConceptValidationError(
        code: ConceptValidationErrorCode.invalidConfidence,
        message: 'Cannot approve mapping with confidence score below 0.50 (${mapping.confidenceScore})',
        targetId: '${mapping.questionId}_${mapping.conceptId}',
      ));
    }

    // 3. Duplicate Mapping Check
    for (final existing in existingMappings) {
      if (existing.questionId == mapping.questionId &&
          existing.conceptId == mapping.conceptId &&
          existing != mapping) {
        errors.add(ConceptValidationError(
          code: ConceptValidationErrorCode.duplicateMapping,
          message: 'Duplicate mapping between question ${mapping.questionId} and concept ${mapping.conceptId}',
          targetId: '${mapping.questionId}_${mapping.conceptId}',
        ));
      }
    }

    return errors;
  }

  /// Detects circular relationships in concept relationship graph using Depth-First Search.
  static List<ConceptValidationError> detectCircularRelationships(
    List<ConceptRelationship> relationships,
  ) {
    final errors = <ConceptValidationError>[];
    final adjList = <String, List<String>>{};

    for (final rel in relationships) {
      adjList.putIfAbsent(rel.sourceConceptId, () => []).add(rel.targetConceptId);
    }

    final visited = <String>{};
    final recStack = <String>{};

    bool isCyclic(String node, List<String> path) {
      visited.add(node);
      recStack.add(node);
      path.add(node);

      final neighbors = adjList[node] ?? [];
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          if (isCyclic(neighbor, path)) return true;
        } else if (recStack.contains(neighbor)) {
          path.add(neighbor);
          return true;
        }
      }

      recStack.remove(node);
      path.removeLast();
      return false;
    }

    for (final node in adjList.keys) {
      if (!visited.contains(node)) {
        final path = <String>[];
        if (isCyclic(node, path)) {
          errors.add(ConceptValidationError(
            code: ConceptValidationErrorCode.circularRelationship,
            message: 'Circular relationship detected: ${path.join(" -> ")}',
            targetId: node,
          ));
        }
      }
    }

    return errors;
  }
}
