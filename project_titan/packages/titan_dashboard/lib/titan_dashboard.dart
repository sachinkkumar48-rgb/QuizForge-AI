/// Analytics & Product Unified Dashboard package for Project TITAN.
library titan_dashboard;

// Engine & Aggregator
export 'src/engine/dashboard_cache.dart';
export 'src/engine/dashboard_engine.dart';
export 'src/engine/metrics_aggregator.dart';

// Orchestrator & State
export 'src/orchestrator/dashboard_orchestrator.dart';
export 'src/orchestrator/unified_dashboard_state.dart';

// Providers
export 'src/providers/dashboard_providers.dart';

// Legacy & Data Models
export 'src/models/dashboard_snapshot.dart';
export 'src/models/goal_progress.dart';
export 'src/models/learning_insights.dart';
export 'src/models/performance_trend.dart';
export 'src/models/study_statistics.dart';

// Repositories & Use Cases
export 'src/repository/dashboard_repository.dart';
export 'src/repository/dashboard_repository_impl.dart';
export 'src/use_cases/generate_insights_use_case.dart';
export 'src/use_cases/get_dashboard_snapshot_use_case.dart';
export 'src/use_cases/refresh_dashboard_use_case.dart';

// Material 3 Dashboard Widgets
export 'src/widgets/achievement_card.dart';
export 'src/widgets/ai_tutor_card.dart';
export 'src/widgets/analytics_card.dart';
export 'src/widgets/assessment_card.dart';
export 'src/widgets/continue_learning_card.dart';
export 'src/widgets/dashboard_error_view.dart';
export 'src/widgets/dashboard_grid.dart';
export 'src/widgets/dashboard_header.dart';
export 'src/widgets/dashboard_home.dart';
export 'src/widgets/dashboard_offline_banner.dart';
export 'src/widgets/dashboard_scroll_view.dart';
export 'src/widgets/dashboard_skeleton.dart';
export 'src/widgets/executive_summary_card.dart';
export 'src/widgets/goal_progress_card.dart';
export 'src/widgets/journey_card.dart';
export 'src/widgets/knowledge_insight_card.dart';
export 'src/widgets/learning_score_gauge.dart';
export 'src/widgets/mentor_insight_card.dart';
export 'src/widgets/performance_trend_chart.dart';
export 'src/widgets/planner_overview_card.dart';
export 'src/widgets/productivity_card.dart';
export 'src/widgets/quick_actions_card.dart';
export 'src/widgets/recommendation_card.dart';
export 'src/widgets/revision_card.dart';
export 'src/widgets/revision_overview_card.dart';
export 'src/widgets/search_insight_card.dart';
export 'src/widgets/today_focus_card.dart';
export 'src/widgets/upcoming_events_card.dart';
export 'src/widgets/welcome_header.dart';
