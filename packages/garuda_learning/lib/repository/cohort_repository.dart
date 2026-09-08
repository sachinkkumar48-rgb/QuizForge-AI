/// Institutional Cohort Repository Contract (TITAN-KO-048.0 P48).
///
/// Abstract persistence boundary for institutional cohorts, memberships,
/// and targeted assignments.
library;

import '../domain/entities/cohort.dart';
import '../domain/entities/cohort_assignment.dart';

/// Base exception for all cohort domain failures.
class CohortException implements Exception {
  final String message;
  final Object? cause;

  const CohortException(this.message, [this.cause]);

  @override
  String toString() =>
      'CohortException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Thrown when a requested cohort or assignment cannot be found.
class CohortNotFoundException extends CohortException {
  const CohortNotFoundException(super.message, [super.cause]);
}

/// Thrown when an operation violates cohort validation rules or invariant constraints.
class CohortValidationException extends CohortException {
  const CohortValidationException(super.message, [super.cause]);
}

/// Thrown when an unauthorized user attempts an operation.
class CohortSecurityException extends CohortException {
  const CohortSecurityException(super.message, [super.cause]);
}

/// Thrown when storage or persistence failures occur.
class CohortRepositoryException extends CohortException {
  const CohortRepositoryException(super.message, [super.cause]);
}

/// Abstract contract for cohort and assignment persistence.
abstract interface class CohortRepository {
  /// Saves or updates a cohort profile.
  Future<void> saveCohort(Cohort cohort);

  /// Retrieves a cohort by ID, or null if not found.
  Future<Cohort?> getCohortById(String cohortId);

  /// Queries cohorts with optional filters.
  Future<List<Cohort>> listCohorts({
    String? tenantId,
    String? facultyId,
    String? learnerId,
    CohortStatus? status,
  });

  /// Deletes a cohort by ID.
  Future<void> deleteCohort(String cohortId);

  /// Saves or updates a cohort assignment.
  Future<void> saveAssignment(CohortAssignment assignment);

  /// Retrieves an assignment by ID, or null if not found.
  Future<CohortAssignment?> getAssignmentById(String assignmentId);

  /// Queries assignments with optional filters.
  Future<List<CohortAssignment>> listAssignments({
    String? cohortId,
    String? learnerId,
    CohortAssignmentStatus? status,
    String? tenantId,
  });

  /// Deletes an assignment by ID.
  Future<void> deleteAssignment(String assignmentId);

  /// Exports full repository state snapshot for durable persistence.
  Future<Map<String, dynamic>> exportSnapshot();

  /// Restores repository state from a durable snapshot.
  Future<void> importSnapshot(Map<String, dynamic> snapshot);

  /// Clears all stored data (for testing or isolation reset).
  Future<void> clear();
}
