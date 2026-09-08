/// In-Memory Gradebook Repository Implementation (TITAN-KO-050.0 P50).
///
/// Production reference repository supporting restart snapshot persistence,
/// tenant isolation filtering, error simulation, and audit logging.
library;

import '../domain/entities/grade_audit_record.dart';
import '../domain/entities/grade_dispute.dart';
import '../domain/entities/grade_override.dart';
import '../domain/entities/gradebook_entry.dart';
import 'gradebook_repository.dart';

class InMemoryGradebookRepository implements GradebookRepository {
  final Map<String, GradebookEntry> _entries = {};
  final Map<String, GradeDispute> _disputes = {};
  final List<GradeOverrideRecord> _overrides = [];
  final List<GradeAuditRecord> _auditRecords = [];

  bool _simulateFailure = false;

  void setSimulateFailure(bool fail) {
    _simulateFailure = fail;
  }

  void _checkFailure() {
    if (_simulateFailure) {
      throw const GradeRepositoryException(
          'Simulated gradebook storage/repository failure');
    }
  }

  @override
  Future<void> saveGradeEntry(GradebookEntry entry) async {
    _checkFailure();
    _entries[entry.entryId] = entry;
  }

  @override
  Future<GradebookEntry?> getGradeEntry(String entryId) async {
    _checkFailure();
    return _entries[entryId];
  }

  @override
  Future<GradebookEntry?> getEntry(String entryId) => getGradeEntry(entryId);

  @override
  Future<GradebookEntry?> getGradeEntryByLearnerAndAssessment(
    String learnerId,
    String assessmentId,
  ) async {
    _checkFailure();
    for (final e in _entries.values) {
      if (e.learnerId == learnerId && e.assessmentId == assessmentId) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<List<GradebookEntry>> listGradeEntries({
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    GradePublicationStatus? publicationStatus,
  }) async {
    _checkFailure();
    var list = _entries.values.toList();

    if (tenantId != null) {
      list = list.where((e) => e.tenantId == tenantId).toList();
    }
    if (cohortId != null) {
      list = list.where((e) => e.cohortId == cohortId).toList();
    }
    if (assessmentId != null) {
      list = list.where((e) => e.assessmentId == assessmentId).toList();
    }
    if (learnerId != null) {
      list = list.where((e) => e.learnerId == learnerId).toList();
    }
    if (publicationStatus != null) {
      list =
          list.where((e) => e.publicationStatus == publicationStatus).toList();
    }

    list.sort((a, b) => a.entryId.compareTo(b.entryId));
    return List.unmodifiable(list);
  }

  @override
  Future<List<GradebookEntry>> listEntries({
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    GradePublicationStatus? publicationStatus,
  }) =>
      listGradeEntries(
        tenantId: tenantId,
        cohortId: cohortId,
        assessmentId: assessmentId,
        learnerId: learnerId,
        publicationStatus: publicationStatus,
      );

  @override
  Future<void> saveDispute(GradeDispute dispute) async {
    _checkFailure();
    _disputes[dispute.disputeId] = dispute;
  }

  @override
  Future<GradeDispute?> getDispute(String disputeId) async {
    _checkFailure();
    return _disputes[disputeId];
  }

  @override
  Future<List<GradeDispute>> listDisputes({
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    GradeDisputeStatus? status,
  }) async {
    _checkFailure();
    var list = _disputes.values.toList();

    if (tenantId != null) {
      list = list.where((d) => d.tenantId == tenantId).toList();
    }
    if (cohortId != null) {
      list = list.where((d) => d.cohortId == cohortId).toList();
    }
    if (assessmentId != null) {
      list = list.where((d) => d.assessmentId == assessmentId).toList();
    }
    if (learnerId != null) {
      list = list.where((d) => d.learnerId == learnerId).toList();
    }
    if (status != null) {
      list = list.where((d) => d.status == status).toList();
    }

    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<void> saveOverride(GradeOverrideRecord record) async {
    _checkFailure();
    _overrides.add(record);
  }

  @override
  Future<List<GradeOverrideRecord>> listOverrides({
    String? entryId,
    String? learnerId,
    String? assessmentId,
  }) async {
    _checkFailure();
    var list = _overrides.toList();

    if (entryId != null) {
      list = list.where((o) => o.entryId == entryId).toList();
    }
    if (learnerId != null) {
      list = list.where((o) => o.learnerId == learnerId).toList();
    }
    if (assessmentId != null) {
      list = list.where((o) => o.assessmentId == assessmentId).toList();
    }

    list.sort((a, b) => a.overriddenAt.compareTo(b.overriddenAt));
    return List.unmodifiable(list);
  }

  @override
  Future<void> saveAuditRecord(GradeAuditRecord record) async {
    _checkFailure();
    _auditRecords.add(record);
  }

  @override
  Future<List<GradeAuditRecord>> listAuditRecords({
    String? entryId,
    String? cohortId,
    String? learnerId,
  }) async {
    _checkFailure();
    var list = _auditRecords.toList();

    if (entryId != null) {
      list = list.where((a) => a.entryId == entryId).toList();
    }
    if (cohortId != null) {
      list = list.where((a) => a.cohortId == cohortId).toList();
    }
    if (learnerId != null) {
      list = list.where((a) => a.learnerId == learnerId).toList();
    }

    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return List.unmodifiable(list);
  }

  @override
  Future<Map<String, dynamic>> exportSnapshot() async {
    _checkFailure();
    return {
      'entries': _entries.values.map((e) => e.toJson()).toList(),
      'disputes': _disputes.values.map((d) => d.toJson()).toList(),
      'overrides': _overrides.map((o) => o.toJson()).toList(),
      'auditRecords': _auditRecords.map((a) => a.toJson()).toList(),
    };
  }

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    _checkFailure();
    _entries.clear();
    _disputes.clear();
    _overrides.clear();
    _auditRecords.clear();

    final rawEntries = snapshot['entries'] as List<dynamic>? ?? const [];
    for (final raw in rawEntries) {
      final e = GradebookEntry.fromJson(Map<String, dynamic>.from(raw as Map));
      _entries[e.entryId] = e;
    }

    final rawDisputes = snapshot['disputes'] as List<dynamic>? ?? const [];
    for (final raw in rawDisputes) {
      final d = GradeDispute.fromJson(Map<String, dynamic>.from(raw as Map));
      _disputes[d.disputeId] = d;
    }

    final rawOverrides = snapshot['overrides'] as List<dynamic>? ?? const [];
    for (final raw in rawOverrides) {
      final o =
          GradeOverrideRecord.fromJson(Map<String, dynamic>.from(raw as Map));
      _overrides.add(o);
    }

    final rawAudit = snapshot['auditRecords'] as List<dynamic>? ?? const [];
    for (final raw in rawAudit) {
      final a =
          GradeAuditRecord.fromJson(Map<String, dynamic>.from(raw as Map));
      _auditRecords.add(a);
    }
  }

  @override
  Future<void> clear() async {
    _entries.clear();
    _disputes.clear();
    _overrides.clear();
    _auditRecords.clear();
  }
}
