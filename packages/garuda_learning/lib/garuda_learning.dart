/// GARUDA Learning Objectives & Curriculum Framework Package (P17, P18, P19, P20 & P21).
///
/// Deterministic, versioned, evidence-backed curriculum configuration, sequence,
/// learner progress tracking, assessment engine, learning session orchestration,
/// spaced repetition review scheduling, and adaptive learning path recommendation engine.
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

// P19 Domain Entities
export 'domain/entities/learning_session.dart';
export 'domain/entities/learning_session_state.dart';
export 'domain/entities/question_selection_policy.dart';
export 'domain/entities/question_sequencer_policy.dart';
export 'domain/entities/session_configuration.dart';
export 'domain/entities/session_progress_summary.dart';

// P20 Domain Entities
export 'domain/entities/performance_rating.dart';
export 'domain/entities/review_item.dart';
export 'domain/entities/review_result.dart';
export 'domain/entities/review_schedule.dart';

// P21 Domain Entities
export 'domain/entities/learning_recommendation.dart';
export 'domain/entities/recommendation_policy.dart';
export 'domain/entities/recommendation_queue.dart';
export 'domain/entities/recommendation_type.dart';

// P22 Domain Entities
export 'domain/entities/dismissal_reason.dart';
export 'domain/entities/recommendation_effectiveness.dart';
export 'domain/entities/recommendation_evidence_snapshot.dart';
export 'domain/entities/recommendation_instance.dart';
export 'domain/entities/recommendation_interaction.dart';
export 'domain/entities/recommendation_lifecycle_state.dart';
export 'domain/entities/recommendation_outcome.dart';
export 'domain/entities/recommendation_session_link.dart';

// Evaluators
export 'evaluation/answer_evaluator.dart';
export 'evaluation/manual_evaluator.dart';
export 'evaluation/multiple_choice_evaluator.dart';
export 'evaluation/short_answer_evaluator.dart';
export 'evaluation/true_false_evaluator.dart';

// P19 Orchestration Engine
export 'orchestration/learning_session_orchestrator.dart';
export 'orchestration/question_selector.dart';
export 'orchestration/question_sequencer.dart';

// Repositories
export 'repository/attempt_repository.dart';
export 'repository/in_memory_recommendation_lifecycle_repository.dart';
export 'repository/in_memory_recommendation_repository.dart';
export 'repository/learner_repository.dart';
export 'repository/progress_repository.dart';
export 'repository/recommendation_lifecycle_repository.dart';
export 'repository/recommendation_repository.dart';
export 'repository/review_schedule_repository.dart';

// Data Seed
export 'data/curriculum_seed_data.dart';

// Services & Engine
export 'service/adaptive_recommendation_service.dart';
export 'service/assessment_service.dart';
export 'service/curriculum_service.dart';
export 'service/deterministic_sequence_resolver.dart';
export 'service/progress_tracker.dart';
export 'service/recommendation_effectiveness_evaluator.dart';
export 'service/recommendation_engine.dart';
export 'service/recommendation_lifecycle_service.dart';
export 'service/session_manager.dart';
export 'service/spaced_repetition_service.dart';

// Validation
export 'validation/curriculum_validation_result.dart';
export 'validation/curriculum_validator.dart';
