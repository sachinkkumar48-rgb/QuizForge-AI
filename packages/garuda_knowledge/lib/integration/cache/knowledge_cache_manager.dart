import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../health/knowledge_package_statistics.dart';
import '../registry/knowledge_package_descriptor.dart';

class KnowledgeCacheManager {
  final Map<String, KnowledgePackageDescriptor> _registrationCache = {};
  final Map<String, List<KnowledgeRelationship>> _relationshipCache = {};
  final Map<String, KnowledgeObject> _lookupCache = {};
  final Map<String, KnowledgePackageStatistics> _statisticsCache = {};

  // Registration Cache
  void cacheRegistration(KnowledgePackageDescriptor descriptor) {
    _registrationCache[descriptor.packageName] = descriptor;
  }

  KnowledgePackageDescriptor? getRegistration(String packageName) {
    return _registrationCache[packageName];
  }

  void invalidateRegistration(String packageName) {
    _registrationCache.remove(packageName);
  }

  // Relationship Cache
  void cacheRelationships(String objectId, List<KnowledgeRelationship> rels) {
    _relationshipCache[objectId] = List.unmodifiable(rels);
  }

  List<KnowledgeRelationship>? getRelationships(String objectId) {
    return _relationshipCache[objectId];
  }

  void invalidateRelationships(String objectId) {
    _relationshipCache.remove(objectId);
  }

  // Lookup Cache
  void cacheLookup(KnowledgeObject object) {
    _lookupCache[object.id.value] = object;
  }

  KnowledgeObject? getLookup(String objectId) {
    return _lookupCache[objectId];
  }

  void invalidateLookup(String objectId) {
    _lookupCache.remove(objectId);
  }

  // Statistics Cache
  void cacheStatistics(String packageName, KnowledgePackageStatistics stats) {
    _statisticsCache[packageName] = stats;
  }

  KnowledgePackageStatistics? getStatistics(String packageName) {
    return _statisticsCache[packageName];
  }

  void invalidateStatistics(String packageName) {
    _statisticsCache.remove(packageName);
  }

  // Full Cache Invalidation
  void invalidateAll() {
    _registrationCache.clear();
    _relationshipCache.clear();
    _lookupCache.clear();
    _statisticsCache.clear();
  }
}
