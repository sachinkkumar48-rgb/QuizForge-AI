/// Integration layer barrel file for GARUDA Knowledge Engine.
library;

// Adapters
export 'adapters/case_law_package_adapter.dart';
export 'adapters/constitution_package_adapter.dart';
export 'adapters/doctrine_package_adapter.dart';
export 'adapters/evidence_package_adapter.dart';
export 'adapters/graph_package_adapter.dart';
export 'adapters/knowledge_package_adapter.dart';
export 'adapters/pyq_package_adapter.dart';

// Cache
export 'cache/knowledge_cache_manager.dart';

// Events
export 'events/knowledge_event_bus.dart';
export 'events/knowledge_events.dart';

// Health & Statistics
export 'health/knowledge_package_health.dart';
export 'health/knowledge_package_statistics.dart';

// Loader
export 'loader/knowledge_package_loader.dart';

// Registry & Capabilities
export 'registry/knowledge_capability.dart';
export 'registry/knowledge_capability_registry.dart';
export 'registry/knowledge_package_descriptor.dart';
export 'registry/knowledge_registration_service.dart';
export 'registry/knowledge_registry.dart';

// Synchronization
export 'sync/knowledge_synchronization_service.dart';
