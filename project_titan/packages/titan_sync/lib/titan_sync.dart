/// Provider-agnostic offline-first cloud synchronization engine for Project TITAN.
library titan_sync;

export 'src/cloud/cloud_provider.dart';
export 'src/conflict/conflict_resolver.dart';
export 'src/engine/background_sync_service.dart';
export 'src/engine/sync_manager.dart';
export 'src/models/sync_batch.dart';
export 'src/models/sync_conflict.dart';
export 'src/models/sync_entity_type.dart';
export 'src/models/sync_item.dart';
export 'src/models/sync_result.dart';
export 'src/repository/sync_repository.dart';
export 'src/repository/sync_repository_impl.dart';
export 'src/use_cases/queue_sync_use_case.dart';
export 'src/use_cases/resolve_conflict_use_case.dart';
export 'src/use_cases/retry_failed_sync_use_case.dart';
export 'src/use_cases/sync_now_use_case.dart';
export 'src/widgets/conflict_resolution_dialog.dart';
export 'src/widgets/last_sync_tile.dart';
export 'src/widgets/pending_sync_badge.dart';
export 'src/widgets/sync_progress_indicator.dart';
export 'src/widgets/sync_status_card.dart';
