import 'package:garuda_learning/garuda_learning.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';

/// HTTP and offline-first implementation of [AssessmentRepository] (TITAN-KO P49 / P57).
/// Communicates with FastAPI backend `/api/v1/lms/assessments`.
class HttpAssessmentRepository implements AssessmentRepository {
  final ApiClient _apiClient;
  final InMemoryAssessmentRepository _local;

  HttpAssessmentRepository({
    ApiClient? apiClient,
    InMemoryAssessmentRepository? localStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _local = localStore ?? InMemoryAssessmentRepository();

  // ---------------------------------------------------------------------------
  // Assessment Definitions
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAssessment(Assessment assessment) async {
    await _local.saveAssessment(assessment);
    try {
      await _apiClient.post('/api/v1/lms/assessments', body: assessment.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveAssessment failed, cached locally: $e', tag: 'HttpAssessmentRepo');
    }
  }

  @override
  Future<Assessment?> getAssessmentById(String assessmentId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/assessments/${Uri.encodeComponent(assessmentId)}');
      if (res.isNotEmpty && (res['assessment'] != null || res['assessmentId'] != null)) {
        final aMap = (res['assessment'] is Map)
            ? Map<String, dynamic>.from(res['assessment'] as Map)
            : Map<String, dynamic>.from(res);
        final assessment = Assessment.fromJson(aMap);
        await _local.saveAssessment(assessment);
        return assessment;
      }
    } catch (e) {
      AppLogger.debug('Remote getAssessmentById fallback to local: $e', tag: 'HttpAssessmentRepo');
    }
    return _local.getAssessmentById(assessmentId);
  }

  @override
  Future<List<Assessment>> listAssessments({
    String? tenantId,
    String? creatorFacultyId,
    String? cohortId,
    AssessmentStatus? status,
  }) async {
    try {
      final params = <String>[];
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (creatorFacultyId != null) params.add('creatorFacultyId=${Uri.encodeComponent(creatorFacultyId)}');
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/assessments$query');
      final dynamic listData = res['assessments'] ?? res['data'];
      if (listData is List) {
        final assessments = listData
            .map((a) => Assessment.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
        for (final a in assessments) {
          await _local.saveAssessment(a);
        }
        return assessments;
      }
    } catch (e) {
      AppLogger.debug('Remote listAssessments fallback to local: $e', tag: 'HttpAssessmentRepo');
    }
    return _local.listAssessments(
      tenantId: tenantId,
      creatorFacultyId: creatorFacultyId,
      cohortId: cohortId,
      status: status,
    );
  }

  @override
  Future<void> deleteAssessment(String assessmentId) async {
    await _local.deleteAssessment(assessmentId);
    try {
      await _apiClient.delete('/api/v1/lms/assessments/${Uri.encodeComponent(assessmentId)}');
    } catch (e) {
      AppLogger.debug('Remote deleteAssessment failed: $e', tag: 'HttpAssessmentRepo');
    }
  }

  // ---------------------------------------------------------------------------
  // Attempts
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAttempt(AssessmentAttempt attempt) async {
    await _local.saveAttempt(attempt);
    try {
      await _apiClient.post('/api/v1/lms/assessments/attempts', body: attempt.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveAttempt failed, cached locally: $e', tag: 'HttpAssessmentRepo');
    }
  }

  @override
  Future<AssessmentAttempt?> getAttemptById(String attemptId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/assessments/attempts/${Uri.encodeComponent(attemptId)}');
      if (res.isNotEmpty && (res['attempt'] != null || res['attemptId'] != null)) {
        final aMap = (res['attempt'] is Map)
            ? Map<String, dynamic>.from(res['attempt'] as Map)
            : Map<String, dynamic>.from(res);
        final attempt = AssessmentAttempt.fromJson(aMap);
        await _local.saveAttempt(attempt);
        return attempt;
      }
    } catch (e) {
      AppLogger.debug('Remote getAttemptById fallback to local: $e', tag: 'HttpAssessmentRepo');
    }
    return _local.getAttemptById(attemptId);
  }

  @override
  Future<List<AssessmentAttempt>> listAttempts({
    String? assessmentId,
    String? learnerId,
    AssessmentAttemptStatus? status,
  }) async {
    try {
      final params = <String>[];
      if (assessmentId != null) params.add('assessmentId=${Uri.encodeComponent(assessmentId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/assessments/attempts$query');
      final dynamic listData = res['attempts'] ?? res['data'];
      if (listData is List) {
        final attempts = listData
            .map((a) => AssessmentAttempt.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
        for (final a in attempts) {
          await _local.saveAttempt(a);
        }
        return attempts;
      }
    } catch (e) {
      AppLogger.debug('Remote listAttempts fallback to local: $e', tag: 'HttpAssessmentRepo');
    }
    return _local.listAttempts(assessmentId: assessmentId, learnerId: learnerId, status: status);
  }

  // ---------------------------------------------------------------------------
  // Results
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveResult(AssessmentResult result) async {
    await _local.saveResult(result);
    try {
      await _apiClient.post('/api/v1/lms/assessments/results', body: result.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveResult failed, cached locally: $e', tag: 'HttpAssessmentRepo');
    }
  }

  @override
  Future<AssessmentResult?> getResultById(String resultId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/assessments/results/${Uri.encodeComponent(resultId)}');
      if (res.isNotEmpty && (res['result'] != null || res['resultId'] != null)) {
        final rMap = (res['result'] is Map)
            ? Map<String, dynamic>.from(res['result'] as Map)
            : Map<String, dynamic>.from(res);
        final result = AssessmentResult.fromJson(rMap);
        await _local.saveResult(result);
        return result;
      }
    } catch (e) {
      AppLogger.debug('Remote getResultById fallback to local: $e', tag: 'HttpAssessmentRepo');
    }
    return _local.getResultById(resultId);
  }

  @override
  Future<AssessmentResult?> getResultForAttempt(String attemptId) async {
    try {
      final res = await _apiClient.get('/api/v1/lms/assessments/attempts/${Uri.encodeComponent(attemptId)}/result');
      if (res.isNotEmpty && (res['result'] != null || res['resultId'] != null)) {
        final rMap = (res['result'] is Map)
            ? Map<String, dynamic>.from(res['result'] as Map)
            : Map<String, dynamic>.from(res);
        final result = AssessmentResult.fromJson(rMap);
        await _local.saveResult(result);
        return result;
      }
    } catch (e) {
      AppLogger.debug('Remote getResultForAttempt fallback to local: $e', tag: 'HttpAssessmentRepo');
    }
    return _local.getResultForAttempt(attemptId);
  }

  @override
  Future<List<AssessmentResult>> listResults({
    String? assessmentId,
    String? learnerId,
  }) async {
    try {
      final params = <String>[];
      if (assessmentId != null) params.add('assessmentId=${Uri.encodeComponent(assessmentId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/assessments/results$query');
      final dynamic listData = res['results'] ?? res['data'];
      if (listData is List) {
        final results = listData
            .map((r) => AssessmentResult.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        for (final r in results) {
          await _local.saveResult(r);
        }
        return results;
      }
    } catch (e) {
      AppLogger.debug('Remote listResults fallback to local: $e', tag: 'HttpAssessmentRepo');
    }
    return _local.listResults(assessmentId: assessmentId, learnerId: learnerId);
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
