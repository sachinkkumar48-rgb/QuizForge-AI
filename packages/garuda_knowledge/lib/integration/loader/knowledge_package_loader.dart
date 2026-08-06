import '../adapters/knowledge_package_adapter.dart';
import '../events/knowledge_event_bus.dart';
import '../events/knowledge_events.dart';
import '../registry/knowledge_registration_service.dart';

class KnowledgePackageLoader {
  final KnowledgeRegistrationService _registrationService;
  final KnowledgeEventBus _eventBus;

  KnowledgePackageLoader(this._registrationService, this._eventBus);

  Future<void> loadPackage(
    KnowledgePackageAdapter adapter, {
    List<String> dependencies = const [],
  }) async {
    await _registrationService.registerAndSync(adapter, dependencies: dependencies);
    _eventBus.publish(PackageLoadedEvent(
      packageName: adapter.packageName,
      version: adapter.version,
    ));
  }

  Future<void> reloadPackage(KnowledgePackageAdapter adapter) async {
    await _registrationService.unregister(adapter.packageName);
    await _registrationService.registerAndSync(adapter);
    _eventBus.publish(PackageReloadedEvent(packageName: adapter.packageName));
  }
}
