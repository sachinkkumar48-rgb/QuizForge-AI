library;

import '../entities/audit_log_entry.dart';
import '../entities/dashboard_metrics.dart';
import '../entities/editorial_status.dart';
import '../entities/knowledge_object.dart';
import '../entities/knowledge_object_version.dart';

/// Abstract repository contract for GARUDA Editorial Studio operations.
abstract class EditorialRepository {
  // Knowledge Object Lifecycle CRUD
  Future<List<KnowledgeObject>> getKnowledgeObjects({
    EditorialStatus? status,
    String? subject,
    String? topic,
    String? searchQuery,
  });

  Future<KnowledgeObject?> getKnowledgeObjectById(String id);

  Future<KnowledgeObject> saveKnowledgeObject(KnowledgeObject object, {required String editor, String? changeSummary});

  Future<KnowledgeObject> updateKnowledgeObject(KnowledgeObject object, {required String editor, required String changeSummary});

  Future<bool> deleteKnowledgeObject(String id, {required String editor, String? reason});

  Future<KnowledgeObject> duplicateKnowledgeObject(String id, {required String editor});

  Future<KnowledgeObject> changeStatus(String id, EditorialStatus newStatus, {required String editor, String? comment});

  // Version Control
  Future<List<KnowledgeObjectVersion>> getVersionHistory(String objectId);

  Future<KnowledgeObject?> restoreVersion(String objectId, int versionNumber, {required String editor});

  // Audit Trail
  Future<List<AuditLogEntry>> getAuditLogs({String? objectId, String? editor});

  Future<void> logAuditEntry(AuditLogEntry entry);

  // Metrics
  Future<DashboardMetrics> getDashboardMetrics();
}
