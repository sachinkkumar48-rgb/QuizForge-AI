/// Canonical Learning Content Framework for Project TITAN.
///
/// Serves as the core domain abstraction for every educational resource type
/// and provides pure Dart activity tracking, offline repository, and M3 widgets.
library titan_learning_content;

export 'src/engine/learning_activity_engine.dart';
export 'src/integration/content_engine_integrator.dart';
export 'src/models/learning_content_models.dart';
export 'src/repository/learning_content_repository.dart';
export 'src/repository/learning_content_repository_impl.dart';
export 'src/use_cases/continue_learning_content_use_case.dart';
export 'src/use_cases/get_chapter_contents_use_case.dart';
export 'src/use_cases/get_learning_content_use_case.dart';
export 'src/use_cases/get_recommended_content_use_case.dart';
export 'src/use_cases/mark_content_completed_use_case.dart';
export 'src/use_cases/update_content_progress_use_case.dart';
export 'src/widgets/content_metadata_card.dart';
export 'src/widgets/content_objectives_card.dart';
export 'src/widgets/content_progress_indicator.dart';
export 'src/widgets/continue_content_card.dart';
export 'src/widgets/learning_activity_timeline.dart';
export 'src/widgets/learning_content_tile.dart';
export 'src/widgets/learning_outcome_card.dart';
export 'src/widgets/prerequisite_card.dart';
