import '../adapters/knowledge_package_adapter.dart';
import '../cache/knowledge_cache_manager.dart';
import '../events/knowledge_event_bus.dart';
import '../events/knowledge_events.dart';
import '../health/knowledge_package_health.dart';
import '../health/knowledge_package_statistics.dart';
import 'knowledge_capability_registry.dart';
import 'knowledge_package_descriptor.dart';

class KnowledgeRegistry {
  final Map<String, KnowledgePackageAdapter> _adapters = {};
  final Map<String, KnowledgePackageDescriptor> _descriptors = {};
  final KnowledgeCapabilityRegistry capabilityRegistry = KnowledgeCapabilityRegistry();
  final KnowledgeCacheManager cacheManager = KnowledgeCacheManager();
  final KnowledgeEventBus eventBus;

  KnowledgeRegistry(this.eventBus);

  Future<void> registerPackage(
    KnowledgePackageAdapter adapter, {
    List<String> dependencies = const [],
  }) async {
    final name = adapter.packageName;
    final meta = await adapter.extractMetadata();

    final descriptor = KnowledgePackageDescriptor(
      packageName: name,
      version: adapter.version,
      dependencies: dependencies,
      capabilities: adapter.capabilities,
      registeredAt: DateTime.now(),
      metadata: meta,
    );

    _adapters[name] = adapter;
    _descriptors[name] = descriptor;
    capabilityRegistry.registerCapabilities(name, adapter.capabilities);
    cacheManager.cacheRegistration(descriptor);

    eventBus.publish(PackageLoadedEvent(
      packageName: name,
      version: adapter.version,
    ));
  }

  Future<void> unregisterPackage(String packageName) async {
    _adapters.remove(packageName);
    _descriptors.remove(packageName);
    capabilityRegistry.unregisterCapabilities(packageName);
    cacheManager.invalidateRegistration(packageName);
  }

  List<KnowledgePackageDescriptor> discoverPackages() {
    return _descriptors.values.toList();
  }

  KnowledgePackageDescriptor? getPackage(String packageName) {
    return _descriptors[packageName];
  }

  KnowledgePackageAdapter? getAdapter(String packageName) {
    return _adapters[packageName];
  }

  Map<String, List<String>> getDependencyGraph() {
    final graph = <String, List<String>>{};
    _descriptors.forEach((name, desc) {
      graph[name] = desc.dependencies;
    });
    return graph;
  }

  Future<KnowledgePackageHealth> getHealth(String packageName) async {
    final adapter = _adapters[packageName];
    if (adapter == null) {
      return KnowledgePackageHealth(
        packageName: packageName,
        version: '0.0.0',
        objectCount: 0,
        relationshipCount: 0,
        evidenceCount: 0,
        coverage: 0.0,
        status: PackageHealthStatus.unhealthy,
        issues: ['Package not registered'],
      );
    }

    final objs = await adapter.extractObjects();
    final rels = await adapter.extractRelationships();
    final evs = await adapter.extractEvidenceReferences();

    final coverage = objs.isNotEmpty ? (evs.length / objs.length) * 100.0 : 100.0;
    return KnowledgePackageHealth(
      packageName: packageName,
      version: adapter.version,
      objectCount: objs.length,
      relationshipCount: rels.length,
      evidenceCount: evs.length,
      coverage: coverage,
      lastSynchronization: DateTime.now(),
      status: PackageHealthStatus.healthy,
    );
  }

  Future<KnowledgePackageStatistics> getStatistics(String packageName) async {
    final adapter = _adapters[packageName];
    final objs = adapter != null ? await adapter.extractObjects() : <dynamic>[];
    final rels = adapter != null ? await adapter.extractRelationships() : <dynamic>[];

    return KnowledgePackageStatistics(
      packageName: packageName,
      totalObjectsRegistered: objs.length,
      totalRelationshipsRegistered: rels.length,
      totalEventsDispatched: 0,
      initializedAt: DateTime.now(),
    );
  }
}
