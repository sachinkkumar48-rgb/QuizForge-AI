library;

import '../domain/entities/audit_log_entry.dart';
import '../domain/entities/dashboard_metrics.dart';
import '../domain/entities/editorial_status.dart';
import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_object_version.dart';
import '../domain/repositories/editorial_repository.dart';

/// Thread-safe in-memory repository implementation for GARUDA Editorial Studio.
class InMemoryEditorialRepository implements EditorialRepository {
  final Map<String, KnowledgeObject> _objects = {};
  final Map<String, List<AuditLogEntry>> _auditLogs = {};

  InMemoryEditorialRepository() {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();

    final ko1 = KnowledgeObject(
      id: 'KO-POLITY-001',
      title: 'Right to Privacy & Article 21 Interpretation',
      subject: 'Polity',
      topic: 'Fundamental Rights',
      subtopic: 'Right to Life',
      concept: 'Privacy Rights',
      summary: 'Analysis of Article 21 scope post Puttaswamy judgment.',
      content: 'Article 21 guarantees life and personal liberty, interpreted dynamically by Supreme Court.',
      references: const ['Art 21', 'Puttaswamy Case 2017'],
      evidenceIds: const ['EV-SC-01'],
      status: EditorialStatus.reviewPending,
      currentVersion: 1,
      createdBy: 'SeniorEditor1',
      createdAt: now.subtract(const Duration(hours: 5)),
      updatedAt: now.subtract(const Duration(hours: 1)),
      versions: [
        KnowledgeObjectVersion(
          versionNumber: 1,
          editor: 'SeniorEditor1',
          timestamp: now.subtract(const Duration(hours: 5)),
          changeSummary: 'Initial creation of Knowledge Object KO-POLITY-001',
          snapshot: {'title': 'Right to Privacy & Article 21 Interpretation'},
        ),
      ],
    );

    final ko2 = KnowledgeObject(
      id: 'KO-GOV-002',
      title: 'Digital Personal Data Protection (DPDP) Act Overview',
      subject: 'Governance',
      topic: 'Digital Laws',
      subtopic: 'Data Governance',
      concept: 'Data Principal Rights',
      summary: 'Key provisions of DPDP Act 2023 statutory obligations.',
      content: 'Detailed breakdown of obligations of Data Fiduciaries and rights of Data Principals.',
      references: const ['DPDP Act 2023', 'MeitY Guidelines'],
      evidenceIds: const ['EV-PIB-2026-99'],
      status: EditorialStatus.draft,
      currentVersion: 1,
      createdBy: 'Editor2',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(hours: 3)),
      versions: [
        KnowledgeObjectVersion(
          versionNumber: 1,
          editor: 'Editor2',
          timestamp: now.subtract(const Duration(days: 1)),
          changeSummary: 'Drafted DPDP Act framework',
          snapshot: {'title': 'Digital Personal Data Protection (DPDP) Act Overview'},
        ),
      ],
    );

    final ko3 = KnowledgeObject(
      id: 'KO-ENV-003',
      title: 'National Green Hydrogen Mission Guidelines',
      subject: 'Environment',
      topic: 'Clean Energy',
      subtopic: 'Renewable Mission',
      concept: 'Green Hydrogen',
      summary: 'Government targets for green hydrogen production by 2030.',
      content: 'Strategic targets and financial incentives under SIGHT scheme.',
      references: const ['MNRE Circular 2023', 'Art 48A'],
      evidenceIds: const ['EV-PIB-2026-001'],
      status: EditorialStatus.published,
      currentVersion: 2,
      createdBy: 'Editor1',
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(hours: 8)),
      versions: [
        KnowledgeObjectVersion(
          versionNumber: 1,
          editor: 'Editor1',
          timestamp: now.subtract(const Duration(days: 3)),
          changeSummary: 'Initial draft',
          snapshot: {'title': 'Green Hydrogen Mission'},
        ),
        KnowledgeObjectVersion(
          versionNumber: 2,
          editor: 'SeniorEditor2',
          timestamp: now.subtract(const Duration(hours: 8)),
          changeSummary: 'Approved and published v2 with MNRE updates',
          snapshot: {'title': 'National Green Hydrogen Mission Guidelines'},
        ),
      ],
    );

    _objects[ko1.id] = ko1;
    _objects[ko2.id] = ko2;
    _objects[ko3.id] = ko3;

    logAuditEntry(AuditLogEntry(
      id: 'aud_01',
      editor: 'SeniorEditor1',
      timestamp: now.subtract(const Duration(hours: 5)),
      action: 'CREATE',
      objectId: 'KO-POLITY-001',
      newState: 'reviewPending',
      comment: 'Created and submitted for review',
    ));
  }

  @override
  Future<List<KnowledgeObject>> getKnowledgeObjects({
    EditorialStatus? status,
    String? subject,
    String? topic,
    String? searchQuery,
  }) async {
    var results = _objects.values.toList();

    if (status != null) {
      results = results.where((o) => o.status == status).toList();
    }
    if (subject != null && subject.isNotEmpty) {
      results = results.where((o) => o.subject.toLowerCase() == subject.toLowerCase()).toList();
    }
    if (topic != null && topic.isNotEmpty) {
      results = results.where((o) => o.topic.toLowerCase() == topic.toLowerCase()).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results.where((o) =>
          o.id.toLowerCase().contains(q) ||
          o.title.toLowerCase().contains(q) ||
          o.subject.toLowerCase().contains(q) ||
          o.topic.toLowerCase().contains(q) ||
          o.summary.toLowerCase().contains(q) ||
          o.references.any((r) => r.toLowerCase().contains(q))).toList();
    }

    return results;
  }

  @override
  Future<KnowledgeObject?> getKnowledgeObjectById(String id) async {
    return _objects[id];
  }

  @override
  Future<KnowledgeObject> saveKnowledgeObject(KnowledgeObject object, {required String editor, String? changeSummary}) async {
    final now = DateTime.now();
    final v1 = KnowledgeObjectVersion(
      versionNumber: 1,
      editor: editor,
      timestamp: now,
      changeSummary: changeSummary ?? 'Initial object creation',
      snapshot: object.toJson(),
    );

    final saved = object.copyWith(
      currentVersion: 1,
      createdBy: editor,
      createdAt: now,
      updatedAt: now,
      versions: [v1],
    );

    _objects[saved.id] = saved;

    await logAuditEntry(AuditLogEntry(
      id: 'aud_${now.millisecondsSinceEpoch}',
      editor: editor,
      timestamp: now,
      action: 'CREATE',
      objectId: saved.id,
      newState: saved.status.name,
      comment: changeSummary ?? 'Created object',
    ));

    return saved;
  }

  @override
  Future<KnowledgeObject> updateKnowledgeObject(KnowledgeObject object, {required String editor, required String changeSummary}) async {
    final existing = _objects[object.id];
    final now = DateTime.now();
    final nextVersionNum = (existing?.currentVersion ?? 0) + 1;

    final newVer = KnowledgeObjectVersion(
      versionNumber: nextVersionNum,
      editor: editor,
      timestamp: now,
      changeSummary: changeSummary,
      snapshot: object.toJson(),
    );

    final existingVers = existing?.versions ?? [];
    final updated = object.copyWith(
      currentVersion: nextVersionNum,
      updatedAt: now,
      versions: [...existingVers, newVer],
    );

    _objects[updated.id] = updated;

    await logAuditEntry(AuditLogEntry(
      id: 'aud_${now.millisecondsSinceEpoch}',
      editor: editor,
      timestamp: now,
      action: 'UPDATE',
      objectId: updated.id,
      previousState: existing?.status.name ?? '',
      newState: updated.status.name,
      comment: changeSummary,
    ));

    return updated;
  }

  @override
  Future<bool> deleteKnowledgeObject(String id, {required String editor, String? reason}) async {
    final existing = _objects.remove(id);
    if (existing != null) {
      await logAuditEntry(AuditLogEntry(
        id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
        editor: editor,
        timestamp: DateTime.now(),
        action: 'DELETE',
        objectId: id,
        previousState: existing.status.name,
        comment: reason ?? 'Object deleted',
      ));
      return true;
    }
    return false;
  }

  @override
  Future<KnowledgeObject> duplicateKnowledgeObject(String id, {required String editor}) async {
    final source = _objects[id];
    if (source == null) throw Exception('Knowledge Object $id not found for duplication.');

    final now = DateTime.now();
    final dupId = 'KO-COPY-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final dup = source.copyWith(
      id: dupId,
      title: '${source.title} (Copy)',
      status: EditorialStatus.draft,
      currentVersion: 1,
      createdBy: editor,
      createdAt: now,
      updatedAt: now,
      versions: [],
    );

    return saveKnowledgeObject(dup, editor: editor, changeSummary: 'Duplicated from ${source.id}');
  }

  @override
  Future<KnowledgeObject> changeStatus(String id, EditorialStatus newStatus, {required String editor, String? comment}) async {
    final existing = _objects[id];
    if (existing == null) throw Exception('Knowledge Object $id not found.');

    final updated = existing.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    _objects[id] = updated;

    await logAuditEntry(AuditLogEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      editor: editor,
      timestamp: DateTime.now(),
      action: 'STATUS_CHANGE',
      objectId: id,
      previousState: existing.status.name,
      newState: newStatus.name,
      comment: comment ?? 'Status updated to ${newStatus.name}',
    ));

    return updated;
  }

  @override
  Future<List<KnowledgeObjectVersion>> getVersionHistory(String objectId) async {
    return _objects[objectId]?.versions ?? [];
  }

  @override
  Future<KnowledgeObject?> restoreVersion(String objectId, int versionNumber, {required String editor}) async {
    final existing = _objects[objectId];
    if (existing == null) return null;

    final targetVer = existing.versions.firstWhere(
      (v) => v.versionNumber == versionNumber,
      orElse: () => existing.versions.last,
    );

    final restoredFromSnapshot = KnowledgeObject.fromJson(targetVer.snapshot);
    return updateKnowledgeObject(
      restoredFromSnapshot.copyWith(
        id: objectId,
        status: existing.status,
      ),
      editor: editor,
      changeSummary: 'Restored to Version $versionNumber',
    );
  }

  @override
  Future<List<AuditLogEntry>> getAuditLogs({String? objectId, String? editor}) async {
    var allLogs = _auditLogs.values.expand((element) => element).toList();
    if (objectId != null) {
      allLogs = allLogs.where((l) => l.objectId == objectId).toList();
    }
    if (editor != null) {
      allLogs = allLogs.where((l) => l.editor == editor).toList();
    }
    allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allLogs;
  }

  @override
  Future<void> logAuditEntry(AuditLogEntry entry) async {
    _auditLogs.putIfAbsent(entry.objectId, () => []).add(entry);
  }

  @override
  Future<DashboardMetrics> getDashboardMetrics() async {
    final allObjs = _objects.values.toList();
    final today = DateTime.now();

    return DashboardMetrics(
      pendingEvidenceCount: 3, // Mock pending evidence inbox count
      pendingLinksCount: 4, // Mock pending link suggestions count
      pendingPublicationsCount: allObjs.where((o) => o.status == EditorialStatus.reviewPending || o.status == EditorialStatus.approved).length,
      publishedTodayCount: allObjs.where((o) => o.status == EditorialStatus.published && o.updatedAt.day == today.day).length,
      recentlyUpdatedCount: allObjs.where((o) => o.updatedAt.isAfter(today.subtract(const Duration(days: 1)))).length,
      draftObjectsCount: allObjs.where((o) => o.status == EditorialStatus.draft).length,
      rejectedObjectsCount: allObjs.where((o) => o.status == EditorialStatus.rejected).length,
    );
  }
}
