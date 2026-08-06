import '../../repositories/knowledge_repository.dart';
import '../adapters/knowledge_package_adapter.dart';
import '../events/knowledge_event_bus.dart';
import '../events/knowledge_events.dart';

class SyncResult {
  final String packageName;
  final int objectsAdded;
  final int objectsUpdated;
  final int relationshipsAdded;
  final List<String> conflicts;

  const SyncResult({
    required this.packageName,
    required this.objectsAdded,
    required this.objectsUpdated,
    required this.relationshipsAdded,
    this.conflicts = const [],
  });
}

class KnowledgeSynchronizationService {
  final KnowledgeRepository _repository;
  final KnowledgeEventBus _eventBus;

  KnowledgeSynchronizationService(this._repository, this._eventBus);

  Future<SyncResult> synchronizeAdapter(KnowledgePackageAdapter adapter) async {
    final extractedObjects = await adapter.extractObjects();
    final extractedRels = await adapter.extractRelationships();

    int addedObj = 0;
    int updatedObj = 0;
    int addedRel = 0;
    final conflicts = <String>[];

    for (final obj in extractedObjects) {
      final existing = await _repository.findById(obj.id);
      if (existing == null) {
        await _repository.create(obj);
        addedObj++;
        _eventBus.publish(ObjectRegisteredEvent(
          objectId: obj.id.value,
          objectType: obj.type.name,
          packageName: adapter.packageName,
        ));
      } else {
        if (obj.currentVersion.versionNumber > existing.currentVersion.versionNumber) {
          await _repository.update(obj);
          updatedObj++;
          _eventBus.publish(ObjectUpdatedEvent(
            objectId: obj.id.value,
            newVersion: obj.currentVersion.versionNumber,
          ));
        } else if (obj.currentVersion.versionNumber < existing.currentVersion.versionNumber) {
          conflicts.add('Conflict on ${obj.id.value}: Extracted version (${obj.currentVersion.versionNumber}) is older than repository version (${existing.currentVersion.versionNumber})');
        }
      }
    }

    for (final rel in extractedRels) {
      final existingRelated = await _repository.findRelated(rel.sourceId);
      if (!existingRelated.any((r) => r.id == rel.id)) {
        addedRel++;
        _eventBus.publish(RelationshipCreatedEvent(
          relationshipId: rel.id,
          sourceId: rel.sourceId.value,
          targetId: rel.targetId.value,
          type: rel.type.name,
        ));
      }
    }

    _eventBus.publish(SynchronizationCompletedEvent(
      syncedObjectCount: addedObj + updatedObj,
      syncedRelationshipCount: addedRel,
    ));

    return SyncResult(
      packageName: adapter.packageName,
      objectsAdded: addedObj,
      objectsUpdated: updatedObj,
      relationshipsAdded: addedRel,
      conflicts: conflicts,
    );
  }
}
