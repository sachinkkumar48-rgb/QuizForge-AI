import 'package:meta/meta.dart';

@immutable
abstract class KnowledgeEvent {
  final DateTime timestamp;

  KnowledgeEvent() : timestamp = DateTime.now();
}

class ObjectRegisteredEvent extends KnowledgeEvent {
  final String objectId;
  final String objectType;
  final String packageName;

  ObjectRegisteredEvent({
    required this.objectId,
    required this.objectType,
    required this.packageName,
  });
}

class ObjectUpdatedEvent extends KnowledgeEvent {
  final String objectId;
  final int newVersion;

  ObjectUpdatedEvent({
    required this.objectId,
    required this.newVersion,
  });
}

class ObjectDeletedEvent extends KnowledgeEvent {
  final String objectId;

  ObjectDeletedEvent({required this.objectId});
}

class RelationshipCreatedEvent extends KnowledgeEvent {
  final String relationshipId;
  final String sourceId;
  final String targetId;
  final String type;

  RelationshipCreatedEvent({
    required this.relationshipId,
    required this.sourceId,
    required this.targetId,
    required this.type,
  });
}

class RelationshipRemovedEvent extends KnowledgeEvent {
  final String relationshipId;

  RelationshipRemovedEvent({required this.relationshipId});
}

class EvidenceUpdatedEvent extends KnowledgeEvent {
  final String evidenceId;
  final String targetObjectId;

  EvidenceUpdatedEvent({
    required this.evidenceId,
    required this.targetObjectId,
  });
}

class PackageLoadedEvent extends KnowledgeEvent {
  final String packageName;
  final String version;

  PackageLoadedEvent({
    required this.packageName,
    required this.version,
  });
}

class PackageReloadedEvent extends KnowledgeEvent {
  final String packageName;

  PackageReloadedEvent({required this.packageName});
}

class SynchronizationCompletedEvent extends KnowledgeEvent {
  final int syncedObjectCount;
  final int syncedRelationshipCount;

  SynchronizationCompletedEvent({
    required this.syncedObjectCount,
    required this.syncedRelationshipCount,
  });
}
