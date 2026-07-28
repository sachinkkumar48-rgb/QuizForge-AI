/// Smart Assessment Engine package for Project TITAN.
///
/// Serves as the unified assessment platform for Practice Tests, Topic Tests,
/// Mock Exams, Adaptive Tests (CAT), Previous Year Questions (PYQs), AI-Generated Tests,
/// Daily Quizzes, and Revision Tests.
library titan_smart_assessment;

export 'src/engine/assessment_engine.dart';
export 'src/integration/assessment_integrator.dart';
export 'src/models/adaptive_assessment_state.dart';
export 'src/models/assessment.dart';
export 'src/models/assessment_analysis.dart';
export 'src/models/assessment_attempt.dart';
export 'src/models/assessment_blueprint.dart';
export 'src/models/assessment_feedback.dart';
export 'src/models/assessment_models.dart';
export 'src/models/assessment_objective.dart';
export 'src/models/assessment_recommendation.dart';
export 'src/models/assessment_result.dart';
export 'src/models/assessment_rubric.dart';
export 'src/models/assessment_session.dart';
export 'src/models/difficulty_profile.dart';
export 'src/models/enums.dart';
export 'src/models/question_statistics.dart';
export 'src/models/skill_gap.dart';
export 'src/models/topic_statistics.dart';
export 'src/repository/assessment_repository.dart';
export 'src/repository/assessment_repository_impl.dart';
export 'src/use_cases/analyze_performance_use_case.dart';
export 'src/use_cases/evaluate_assessment_use_case.dart';
export 'src/use_cases/finish_assessment_use_case.dart';
export 'src/use_cases/generate_adaptive_assessment_use_case.dart';
export 'src/use_cases/generate_mock_exam_use_case.dart';
export 'src/use_cases/generate_practice_assessment_use_case.dart';
export 'src/use_cases/recommend_revision_use_case.dart';
export 'src/use_cases/start_assessment_use_case.dart';
export 'src/use_cases/submit_answer_use_case.dart';
export 'src/widgets/adaptive_assessment_card.dart';
export 'src/widgets/assessment_analysis_card.dart';
export 'src/widgets/assessment_card.dart';
export 'src/widgets/assessment_feedback_card.dart';
export 'src/widgets/assessment_history_card.dart';
export 'src/widgets/assessment_progress_card.dart';
export 'src/widgets/assessment_summary_dialog.dart';
export 'src/widgets/difficulty_distribution_chart.dart';
export 'src/widgets/readiness_score_card.dart';
export 'src/widgets/recommendation_panel.dart';
export 'src/widgets/skill_gap_card.dart';
export 'src/widgets/topic_performance_card.dart';
