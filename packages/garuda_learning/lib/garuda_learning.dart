/// GARUDA Learning Objectives & Curriculum Framework Package (TITAN-KO-017.0 P17).
///
/// Deterministic, versioned, evidence-backed curriculum configuration and
/// sequence layer organizing P11–P16 Knowledge Products into structured
/// Learning Objectives, Curriculum Domains, Units, and explicit Prerequisite sequences.
library;

// Domain Entities
export 'domain/entities/bloom_taxonomy_level.dart';
export 'domain/entities/curriculum_domain.dart';
export 'domain/entities/curriculum_framework.dart';
export 'domain/entities/curriculum_unit.dart';
export 'domain/entities/curriculum_version.dart';
export 'domain/entities/knowledge_product_mapping.dart';
export 'domain/entities/learning_objective.dart';
export 'domain/entities/prerequisite_relationship.dart';
export 'domain/entities/static_mastery_criteria.dart';

// Data Seed
export 'data/curriculum_seed_data.dart';

// Services & Sequence Engine
export 'service/curriculum_service.dart';
export 'service/deterministic_sequence_resolver.dart';

// Validation
export 'validation/curriculum_validation_result.dart';
export 'validation/curriculum_validator.dart';
