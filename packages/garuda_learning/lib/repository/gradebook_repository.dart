/// Gradebook Repository Contract & Exceptions (TITAN-KO-050.0 P50).
///
/// Persistence boundary for official grades, gradebook entries, learner disputes,
/// faculty overrides, and immutable audit logs.
library;

import '../domain/entities/grade_audit_record.dart';
import '../domain/entities/grade_dispute.dart';
import '../domain/entities/grade_override.dart';
import '../domain/entities/gradebook_entry.dart';

/// Base exception for all gradebook operations.
class GradebookException implements Exception {
  final String message;
  final Object? cause;

  const GradebookException(this.message, [this.cause]);

  @override
  String toString() =>
      'GradebookException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Thrown when a grade entry, dispute, or override cannot be found.
class GradeNotFoundException extends GradebookException {
  const GradeNotFoundException(super.message, [super.cause]);
}

/// Thrown when grade parameters, scores, or dispute arguments violate validation rules.
class GradeValidationException extends GradebookException {
  const GradeValidationException(super.message, [super.cause]);
}

/// Thrown on unauthorized grade access, publication, or override attempts.
class GradeSecurityException extends GradebookException {
  const GradeSecurityException(super.message, [super.cause]);
}

/// Thrown on invalid dispute state transitions or duplicate dispute submissions.
class GradeDisputeException extends GradebookException {
  const GradeDisputeException(super.message, [super.cause]);
}

/// Thrown on underlying storage, snapshot, or repository failures.
class GradeRepositoryException extends GradebookException {
  const GradeRepositoryException(super.message, [super.cause]);
}

/// Persistence contract for gradebook entries, disputes, overrides, and audit trails.
abstract interface class GradebookRepository {
  /// Saves or updates a gradebook entry.
  Future<void> saveGradeEntry(GradebookEntry entry);

  /// Retrieves a gradebook entry by its canonical identifier.
  Future<GradebookEntry?> getGradeEntry(String entryId);

  /// Alias for [getGradeEntry].
  Future<GradebookEntry?> getEntry(String entryId);

  /// Retrieves an entry for a specific learner on a specific assessment.
  Future<GradebookEntry?> getGradeEntryByLearnerAndAssessment(
    String learnerId,
    String assessmentId,
  );

  /// Queries gradebook entries with optional filtering.
  Future<List<GradebookEntry>> listGradeEntries({
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    GradePublicationStatus? publicationStatus,
  });

  /// Alias for [listGradeEntries].
  Future<List<GradebookEntry>> listEntries({
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    GradePublicationStatus? publicationStatus,
  });

  /// Saves or updates a learner grade dispute.
  Future<void> saveDispute(GradeDispute dispute);

  /// Retrieves a dispute by its unique identifier.
  Future<GradeDispute?> getDispute(String disputeId);

  /// Queries disputes with optional filtering.
  Future<List<GradeDispute>> listDisputes({
    String? tenantId,
    String? cohortId,
    String? assessmentId,
    String? learnerId,
    GradeDisputeStatus? status,
  });

  /// Saves an immutable faculty grade override record.
  Future<void> saveOverride(GradeOverrideRecord record);

  /// Queries override records with optional filtering.
  Future<List<GradeOverrideRecord>> listOverrides({
    String? entryId,
    String? learnerId,
    String? assessmentId,
  });

  /// Saves an immutable grade audit event record.
  Future<void> saveAuditRecord(GradeAuditRecord record);

  /// Queries audit records with optional filtering.
  Future<List<GradeAuditRecord>> listAuditRecords({
    String? entryId,
    String? cohortId,
    String? learnerId,
  });

  /// Exports repository state as a serialized snapshot dictionary.
  Future<Map<String, dynamic>> exportSnapshot();

  /// Restores repository state from a serialized snapshot dictionary.
  Future<void> importSnapshot(Map<String, dynamic> snapshot);

  /// Clears all repository records.
  Future<void> clear();
}
