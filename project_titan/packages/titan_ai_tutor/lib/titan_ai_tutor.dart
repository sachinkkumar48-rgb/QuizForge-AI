/// AI Tutor Engine package for Project TITAN.
///
/// Provides adaptive teaching, Socratic questioning, misconception detection,
/// personalized learning pathways, and ecosystem integrations.
library titan_ai_tutor;

export 'src/engine/tutor_engine.dart';
export 'src/integration/tutor_integrator.dart';
export 'src/models/enums.dart';
export 'src/models/tutor_concept.dart';
export 'src/models/tutor_context.dart';
export 'src/models/tutor_difficulty.dart';
export 'src/models/tutor_evaluation.dart';
export 'src/models/tutor_exercise.dart';
export 'src/models/tutor_feedback.dart';
export 'src/models/tutor_goal.dart';
export 'src/models/tutor_hint.dart';
export 'src/models/tutor_lesson.dart';
export 'src/models/tutor_memory.dart';
export 'src/models/tutor_models.dart';
export 'src/models/tutor_progress.dart';
export 'src/models/tutor_question.dart';
export 'src/models/tutor_session.dart';
export 'src/models/tutor_strategy.dart';
export 'src/repository/tutor_repository.dart';
export 'src/repository/tutor_repository_impl.dart';
export 'src/use_cases/continue_tutor_session_use_case.dart';
export 'src/use_cases/detect_misconception_use_case.dart';
export 'src/use_cases/end_tutor_session_use_case.dart';
export 'src/use_cases/evaluate_answer_use_case.dart';
export 'src/use_cases/explain_concept_use_case.dart';
export 'src/use_cases/generate_assignment_use_case.dart';
export 'src/use_cases/generate_practice_use_case.dart';
export 'src/use_cases/recommend_next_lesson_use_case.dart';
export 'src/use_cases/start_tutor_session_use_case.dart';
export 'src/widgets/tutor_chat_view.dart';
export 'src/widgets/tutor_concept_tree.dart';
export 'src/widgets/tutor_evaluation_card.dart';
export 'src/widgets/tutor_exercise_card.dart';
export 'src/widgets/tutor_feedback_card.dart';
export 'src/widgets/tutor_goal_card.dart';
export 'src/widgets/tutor_hint_card.dart';
export 'src/widgets/tutor_lesson_card.dart';
export 'src/widgets/tutor_memory_panel.dart';
export 'src/widgets/tutor_progress_card.dart';
export 'src/widgets/tutor_recommendation_card.dart';
export 'src/widgets/tutor_summary_card.dart';
