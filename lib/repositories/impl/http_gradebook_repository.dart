import 'package:garuda_learning/garuda_learning.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';

/// HTTP and offline-first implementation of [GradebookRepository] (TITAN-KO P50 / P57).
/// Communicates with FastAPI backend `/api/v1/lms/gradebook`.
class HttpGradebookRepository implements GradebookRepository {
  final ApiClient _apiClient;
  final InMemoryGradebookRepository _local;

  HttpGradebookRepository({
    ApiClient? apiClient,
    InMemoryGradebookRepository? localStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _local = localStore ?? InMemoryGradebookRepository();

  // ---------------------------------------------------------------------------
  // Grade Entries
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveGradeEntry(GradebookEntry entry) async {
    await _local.saveGradeEntry(entry);
    try {
      await _apiClient.post('/api/v1/lms/gradebook/entries', body: entry.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveGradeEntry failed, cached locally: $e', tag: 'HttpGradebookRepo');
    }
  }

  @override
  Future<GradebookEntry?> getGradeEntry(String entryId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/gradebook/entries/${Uri.encodeComponent(entryId)}');
      if (res.isNotEmpty && (res['entry'] != null || res['entryId'] != null)) {
        final eMap = (res['entry'] is Map)
            ? Map<String, dynamic>.from(res['entry'] as Map)
            : Map<String, dynamic>.from(res);
        final entry = GradebookEntry.fromJson(eMap);
        await _local.saveGradeEntry(entry);
        return entry;
      }
    } catch (e) {
      AppLogger.debug('Remote getGradeEntry fallback to local: $e', tag: 'HttpGradebookRepo');
    }
    return _local.getGradeEntry(entryId);
  }

  @override
  Future<GradebookEntry?> getEntry(String entryId) => getGradeEntry(entryId);

  @override
  Future<GradebookEntry?> getGradeEntryByLearnerAndAssessment(
    String learnerId,
    String assessmentId,
  ) async {
    try {
      final query =
          'learnerId=${Uri.encodeComponent(learnerId)}&assessmentId=${Uri.encodeComponent(assessmentId)}';
      final res = await _apiClient.get('/api/v1/lms/gradebook/entries/by-learner-assessment?$query');
      if (res.isNotEmpty && (res['entry'] != null || res['entryId'] != null)) {
        final eMap = (res['entry'] is Map)
            ? Map<String, dynamic>.from(res['entry'] as Map)
            : Map<String, dynamic>.from(res);
        final entry = GradebookEntry.fromJson(eMap);
        await _local.saveGradeEntry(entry);
        return entry;
      }
    } catch (e) {
      AppLogger.debug('Remote getGradeEntryByLearnerAndAssessment fallback to local: $e', tag: 'HttpGradebookRepo');
    }
    return _local.getGradeEntryByLearnerAndAssessment(learnerId, assessmentId);
  }

  @override
  Future<List<GradebookEntry>> listGradeEntries({
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    GradePublicationStatus? publicationStatus,
  }) async {
    try {
      final params = <String>[];
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (assessmentId != null) params.add('assessmentId=${Uri.encodeComponent(assessmentId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (publicationStatus != null) params.add('publicationStatus=${Uri.encodeComponent(publicationStatus.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/gradebook/entries$query');
      final dynamic listData = res['entries'] ?? res['data'];
      if (listData is List) {
        final entries = listData
            .map((e) => GradebookEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        for (final e in entries) {
          await _local.saveGradeEntry(e);
        }
        return entries;
      }
    } catch (e) {
      AppLogger.debug('Remote listGradeEntries fallback to local: $e', tag: 'HttpGradebookRepo');
    }
    return _local.listGradeEntries(
      tenantId: tenantId,
      cohortId: cohortId,
      assessmentId: assessmentId,
      learnerId: learnerId,
      publicationStatus: publicationStatus,
    );
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

  // ---------------------------------------------------------------------------
  // Disputes
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveDispute(GradeDispute dispute) async {
    await _local.saveDispute(dispute);
    try {
      await _apiClient.post('/api/v1/lms/gradebook/disputes', body: dispute.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveDispute failed: $e', tag: 'HttpGradebookRepo');
    }
  }

  @override
  Future<GradeDispute?> getDispute(String disputeId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/gradebook/disputes/${Uri.encodeComponent(disputeId)}');
      if (res.isNotEmpty && (res['dispute'] != null || res['disputeId'] != null)) {
        final dMap = (res['dispute'] is Map)
            ? Map<String, dynamic>.from(res['dispute'] as Map)
            : Map<String, dynamic>.from(res);
        final dispute = GradeDispute.fromJson(dMap);
        await _local.saveDispute(dispute);
        return dispute;
      }
    } catch (e) {
      AppLogger.debug('Remote getDispute fallback to local: $e', tag: 'HttpGradebookRepo');
    }
    return _local.getDispute(disputeId);
  }

  @override
  Future<List<GradeDispute>> listDisputes({
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    GradeDisputeStatus? status,
  }) async {
    try {
      final params = <String>[];
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (assessmentId != null) params.add('assessmentId=${Uri.encodeComponent(assessmentId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/gradebook/disputes$query');
      final dynamic listData = res['disputes'] ?? res['data'];
      if (listData is List) {
        final disputes = listData
            .map((d) => GradeDispute.fromJson(Map<String, dynamic>.from(d as Map)))
            .toList();
        for (final d in disputes) {
          await _local.saveDispute(d);
        }
        return disputes;
      }
    } catch (e) {
      AppLogger.debug('Remote listDisputes fallback to local: $e', tag: 'HttpGradebookRepo');
    }
    return _local.listDisputes(
      tenantId: tenantId,
      cohortId: cohortId,
      assessmentId: assessmentId,
      learnerId: learnerId,
      status: status,
    );
  }

  // ---------------------------------------------------------------------------
  // Overrides & Audits
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveOverride(GradeOverrideRecord record) async {
    await _local.saveOverride(record);
    try {
      await _apiClient.post('/api/v1/lms/gradebook/overrides', body: record.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveOverride failed: $e', tag: 'HttpGradebookRepo');
    }
  }

  @override
  Future<List<GradeOverrideRecord>> listOverrides({
    String? entryId,
    String? learnerId,
    String? assessmentId,
  }) async {
    try {
      final params = <String>[];
      if (entryId != null) params.add('entryId=${Uri.encodeComponent(entryId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (assessmentId != null) params.add('assessmentId=${Uri.encodeComponent(assessmentId)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/gradebook/overrides$query');
      final dynamic listData = res['overrides'] ?? res['data'];
      if (listData is List) {
        return listData
            .map((o) => GradeOverrideRecord.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('Remote listOverrides fallback to local: $e', tag: 'HttpGradebookRepo');
    }
    return _local.listOverrides(
      entryId: entryId,
      learnerId: learnerId,
      assessmentId: assessmentId,
    );
  }

  @override
  Future<void> saveAuditRecord(GradeAuditRecord record) async {
    await _local.saveAuditRecord(record);
    try {
      await _apiClient.post('/api/v1/lms/gradebook/audit', body: record.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveAuditRecord failed: $e', tag: 'HttpGradebookRepo');
    }
  }

  @override
  Future<List<GradeAuditRecord>> listAuditRecords({
    String? entryId,
    String? cohortId,
    String? learnerId,
  }) async {
    try {
      final params = <String>[];
      if (entryId != null) params.add('entryId=${Uri.encodeComponent(entryId)}');
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/gradebook/audit$query');
      final dynamic listData = res['audits'] ?? res['data'];
      if (listData is List) {
        return listData
            .map((a) => GradeAuditRecord.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('Remote listAuditRecords fallback to local: $e', tag: 'HttpGradebookRepo');
    }
    return _local.listAuditRecords(
      entryId: entryId,
      cohortId: cohortId,
      learnerId: learnerId,
    );
  }

  // ---------------------------------------------------------------------------
  // Snapshots & Maintenance
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> exportSnapshot() => _local.exportSnapshot();

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) => _local.importSnapshot(snapshot);

  @override
  Future<void> clear() => _local.clear();
}
