/// GARUDA Evidence Engine Package for Project TITAN.
/// Single gateway for all external current affairs, official publications,
/// judgments, and notifications entering Project TITAN.
library;

// Domain Entities & Enums
export 'domain/entities/enums.dart';
export 'domain/entities/evidence_attachment.dart';
export 'domain/entities/evidence_authority.dart';
export 'domain/entities/evidence_metadata.dart';
export 'domain/entities/evidence_object.dart';
export 'domain/entities/evidence_relationship.dart';
export 'domain/entities/evidence_search_query.dart';
export 'domain/entities/evidence_source.dart';
export 'domain/entities/evidence_tag.dart';
export 'domain/entities/knowledge_object_links.dart';

// Domain Repositories & Use Cases
export 'domain/repositories/evidence_repository.dart';
export 'domain/usecases/collect_evidence_usecase.dart';
export 'domain/usecases/link_knowledge_object_usecase.dart';
export 'domain/usecases/search_evidence_usecase.dart';
export 'domain/usecases/store_evidence_usecase.dart';
export 'domain/usecases/validate_evidence_usecase.dart';

// Infrastructure - Collectors
export 'infrastructure/collectors/base_evidence_collector.dart';
export 'infrastructure/collectors/collector_stubs.dart';
export 'infrastructure/collectors/evidence_collector.dart';

// Infrastructure - Validators
export 'infrastructure/validators/authority_validator.dart';
export 'infrastructure/validators/composite_evidence_validator.dart';
export 'infrastructure/validators/date_validator.dart';
export 'infrastructure/validators/duplicate_validator.dart';
export 'infrastructure/validators/evidence_validator.dart';
export 'infrastructure/validators/json_validator.dart';
export 'infrastructure/validators/metadata_validator.dart';
export 'infrastructure/validators/url_validator.dart';
export 'infrastructure/validators/validation_result.dart';

// Infrastructure - Storage
export 'infrastructure/storage/in_memory_evidence_repository.dart';

// Orchestration Layer (TITAN-GCA-002)
export 'orchestration/events/evidence_events.dart';
export 'orchestration/health/source_health.dart';
export 'orchestration/lifecycle/evidence_lifecycle.dart';
export 'orchestration/lineage/evidence_lineage.dart';
export 'orchestration/monitoring/change_detector.dart';
export 'orchestration/queue/editorial_queue.dart';
export 'orchestration/registry/collector_registry.dart';
export 'orchestration/registry/evidence_source_registry.dart';
export 'orchestration/scheduler/schedule_config.dart';
export 'orchestration/versioning/evidence_version.dart';

// Services & Utilities
export 'services/garuda_evidence_service.dart';
export 'utils/date_utils.dart';
export 'utils/hash_utils.dart';
export 'utils/url_utils.dart';
