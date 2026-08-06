library;

import '../../domain/entities/editorial_status.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_object_version.dart';
import 'editorial_audit_trail.dart';

class RollbackResult {
  final KnowledgeObject restoredObject;
  final int restoredFromVersionNumber;

  const RollbackResult({
    required this.restoredObject,
    required this.restoredFromVersionNumber,
  });
}

class RollbackService {
  final EditorialAuditTrail auditTrail;

  RollbackService({required this.auditTrail});

  RollbackResult rollbackToVersion({
    required KnowledgeObject currentObject,
    required KnowledgeObjectVersion targetVersion,
    required String actorId,
    required String actorName,
    String? reason,
  }) {
    final snap = targetVersion.snapshotObject;

    final restored = currentObject.copyWith(
      title: snap.title,
      content: snap.content,
      subject: snap.subject,
      topic: snap.topic,
      subtopic: snap.subtopic,
      officialSource: snap.officialSource,
      evidenceIds: snap.evidenceIds,
      relatedArticles: snap.relatedArticles,
      relatedCaseLaws: snap.relatedCaseLaws,
      tags: snap.tags,
      isVerified: snap.isVerified,
      status: EditorialStatus.pendingReview,
      version: currentObject.version + 1,
      updatedAt: DateTime.now(),
    );

    auditTrail.record(
      objectId: currentObject.id,
      actorId: actorId,
      actorName: actorName,
      actionType: AuditActionType.rollback,
      summary: 'Rolled back object from version v${currentObject.version} to v${targetVersion.versionNumber}',
      comments: reason ?? 'Rollback initiated by editor.',
      metadata: {
        'fromVersion': currentObject.version,
        'toVersion': targetVersion.versionNumber,
      },
    );

    return RollbackResult(
      restoredObject: restored,
      restoredFromVersionNumber: targetVersion.versionNumber,
    );
  }

  KnowledgeObject restoreArchivedObject({
    required KnowledgeObject archivedObject,
    required String actorId,
    required String actorName,
  }) {
    final restored = archivedObject.copyWith(
      status: EditorialStatus.pendingReview,
      version: archivedObject.version + 1,
      updatedAt: DateTime.now(),
    );

    auditTrail.record(
      objectId: archivedObject.id,
      actorId: actorId,
      actorName: actorName,
      actionType: AuditActionType.restored,
      summary: 'Restored archived Knowledge Object to Pending Review.',
    );

    return restored;
  }
}
