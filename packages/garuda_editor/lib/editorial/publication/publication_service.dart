library;

import '../../domain/entities/editorial_status.dart';
import '../../domain/entities/knowledge_object.dart';
import '../history/editorial_audit_trail.dart';
import '../history/rollback_service.dart';
import '../verification/quality_gates.dart';

class BulkPublicationResult {
  final List<KnowledgeObject> publishedObjects;
  final Map<String, List<String>> failedObjectReasons;

  const BulkPublicationResult({
    required this.publishedObjects,
    required this.failedObjectReasons,
  });

  int get successCount => publishedObjects.length;
  int get failureCount => failedObjectReasons.length;
}

class PublicationService {
  final EditorialAuditTrail auditTrail;
  final RollbackService rollbackService;

  PublicationService({
    required this.auditTrail,
    required this.rollbackService,
  });

  KnowledgeObject publish(
    KnowledgeObject object, {
    required String actorId,
    required String actorName,
    bool skipQualityGates = false,
  }) {
    if (!skipQualityGates) {
      final gateResult = QualityGates.validatePublicationGate(object);
      if (!gateResult.isPassed) {
        throw StateError(
            'Cannot publish KnowledgeObject "${object.id}": ${gateResult.blockingReasons.join("; ")}');
      }
    }

    final published = object.copyWith(
      status: EditorialStatus.published,
      version: object.version + 1,
      updatedAt: DateTime.now(),
    );

    auditTrail.record(
      objectId: object.id,
      actorId: actorId,
      actorName: actorName,
      actionType: AuditActionType.published,
      summary: 'Knowledge Object published to GARUDA production corpus.',
    );

    return published;
  }

  KnowledgeObject unpublish(
    KnowledgeObject object, {
    required String actorId,
    required String actorName,
    String? reason,
  }) {
    if (object.status != EditorialStatus.published) {
      throw StateError('Cannot unpublish object that is not currently Published.');
    }

    final unpublished = object.copyWith(
      status: EditorialStatus.approved,
      version: object.version + 1,
      updatedAt: DateTime.now(),
    );

    auditTrail.record(
      objectId: object.id,
      actorId: actorId,
      actorName: actorName,
      actionType: AuditActionType.unpublished,
      summary: 'Unpublished object back to Approved status.',
      comments: reason,
    );

    return unpublished;
  }

  KnowledgeObject republish(
    KnowledgeObject object, {
    required String actorId,
    required String actorName,
  }) {
    final republished = object.copyWith(
      status: EditorialStatus.published,
      version: object.version + 1,
      updatedAt: DateTime.now(),
    );

    auditTrail.record(
      objectId: object.id,
      actorId: actorId,
      actorName: actorName,
      actionType: AuditActionType.republished,
      summary: 'Republished updated Knowledge Object to GARUDA corpus.',
    );

    return republished;
  }

  KnowledgeObject archive(
    KnowledgeObject object, {
    required String actorId,
    required String actorName,
    String? reason,
  }) {
    final archived = object.copyWith(
      status: EditorialStatus.archived,
      version: object.version + 1,
      updatedAt: DateTime.now(),
    );

    auditTrail.record(
      objectId: object.id,
      actorId: actorId,
      actorName: actorName,
      actionType: AuditActionType.archived,
      summary: 'Knowledge Object archived.',
      comments: reason,
    );

    return archived;
  }

  KnowledgeObject restore(
    KnowledgeObject object, {
    required String actorId,
    required String actorName,
  }) {
    return rollbackService.restoreArchivedObject(
      archivedObject: object,
      actorId: actorId,
      actorName: actorName,
    );
  }

  BulkPublicationResult bulkPublish(
    List<KnowledgeObject> objects, {
    required String actorId,
    required String actorName,
  }) {
    final List<KnowledgeObject> publishedList = [];
    final Map<String, List<String>> failures = {};

    for (final obj in objects) {
      final gateResult = QualityGates.validatePublicationGate(obj);
      if (gateResult.isPassed) {
        final pub = publish(obj, actorId: actorId, actorName: actorName, skipQualityGates: true);
        publishedList.add(pub);
      } else {
        failures[obj.id] = gateResult.blockingReasons;
      }
    }

    return BulkPublicationResult(
      publishedObjects: publishedList,
      failedObjectReasons: failures,
    );
  }

  List<KnowledgeObject> bulkArchive(
    List<KnowledgeObject> objects, {
    required String actorId,
    required String actorName,
    String? reason,
  }) {
    return objects
        .map((obj) => archive(obj, actorId: actorId, actorName: actorName, reason: reason))
        .toList();
  }
}
