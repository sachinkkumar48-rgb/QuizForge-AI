/// GARUDA Learning Objectives & Curriculum Framework Package (TITAN-KO-017.0 P17 & TITAN-KO-018.0 P18).
///
/// Deterministic, versioned, evidence-backed curriculum configuration, sequence,
/// learner progress tracking, and assessment engine organizing P11–P16 Knowledge
/// Products into structured Learning Objectives, explicit Prerequisite sequences,
/// deterministic answer evaluation, and objective achievement tracking.
library;

// P17 Domain Entities
export 'domain/entities/bloom_taxonomy_level.dart';
export 'domain/entities/curriculum_domain.dart';
export 'domain/entities/curriculum_framework.dart';
export 'domain/entities/curriculum_unit.dart';
export 'domain/entities/curriculum_version.dart';
export 'domain/entities/knowledge_product_mapping.dart';
export 'domain/entities/learning_objective.dart';
export 'domain/entities/prerequisite_relationship.dart';
export 'domain/entities/static_mastery_criteria.dart';

// P18 Domain Entities
export 'domain/entities/assessment_session.dart';
export 'domain/entities/assessment_threshold_config.dart';
export 'domain/entities/attempt_result.dart';
export 'domain/entities/evaluation_method.dart';
export 'domain/entities/learner.dart';
export 'domain/entities/learner_objective_status.dart';
export 'domain/entities/learner_progress.dart';
export 'domain/entities/question_attempt.dart';

// Evaluators
export 'evaluation/answer_evaluator.dart';
export 'evaluation/manual_evaluator.dart';
export 'evaluation/multiple_choice_evaluator.dart';
export 'evaluation/short_answer_evaluator.dart';
export 'evaluation/true_false_evaluator.dart';

// Repositories
export 'repository/attempt_repository.dart';
export 'repository/learner_repository.dart';
export 'repository/progress_repository.dart';

// Data Seed
export 'data/curriculum_seed_data.dart';

// Services & Engine
export 'service/assessment_service.dart';
export 'service/curriculum_service.dart';
export 'service/deterministic_sequence_resolver.dart';
export 'service/progress_tracker.dart';
export 'service/session_manager.dart';

// Validation
export 'validation/curriculum_validation_result.dart';
export 'validation/curriculum_validator.dart';
