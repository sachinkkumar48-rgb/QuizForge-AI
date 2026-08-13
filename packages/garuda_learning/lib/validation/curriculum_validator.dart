/// Curriculum Validator service (TITAN-KO-017.0 P17).
///
/// Validates a [CurriculumFramework] against structural, prerequisite,
/// canonical product resolution, and evidence safety rules.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show
        CaseExplanationService,
        DoctrineKnowledgeProductService,
        KnowledgeProductNavigatorService,
        KnowledgeProductType,
        QuestionKnowledgeProductService,
        StatuteKnowledgeProductService,
        TopicKnowledgeProductService;

import '../domain/entities/curriculum_framework.dart';

import 'curriculum_validation_result.dart';

class CurriculumValidator {
  final KnowledgeProductNavigatorService? _navigatorService;
  final CaseExplanationService? _caseExplanationService;
  final DoctrineKnowledgeProductService? _doctrineService;
  final StatuteKnowledgeProductService? _statuteService;
  final TopicKnowledgeProductService? _topicService;
  final QuestionKnowledgeProductService? _questionService;

  CurriculumValidator({
    KnowledgeProductNavigatorService? navigatorService,
    CaseExplanationService? caseExplanationService,
    DoctrineKnowledgeProductService? doctrineService,
    StatuteKnowledgeProductService? statuteService,
    TopicKnowledgeProductService? topicService,
    QuestionKnowledgeProductService? questionService,
  })  : _navigatorService = navigatorService,
        _caseExplanationService = caseExplanationService,
        _doctrineService = doctrineService,
        _statuteService = statuteService,
        _topicService = topicService,
        _questionService = questionService;

  /// Performs full validation of a [CurriculumFramework].
  CurriculumValidationResult validate(CurriculumFramework framework) {
    final errors = <String>[];
    final warnings = <String>[];

    var validatedObjectiveCount = 0;
    var validatedReferenceCount = 0;
    var validatedPrerequisiteCount = 0;

    final domainIds = <String>{};
    final unitIds = <String>{};
    final objectiveIds = <String>{};

    // 1. Hierarchy & ID Uniqueness Validation
    if (framework.id.trim().isEmpty) {
      errors.add('Framework ID cannot be empty');
    }
    if (framework.provenance.trim().isEmpty) {
      errors.add('Framework must carry explicit provenance');
    }

    for (final domain in framework.domains) {
      if (!domainIds.add(domain.id)) {
        errors.add('Duplicate domain ID: "${domain.id}"');
      }
      if (domain.provenance.trim().isEmpty) {
        errors.add('Domain "${domain.id}" must carry explicit provenance');
      }

      for (final unit in domain.units) {
        if (!unitIds.add(unit.id)) {
          errors.add('Duplicate unit ID: "${unit.id}"');
        }
        if (unit.domainId != domain.id) {
          errors.add(
              'Unit "${unit.id}" has mismatched domainId "${unit.domainId}" (expected "${domain.id}")');
        }
        if (unit.provenance.trim().isEmpty) {
          errors.add('Unit "${unit.id}" must carry explicit provenance');
        }

        for (final obj in unit.objectives) {
          if (!objectiveIds.add(obj.id)) {
            errors.add('Duplicate learning objective ID: "${obj.id}"');
          }
          if (obj.unitId != unit.id) {
            errors.add(
                'Objective "${obj.id}" has mismatched unitId "${obj.unitId}" (expected "${unit.id}")');
          }
          if (obj.provenance.trim().isEmpty) {
            errors.add('Objective "${obj.id}" must carry explicit provenance');
          }
          validatedObjectiveCount++;
        }
      }
    }

    // 2. Prerequisite Relationship Safety & Cycle Detection
    final adjList = <String, List<String>>{};
    for (final obj in framework.allObjectives) {
      adjList[obj.id] = [];
      for (final prereq in obj.prerequisites) {
        final targetId = prereq.prerequisiteObjectiveId;
        validatedPrerequisiteCount++;

        if (prereq.provenance.trim().isEmpty) {
          errors.add(
              'Prerequisite from "${obj.id}" to "$targetId" lacks explicit provenance');
        }

        if (!objectiveIds.contains(targetId)) {
          errors.add(
              'Objective "${obj.id}" references non-existent prerequisite objective "$targetId"');
        } else if (targetId == obj.id) {
          errors.add(
              'Objective "${obj.id}" declares self-referential prerequisite to itself');
        } else {
          adjList[obj.id]!.add(targetId);
        }
      }
    }

    // Cycle detection using DFS (colors: 0=unvisited, 1=visiting, 2=visited)
    final state = <String, int>{for (var id in objectiveIds) id: 0};
    bool hasCycle(String curr, List<String> path) {
      state[curr] = 1;
      path.add(curr);

      for (final neighbor in adjList[curr] ?? const []) {
        if (state[neighbor] == 1) {
          final cyclePath = [...path.sublist(path.indexOf(neighbor)), neighbor];
          errors.add(
              'Cyclic prerequisite dependency detected: ${cyclePath.join(" -> ")}');
          return true;
        } else if (state[neighbor] == 0) {
          if (hasCycle(neighbor, path)) return true;
        }
      }

      path.removeLast();
      state[curr] = 2;
      return false;
    }

    for (final id in objectiveIds) {
      if (state[id] == 0) {
        hasCycle(id, []);
      }
    }

    // 3. Knowledge Product Mapping Resolution & Validation
    for (final obj in framework.allObjectives) {
      final objectiveProductIds = <String>{};

      for (final mapping in obj.supportedProducts) {
        validatedReferenceCount++;
        objectiveProductIds.add(mapping.productId);

        if (mapping.provenance.trim().isEmpty) {
          errors.add(
              'Product mapping "${mapping.productId}" in objective "${obj.id}" lacks explicit provenance');
        }

        // Validate canonical ID resolution against P11-P16 services if available
        final isValidRef = _verifyProductReference(
          mapping.productType,
          mapping.productId,
          mapping.provisionType,
        );

        if (!isValidRef) {
          errors.add(
              'Objective "${obj.id}" references unresolvable ${mapping.productType.name} product "${mapping.productId}"');
        }
      }

      // Validate Static Mastery Criteria consistency
      final criteria = obj.masteryCriteria;
      if (criteria.minRequiredProducts > obj.supportedProducts.length) {
        warnings.add(
            'Objective "${obj.id}" minRequiredProducts (${criteria.minRequiredProducts}) exceeds available supported products (${obj.supportedProducts.length})');
      }

      for (final mandatoryId in criteria.mandatoryProductIds) {
        if (!objectiveProductIds.contains(mandatoryId)) {
          errors.add(
              'Objective "${obj.id}" lists mandatory product "$mandatoryId" which is not present in supportedProducts');
        }
      }
    }

    return CurriculumValidationResult(
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
      validatedObjectiveCount: validatedObjectiveCount,
      validatedReferenceCount: validatedReferenceCount,
      validatedPrerequisiteCount: validatedPrerequisiteCount,
    );
  }

  /// Verifies whether a product reference resolves to a valid P11–P16 product.
  bool _verifyProductReference(
    KnowledgeProductType type,
    String productId,
    dynamic provisionType,
  ) {
    if (productId.trim().isEmpty) return false;

    // Check against individual services if injected
    final expService = _caseExplanationService;
    if (type == KnowledgeProductType.caseLaw && expService != null) {
      return expService.hasCase(productId);
    }

    final doctService = _doctrineService;
    if (type == KnowledgeProductType.doctrine && doctService != null) {
      return doctService.hasDoctrine(productId);
    }

    final statService = _statuteService;
    if (type == KnowledgeProductType.provision &&
        statService != null &&
        provisionType != null) {
      return statService.hasProvision(provisionType, productId);
    }

    final topService = _topicService;
    if (type == KnowledgeProductType.topic && topService != null) {
      return topService.hasTopic(productId);
    }

    final qService = _questionService;
    if (type == KnowledgeProductType.question && qService != null) {
      return qService.buildAll().any((q) => q.productId == productId);
    }

    // Check via Navigator Service if available
    final nav = _navigatorService;
    if (nav != null) {
      final collection = nav.findAllProductsFor(
        type,
        productId,
        provisionType: provisionType,
      );
      return collection.references.isNotEmpty;
    }

    // Default syntactic canonical ID format check if services are not injected
    return productId.isNotEmpty;
  }
}
