import 'knowledge_capability.dart';

/// Registry maintaining capability maps across registered packages.
class KnowledgeCapabilityRegistry {
  final Map<String, List<KnowledgeCapability>> _packageCapabilities = {};

  void registerCapabilities(String packageName, List<KnowledgeCapability> capabilities) {
    _packageCapabilities[packageName] = List.unmodifiable(capabilities);
  }

  void unregisterCapabilities(String packageName) {
    _packageCapabilities.remove(packageName);
  }

  List<KnowledgeCapability> getCapabilities(String packageName) {
    return _packageCapabilities[packageName] ?? const [];
  }

  List<String> findPackagesByCapability(String capabilityId) {
    final matches = <String>[];
    _packageCapabilities.forEach((pkg, caps) {
      if (caps.any((c) => c.id == capabilityId)) {
        matches.add(pkg);
      }
    });
    return matches;
  }

  Map<String, List<KnowledgeCapability>> get allCapabilities =>
      Map.unmodifiable(_packageCapabilities);
}
