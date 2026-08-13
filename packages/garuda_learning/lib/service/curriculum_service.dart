/// Curriculum Service (TITAN-KO-017.0 P17).
///
/// Central application service providing access to curriculum configuration,
/// objective lookup, explicit prerequisite resolution, deterministic learning
/// sequences, and P11–P16 Knowledge Product integration.
library;

import 'package:garuda_case_law/garuda_case_law.dart'
    show KnowledgeProductNavigatorService, KnowledgeProductReference;

import '../domain/entities/curriculum_domain.dart';
import '../domain/entities/curriculum_framework.dart';
import '../domain/entities/curriculum_unit.dart';
import '../domain/entities/learning_objective.dart';
import '../validation/curriculum_validation_result.dart';
import '../validation/curriculum_validator.dart';

import 'deterministic_sequence_resolver.dart';

class CurriculumService {
  final CurriculumFramework _framework;
  final CurriculumValidator _validator;
  final DeterministicSequenceResolver _sequenceResolver;
  final KnowledgeProductNavigatorService? _navigatorService;

  CurriculumService({
    required CurriculumFramework framework,
    CurriculumValidator? validator,
    DeterministicSequenceResolver? sequenceResolver,
    KnowledgeProductNavigatorService? navigatorService,
  })  : _framework = framework,
        _validator = validator ??
            CurriculumValidator(navigatorService: navigatorService),
        _sequenceResolver = sequenceResolver ?? DeterministicSequenceResolver(),
        _navigatorService = navigatorService;

  /// Returns the current curriculum framework.
  CurriculumFramework get framework => _framework;

  /// Returns framework version descriptor.
  String get versionString => _framework.version.version;

  /// Validates the current framework configuration.
  CurriculumValidationResult validateFramework() {
    return _validator.validate(_framework);
  }

  /// Retrieves a learning objective by canonical ID, or null if not found.
  LearningObjective? getObjectiveById(String objectiveId) {
    return _framework.objectiveMap[objectiveId];
  }

  /// Retrieves a curriculum unit by ID, or null if not found.
  CurriculumUnit? getUnitById(String unitId) {
    return _framework.unitMap[unitId];
  }

  /// Retrieves a curriculum domain by ID, or null if not found.
  CurriculumDomain? getDomainById(String domainId) {
    return _framework.domainMap[domainId];
  }

  /// Resolves all transitive explicit prerequisites for a given objective ID,
  /// returned in deterministic prerequisite topological order.
  List<LearningObjective> getPrerequisiteClosure(String objectiveId) {
    final rootObj = getObjectiveById(objectiveId);
    if (rootObj == null) return const [];

    final visitedIds = <String>{};
    final collected = <LearningObjective>[];

    void collect(LearningObjective current) {
      for (final prereq in current.prerequisites) {
        final pid = prereq.prerequisiteObjectiveId;
        if (visitedIds.add(pid)) {
          final target = getObjectiveById(pid);
          if (target != null) {
            collect(target);
            collected.add(target);
          }
        }
      }
    }

    collect(rootObj);
    return _sequenceResolver.resolveSequence(collected);
  }

  /// Computes a deterministic learning sequence for an entire domain, unit,
  /// or the full framework.
  List<LearningObjective> getDeterministicSequence({
    String? domainId,
    String? unitId,
  }) {
    List<LearningObjective> objectives;

    if (unitId != null) {
      final unit = getUnitById(unitId);
      objectives = unit?.objectives ?? const [];
    } else if (domainId != null) {
      final domain = getDomainById(domainId);
      objectives =
          domain?.allUnits.expand((u) => u.objectives).toList() ?? const [];
    } else {
      objectives = _framework.allObjectives;
    }

    return _sequenceResolver.resolveSequence(objectives);
  }

  /// Resolves mapped supporting P11–P16 products for an objective into P16
  /// [KnowledgeProductReference]s if [KnowledgeProductNavigatorService] is attached.
  List<KnowledgeProductReference> getResolvedProductReferences(
    String objectiveId,
  ) {
    final obj = getObjectiveById(objectiveId);
    final nav = _navigatorService;
    if (obj == null || nav == null) return const [];

    final refs = <KnowledgeProductReference>[];
    for (final mapping in obj.supportedProducts) {
      final collection = nav.findAllProductsFor(
        mapping.productType,
        mapping.productId,
        provisionType: mapping.provisionType,
      );
      if (collection.references.isNotEmpty) {
        final primary = collection.references.firstWhere(
          (r) => r.isPrimary,
          orElse: () => collection.references.first,
        );
        refs.add(primary);
      }
    }
    return refs;
  }
}

extension _CurriculumDomainExtension on CurriculumDomain {
  List<CurriculumUnit> get allUnits => units;
}
