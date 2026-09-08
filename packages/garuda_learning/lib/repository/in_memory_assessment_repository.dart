/// In-Memory Assessment Repository Implementation (TITAN-KO-049.0 P49).
///
/// Production reference repository supporting snapshot persistence roundtrip,
/// tenant isolation filtering, and deterministic ordering.
library;

import '../domain/entities/assessment.dart';
import '../domain/entities/assessment_attempt.dart';
import '../domain/entities/assessment_result.dart';
import 'assessment_repository.dart';

class InMemoryAssessmentRepository implements AssessmentRepository {
  final Map<String, Assessment> _assessments = {};
  final Map<String, AssessmentAttempt> _attempts = {};
  final Map<String, AssessmentResult> _results = {};

  bool _simulateFailure = false;

  void setSimulateFailure(bool fail) {
    _simulateFailure = fail;
  }

  void _checkFailure() {
    if (_simulateFailure) {
      throw const AssessmentRepositoryException(
          'Simulated storage/repository failure');
    }
  }

  @override
  Future<void> saveAssessment(Assessment assessment) async {
    _checkFailure();
    _assessments[assessment.assessmentId] = assessment;
  }

  @override
  Future<Assessment?> getAssessmentById(String assessmentId) async {
    _checkFailure();
    return _assessments[assessmentId];
  }

  @override
  Future<List<Assessment>> listAssessments({
    String? tenantId,
    String? creatorFacultyId,
    String? cohortId,
    AssessmentStatus? status,
  }) async {
    _checkFailure();
    var list = _assessments.values.toList();

    if (tenantId != null) {
      list = list.where((a) => a.tenantId == tenantId).toList();
    }
    if (creatorFacultyId != null) {
      list = list.where((a) => a.creatorFacultyId == creatorFacultyId).toList();
    }
    if (cohortId != null) {
      list = list.where((a) => a.hasCohort(cohortId)).toList();
    }
    if (status != null) {
      list = list.where((a) => a.status == status).toList();
    }

    list.sort((a, b) => a.assessmentId.compareTo(b.assessmentId));
    return List.unmodifiable(list);
  }

  @override
  Future<void> deleteAssessment(String assessmentId) async {
    _checkFailure();
    _assessments.remove(assessmentId);
  }

  @override
  Future<void> saveAttempt(AssessmentAttempt attempt) async {
    _checkFailure();
    _attempts[attempt.attemptId] = attempt;
  }

  @override
  Future<AssessmentAttempt?> getAttemptById(String attemptId) async {
    _checkFailure();
    return _attempts[attemptId];
  }

  @override
  Future<List<AssessmentAttempt>> listAttempts({
    String? assessmentId,
    String? learnerId,
    AssessmentAttemptStatus? status,
  }) async {
    _checkFailure();
    var list = _attempts.values.toList();

    if (assessmentId != null) {
      list = list.where((a) => a.assessmentId == assessmentId).toList();
    }
    if (learnerId != null) {
      list = list.where((a) => a.learnerId == learnerId).toList();
    }
    if (status != null) {
      list = list.where((a) => a.status == status).toList();
    }

    list.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return List.unmodifiable(list);
  }

  @override
  Future<void> saveResult(AssessmentResult result) async {
    _checkFailure();
    _results[result.resultId] = result;
  }

  @override
  Future<AssessmentResult?> getResultById(String resultId) async {
    _checkFailure();
    return _results[resultId];
  }

  @override
  Future<AssessmentResult?> getResultForAttempt(String attemptId) async {
    _checkFailure();
    for (final res in _results.values) {
      if (res.attemptId == attemptId) return res;
    }
    return null;
  }

  @override
  Future<List<AssessmentResult>> listResults({
    String? assessmentId,
    String? learnerId,
  }) async {
    _checkFailure();
    var list = _results.values.toList();

    if (assessmentId != null) {
      list = list.where((r) => r.assessmentId == assessmentId).toList();
    }
    if (learnerId != null) {
      list = list.where((r) => r.learnerId == learnerId).toList();
    }

    list.sort((a, b) => a.evaluatedAt.compareTo(b.evaluatedAt));
    return List.unmodifiable(list);
  }

  @override
  Future<Map<String, dynamic>> exportSnapshot() async {
    _checkFailure();
    return {
      'assessments': _assessments.values.map((a) => a.toJson()).toList(),
      'attempts': _attempts.values.map((a) => a.toJson()).toList(),
      'results': _results.values.map((r) => r.toJson()).toList(),
    };
  }

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    _checkFailure();
    _assessments.clear();
    _attempts.clear();
    _results.clear();

    final rawAssessments =
        snapshot['assessments'] as List<dynamic>? ?? const [];
    for (final raw in rawAssessments) {
      final a = Assessment.fromJson(Map<String, dynamic>.from(raw as Map));
      _assessments[a.assessmentId] = a;
    }

    final rawAttempts = snapshot['attempts'] as List<dynamic>? ?? const [];
    for (final raw in rawAttempts) {
      final att =
          AssessmentAttempt.fromJson(Map<String, dynamic>.from(raw as Map));
      _attempts[att.attemptId] = att;
    }

    final rawResults = snapshot['results'] as List<dynamic>? ?? const [];
    for (final raw in rawResults) {
      final res =
          AssessmentResult.fromJson(Map<String, dynamic>.from(raw as Map));
      _results[res.resultId] = res;
    }
  }

  @override
  Future<void> clear() async {
    _assessments.clear();
    _attempts.clear();
    _results.clear();
  }
}
