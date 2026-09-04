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

// Track 1 Question Entities & Providers
export 'domain/entities/question_entity.dart';
export 'adapter/legal_question_adapter.dart';
export 'adapter/pyq_question_adapter.dart';
export 'provider/question_provider.dart';

// P23 Domain Entities
export 'domain/entities/weak_spot_profile.dart';

// P24 Domain Entities
export 'domain/entities/daily_study_agenda.dart';
export 'domain/entities/study_agenda_item.dart';
export 'domain/entities/study_allocation_type.dart';
export 'domain/entities/study_plan.dart';
export 'domain/entities/study_plan_request.dart';
export 'domain/entities/study_time_budget.dart';

// P25 Domain Entities
export 'domain/entities/content_origin.dart';
export 'domain/entities/remedial_binding.dart';
export 'domain/entities/remedial_lesson.dart';
export 'domain/entities/remedial_practice_session_config.dart';
export 'domain/entities/source_reference.dart';

// P26 Domain Entities
export 'domain/entities/diagnostic_assessment_request.dart';
export 'domain/entities/diagnostic_evidence_state.dart';
export 'domain/entities/diagnostic_objective_result.dart';
export 'domain/entities/diagnostic_placement_frontier.dart';
export 'domain/entities/diagnostic_placement_result.dart';
export 'domain/entities/diagnostic_placement_status.dart';
export 'domain/entities/diagnostic_threshold_config.dart';

// Evaluators
export 'evaluation/answer_evaluator.dart';
export 'evaluation/manual_evaluator.dart';
export 'evaluation/multiple_choice_evaluator.dart';
export 'evaluation/short_answer_evaluator.dart';
export 'evaluation/true_false_evaluator.dart';

// P19 Orchestration Engine & Closed-Loop Engine
export 'orchestration/learning_loop_orchestrator.dart';
export 'orchestration/learning_session_orchestrator.dart';
export 'orchestration/question_selector.dart';
export 'orchestration/question_sequencer.dart';

// Repositories
export 'repository/attempt_repository.dart';
export 'repository/diagnostic_placement_repository.dart';
export 'repository/in_memory_diagnostic_placement_repository.dart';
export 'repository/in_memory_recommendation_lifecycle_repository.dart';
export 'repository/in_memory_recommendation_repository.dart';
export 'repository/learner_repository.dart';
export 'repository/progress_repository.dart';
export 'repository/recommendation_lifecycle_repository.dart';
export 'repository/recommendation_repository.dart';
export 'repository/remedial_lesson_repository.dart';
export 'repository/review_schedule_repository.dart';

// Data Seed
export 'data/curriculum_seed_data.dart';

// Services & Engine
export 'service/adaptive_recommendation_service.dart';
export 'service/assessment_service.dart';
export 'service/curriculum_service.dart';
export 'service/deterministic_diagnostic_evaluator.dart';
export 'service/deterministic_remedial_lesson_service.dart';
export 'service/deterministic_sequence_resolver.dart';
export 'service/deterministic_study_planner_service.dart';
export 'service/diagnostic_assessment_service.dart';
export 'service/progress_tracker.dart';
export 'service/recommendation_effectiveness_evaluator.dart';
export 'service/recommendation_engine.dart';
export 'service/recommendation_lifecycle_service.dart';
export 'service/remedial_content_adapter.dart';
export 'service/remedial_lesson_service.dart';
export 'service/session_manager.dart';
export 'service/spaced_repetition_service.dart';
export 'service/study_planner_engine.dart';
export 'service/weak_spot_diagnostic_evaluator.dart';

// Validation
export 'validation/curriculum_validation_result.dart';
export 'validation/curriculum_validator.dart';

// P32 Domain Entities
export 'domain/entities/pyq_learning_priority_config.dart';
export 'domain/entities/pyq_learning_priority_profile.dart';
export 'domain/entities/pyq_learning_priority_signal.dart';

// P32 Service & Adapters
export 'adapter/pyq_diagnostic_adapter.dart';
export 'adapter/pyq_remediation_adapter.dart';
export 'adapter/pyq_study_plan_adapter.dart';
export 'service/pyq_learning_priority_engine.dart';

// P33 Adaptive Question Selection Domain Entities & Service
export 'domain/entities/adaptive_question_candidate.dart';
export 'domain/entities/adaptive_question_selection_config.dart';
export 'domain/entities/adaptive_question_selection_result.dart';
export 'service/adaptive_question_selection_service.dart';

// P34 Adaptive Practice Session Orchestrator Domain Entities & Service
export 'domain/entities/adaptive_practice_session_config.dart';
export 'domain/entities/adaptive_practice_session_spec.dart';
export 'service/adaptive_practice_session_orchestrator.dart';

// P35 Adaptive Practice Execution & Feedback Domain Entities & Service
export 'domain/entities/practice_execution_error.dart';
export 'domain/entities/practice_execution_state.dart';
export 'service/adaptive_practice_execution_engine.dart';

// P36 Practice Outcome Consolidation & Evidence Bridge Domain Entities & Service
export 'domain/entities/practice_consolidation_error.dart';
export 'domain/entities/practice_outcome_evidence.dart';
export 'domain/entities/practice_outcome_consolidation.dart';
export 'service/practice_outcome_consolidator.dart';

// P37 Adaptive Learning Evidence Feedback Loop & Proposal Domain Entities & Service
export 'domain/entities/learning_evidence_signal.dart';
export 'domain/entities/learning_proposal_error.dart';
export 'domain/entities/learning_state_update_proposal.dart';
export 'service/learning_state_update_proposer.dart';

// P38 Adaptive Learning State Reconciliation Engine Domain Entities & Service
export 'domain/entities/authoritative_learner_state.dart';
export 'domain/entities/reconciliation_decision.dart';
export 'domain/entities/reconciliation_error.dart';
export 'domain/entities/reconciled_learning_state_proposal.dart';
export 'service/adaptive_learning_state_reconciler.dart';

// P39 Authoritative Learning-State Application Gateway Domain Entities & Service
export 'domain/entities/authoritative_application_decision.dart';
export 'domain/entities/authoritative_application_error.dart';
export 'domain/entities/authoritative_application_result.dart';
export 'service/authoritative_learning_state_gateway.dart';

// P39 Authoritative State Persistence & Recovery Domain Entities, Repository & Services
export 'domain/entities/authoritative_persistence_error.dart';
export 'domain/entities/authoritative_recovery_result.dart';
export 'domain/entities/persisted_authoritative_learner_state.dart';
export 'repository/authoritative_learning_state_repository.dart';
export 'repository/in_memory_authoritative_learning_state_repository.dart';
export 'service/authoritative_learning_state_recovery_service.dart';
export 'service/authoritative_schema_migrator.dart';
export 'service/authoritative_state_persistence_coordinator.dart';

// P39 Adaptive Learning State Reconciliation & Persistence Pipeline
export 'domain/entities/reconciliation_audit_trail.dart';
export 'domain/entities/reconciliation_pipeline_result.dart';
export 'service/adaptive_learning_state_reconciliation_pipeline.dart';
export 'service/learner_state_persistence_service.dart';

// P40 Recovery-Aware Adaptive Learning Continuation & Session Resumption
export 'domain/entities/resumable_session_status.dart';
export 'domain/entities/session_checkpoint.dart';
export 'domain/entities/resumable_learning_session.dart';
export 'domain/entities/session_recovery_error.dart';
export 'domain/entities/session_recovery_result.dart';
export 'repository/session_checkpoint_repository.dart';
export 'repository/in_memory_session_checkpoint_repository.dart';
export 'service/learning_session_recovery_service.dart';
export 'service/resumable_adaptive_practice_coordinator.dart';

// P41 Adaptive Learning Decision & Continuation Engine
export 'domain/entities/adaptive_decision_policy.dart';
export 'domain/entities/adaptive_learning_decision.dart';
export 'domain/entities/learning_continuation_plan.dart';
export 'service/adaptive_learning_decision_engine.dart';
