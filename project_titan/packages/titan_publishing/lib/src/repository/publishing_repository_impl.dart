import 'package:titan_content_authoring/titan_content_authoring.dart';
import '../models/publishing_models.dart';
import 'publishing_repository.dart';

class PublishingRepositoryImpl implements PublishingRepository {
  final Map<String, List<ContentVersionRecord>> _versionStore = {};
  final Map<String, ContentVersionRecord> _versionByIdMap = {};
  final Map<String, List<WorkflowAuditEntry>> _auditLogStore = {};

  @override
  Future<void> recordVersionSnapshot(ContentVersionRecord record) async {
    _versionStore.putIfAbsent(record.contentId, () => []).add(record);
    _versionByIdMap[record.versionId] = record;
  }

  @override
  Future<List<ContentVersionRecord>> getVersionHistory(String contentId) async {
    return _versionStore[contentId] ?? const [];
  }

  @override
  Future<ContentVersionRecord?> getVersionById(String versionId) async {
    return _versionByIdMap[versionId];
  }

  @override
  Future<void> logWorkflowTransition(WorkflowAuditEntry entry) async {
    _auditLogStore.putIfAbsent(entry.contentId, () => []).add(entry);
  }

  @override
  Future<List<WorkflowAuditEntry>> getWorkflowAuditLog(String contentId) async {
    return _auditLogStore[contentId] ?? const [];
  }

  @override
  Future<KmpAuthoringItem> transitionState({
    required KmpAuthoringItem item,
    required PublicationStatus targetStatus,
    required String actorId,
    required String actorRole,
    String comments = '',
  }) async {
    final oldStatus = item.status;
    final updated =
        item.copyWith(status: targetStatus, updatedAt: DateTime.now());

    final audit = WorkflowAuditEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      contentId: item.id,
      fromStatus: oldStatus,
      toStatus: targetStatus,
      actorId: actorId,
      actorRole: actorRole,
      comments: comments,
      timestamp: DateTime.now(),
    );
    await logWorkflowTransition(audit);

    // Save snapshot
    final versionRecord = ContentVersionRecord(
      versionId: 'ver_${item.id}_${DateTime.now().millisecondsSinceEpoch}',
      contentId: item.id,
      versionNumber: item.version,
      snapshotTitle: item.title,
      snapshotBody: item.bodyContent,
      changeLogSummary:
          'State transitioned from ${oldStatus.name} to ${targetStatus.name}. $comments',
      authorId: actorId,
      createdAt: DateTime.now(),
    );
    await recordVersionSnapshot(versionRecord);

    return updated;
  }

  @override
  Future<KmpAuthoringItem> rollbackToVersion({
    required KmpAuthoringItem currentItem,
    required String targetVersionId,
    required String actorId,
  }) async {
    final snapshot = await getVersionById(targetVersionId);
    if (snapshot == null) {
      throw Exception('Version snapshot not found: $targetVersionId');
    }

    final rolledBack = currentItem.copyWith(
      title: snapshot.snapshotTitle,
      bodyContent: snapshot.snapshotBody,
      version: '${currentItem.version}-rollback',
      status: PublicationStatus.draft,
      updatedAt: DateTime.now(),
    );

    final audit = WorkflowAuditEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      contentId: currentItem.id,
      fromStatus: currentItem.status,
      toStatus: PublicationStatus.draft,
      actorId: actorId,
      actorRole: 'Editor',
      comments: 'Rolled back content to version ${snapshot.versionNumber}',
      timestamp: DateTime.now(),
    );
    await logWorkflowTransition(audit);

    return rolledBack;
  }
}
