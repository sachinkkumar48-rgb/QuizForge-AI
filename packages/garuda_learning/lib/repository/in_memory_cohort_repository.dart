/// In-Memory Cohort Repository Reference Implementation (TITAN-KO-048.0 P48).
///
/// Production reference repository supporting full snapshot persistence roundtrip,
/// multi-tenant querying, and deterministic sorting.
library;

import '../domain/entities/cohort.dart';
import '../domain/entities/cohort_assignment.dart';
import 'cohort_repository.dart';

class InMemoryCohortRepository implements CohortRepository {
  final Map<String, Cohort> _cohorts = {};
  final Map<String, CohortAssignment> _assignments = {};

  bool _simulateFailure = false;

  /// Enable or disable simulated storage failures for testing.
  void setSimulateFailure(bool fail) {
    _simulateFailure = fail;
  }

  void _checkFailure() {
    if (_simulateFailure) {
      throw const CohortRepositoryException(
          'Simulated storage/database failure occurred');
    }
  }

  @override
  Future<void> saveCohort(Cohort cohort) async {
    _checkFailure();
    _cohorts[cohort.cohortId] = cohort;
  }

  @override
  Future<Cohort?> getCohortById(String cohortId) async {
    _checkFailure();
    return _cohorts[cohortId];
  }

  @override
  Future<List<Cohort>> listCohorts({
    String? tenantId,
    String? facultyId,
    String? learnerId,
    CohortStatus? status,
  }) async {
    _checkFailure();
    var list = _cohorts.values.toList();

    if (tenantId != null) {
      list = list.where((c) => c.tenantId == tenantId).toList();
    }
    if (facultyId != null) {
      list = list.where((c) => c.hasFaculty(facultyId)).toList();
    }
    if (learnerId != null) {
      list = list.where((c) => c.hasLearner(learnerId)).toList();
    }
    if (status != null) {
      list = list.where((c) => c.status == status).toList();
    }

    list.sort((a, b) => a.cohortId.compareTo(b.cohortId));
    return List.unmodifiable(list);
  }

  @override
  Future<void> deleteCohort(String cohortId) async {
    _checkFailure();
    _cohorts.remove(cohortId);
  }

  @override
  Future<void> saveAssignment(CohortAssignment assignment) async {
    _checkFailure();
    _assignments[assignment.assignmentId] = assignment;
  }

  @override
  Future<CohortAssignment?> getAssignmentById(String assignmentId) async {
    _checkFailure();
    return _assignments[assignmentId];
  }

  @override
  Future<List<CohortAssignment>> listAssignments({
    String? cohortId,
    String? learnerId,
    CohortAssignmentStatus? status,
    String? tenantId,
  }) async {
    _checkFailure();
    var list = _assignments.values.toList();

    if (tenantId != null) {
      list = list.where((a) => a.tenantId == tenantId).toList();
    }
    if (cohortId != null) {
      list = list.where((a) => a.cohortId == cohortId).toList();
    }
    if (status != null) {
      list = list.where((a) => a.status == status).toList();
    }
    if (learnerId != null) {
      list = list.where((a) {
        final c = _cohorts[a.cohortId];
        return c != null && c.hasLearner(learnerId);
      }).toList();
    }

    list.sort((a, b) {
      final cmp = a.dueDate.compareTo(b.dueDate);
      if (cmp != 0) return cmp;
      return a.assignmentId.compareTo(b.assignmentId);
    });

    return List.unmodifiable(list);
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    _checkFailure();
    _assignments.remove(assignmentId);
  }

  @override
  Future<Map<String, dynamic>> exportSnapshot() async {
    _checkFailure();
    return {
      'cohorts': _cohorts.values.map((c) => c.toJson()).toList(),
      'assignments': _assignments.values.map((a) => a.toJson()).toList(),
    };
  }

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    _checkFailure();
    _cohorts.clear();
    _assignments.clear();

    final rawCohorts = snapshot['cohorts'] as List<dynamic>? ?? const [];
    for (final raw in rawCohorts) {
      final cohort = Cohort.fromJson(Map<String, dynamic>.from(raw as Map));
      _cohorts[cohort.cohortId] = cohort;
    }

    final rawAssignments =
        snapshot['assignments'] as List<dynamic>? ?? const [];
    for (final raw in rawAssignments) {
      final assignment =
          CohortAssignment.fromJson(Map<String, dynamic>.from(raw as Map));
      _assignments[assignment.assignmentId] = assignment;
    }
  }

  @override
  Future<void> clear() async {
    _cohorts.clear();
    _assignments.clear();
  }
}
