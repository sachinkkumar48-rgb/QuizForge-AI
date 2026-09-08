/// Assessment Repository Contract & Exceptions (TITAN-KO-049.0 P49).
///
/// Persistence boundary for assessments, ongoing attempts, and evaluated results.
library;

import '../domain/entities/assessment.dart';
import '../domain/entities/assessment_attempt.dart';
import '../domain/entities/assessment_result.dart';

/// Base exception for assessment domain operations.
class AssessmentException implements Exception {
  final String message;
  final Object? cause;

  const AssessmentException(this.message, [this.cause]);

  @override
  String toString() =>
      'AssessmentException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Thrown when an assessment, attempt, or result cannot be located.
class AssessmentNotFoundException extends AssessmentException {
  const AssessmentNotFoundException(super.message, [super.cause]);
}

/// Thrown when assessment parameters or question references violate validation rules.
class AssessmentValidationException extends AssessmentException {
  const AssessmentValidationException(super.message, [super.cause]);
}

/// Thrown when an unauthorized user attempts an operation or accesses a private result.
class AssessmentSecurityException extends AssessmentException {
  const AssessmentSecurityException(super.message, [super.cause]);
}

/// Thrown when an attempt policy (max attempts, timing limit, status transition) is violated.
class AssessmentPolicyException extends AssessmentException {
  const AssessmentPolicyException(super.message, [super.cause]);
}

/// Thrown on underlying storage or repository failures.
class AssessmentRepositoryException extends AssessmentException {
  const AssessmentRepositoryException(super.message, [super.cause]);
}

/// Abstract persistence contract for assessments, attempts, and results.
abstract interface class AssessmentRepository {
  /// Saves or updates an assessment definition.
  Future<void> saveAssessment(Assessment assessment);

  /// Retrieves an assessment by ID, or null if absent.
  Future<Assessment?> getAssessmentById(String assessmentId);

  /// Queries assessments with optional filtering.
  Future<List<Assessment>> listAssessments({
    String? tenantId,
    String? creatorFacultyId,
    String? cohortId,
    AssessmentStatus? status,
  });

  /// Deletes an assessment by ID.
  Future<void> deleteAssessment(String assessmentId);

  /// Saves or updates an ongoing or submitted attempt.
  Future<void> saveAttempt(AssessmentAttempt attempt);

  /// Retrieves an attempt by ID, or null if absent.
  Future<AssessmentAttempt?> getAttemptById(String attemptId);

  /// Queries attempts with optional filtering.
  Future<List<AssessmentAttempt>> listAttempts({
    String? assessmentId,
    String? learnerId,
    AssessmentAttemptStatus? status,
  });

  /// Saves an evaluation result.
  Future<void> saveResult(AssessmentResult result);

  /// Retrieves a result by ID, or null if absent.
  Future<AssessmentResult?> getResultById(String resultId);

  /// Retrieves the result for a specific attempt ID, or null if un-evaluated.
  Future<AssessmentResult?> getResultForAttempt(String attemptId);

  /// Queries evaluation results with optional filtering.
  Future<List<AssessmentResult>> listResults({
    String? assessmentId,
    String? learnerId,
  });

  /// Exports durable snapshot for restart persistence.
  Future<Map<String, dynamic>> exportSnapshot();

  /// Restores repository state from a durable snapshot.
  Future<void> importSnapshot(Map<String, dynamic> snapshot);

  /// Clears all repository state (for testing/reset).
  Future<void> clear();
}
