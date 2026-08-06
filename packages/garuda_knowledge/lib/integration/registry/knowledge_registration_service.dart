import '../adapters/knowledge_package_adapter.dart';
import '../sync/knowledge_synchronization_service.dart';
import 'knowledge_registry.dart';

class KnowledgeRegistrationService {
  final KnowledgeRegistry _registry;
  final KnowledgeSynchronizationService _syncService;

  KnowledgeRegistrationService(this._registry, this._syncService);

  Future<void> registerAndSync(
    KnowledgePackageAdapter adapter, {
    List<String> dependencies = const [],
  }) async {
    await _registry.registerPackage(adapter, dependencies: dependencies);
    await _syncService.synchronizeAdapter(adapter);
  }

  Future<void> unregister(String packageName) async {
    await _registry.unregisterPackage(packageName);
  }
}
