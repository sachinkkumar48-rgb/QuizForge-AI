/// Adaptive revision engine, SuperMemo-2 (SM-2) spaced repetition algorithm,
/// and personalized study queue generator for Project TITAN.
library titan_revision;

export 'src/engine/spaced_repetition_engine.dart';
export 'src/models/revision_models.dart';
export 'src/repository/revision_repository.dart';
export 'src/repository/revision_repository_impl.dart';
export 'src/use_cases/generate_revision_queue_use_case.dart';
export 'src/use_cases/process_revision_attempt_use_case.dart';
