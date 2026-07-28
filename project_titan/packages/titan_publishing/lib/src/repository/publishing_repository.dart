import 'package:titan_content_authoring/titan_content_authoring.dart';
import '../models/publishing_models.dart';

abstract class PublishingRepository {
  Future<void> recordVersionSnapshot(ContentVersionRecord record);
  Future<List<ContentVersionRecord>> getVersionHistory(String contentId);
  Future<ContentVersionRecord?> getVersionById(String versionId);

  Future<void> logWorkflowTransition(WorkflowAuditEntry entry);
  Future<List<WorkflowAuditEntry>> getWorkflowAuditLog(String contentId);

  Future<KmpAuthoringItem> transitionState({
    required KmpAuthoringItem item,
    required PublicationStatus targetStatus,
    required String actorId,
    required String actorRole,
    String comments = '',
  });

  Future<KmpAuthoringItem> rollbackToVersion({
    required KmpAuthoringItem currentItem,
    required String targetVersionId,
    required String actorId,
  });
}
