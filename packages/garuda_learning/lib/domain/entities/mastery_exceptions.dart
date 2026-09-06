/// Mastery Engine Exceptions (TITAN-KO-040.0 P40).
///
/// Strongly typed domain and service exceptions for the progressive mastery engine.
library;

/// Base exception for all progressive mastery engine failures.
abstract class MasteryEngineException implements Exception {
  final String message;
  final Map<String, dynamic> details;

  const MasteryEngineException({
    required this.message,
    this.details = const {},
  });

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a [MasteryEngineConfig] violates invariant validation.
class InvalidMasteryConfigurationException extends MasteryEngineException {
  const InvalidMasteryConfigurationException({
    required super.message,
    super.details = const {},
  });
}

/// Thrown when learner state input is malformed, missing, or inconsistent.
class InvalidMasteryLearnerStateException extends MasteryEngineException {
  const InvalidMasteryLearnerStateException({
    required super.message,
    super.details = const {},
  });
}

/// Thrown when evidence items are empty, invalid, or corrupted.
class InvalidMasteryEvidenceException extends MasteryEngineException {
  const InvalidMasteryEvidenceException({
    required super.message,
    super.details = const {},
  });
}

/// Thrown when tenant context (learnerId or examId) mismatches during evaluation or aggregation.
class MasteryTenantMismatchException extends MasteryEngineException {
  final String expectedLearnerId;
  final String actualLearnerId;
  final String expectedExamId;
  final String actualExamId;

  const MasteryTenantMismatchException({
    required super.message,
    required this.expectedLearnerId,
    required this.actualLearnerId,
    required this.expectedExamId,
    required this.actualExamId,
    super.details = const {},
  });

  @override
  String toString() =>
      'MasteryTenantMismatchException: $message (expected: $expectedLearnerId:$expectedExamId, actual: $actualLearnerId:$actualExamId)';
}

/// Thrown when persisted payload has an incompatible schema version.
class UnsupportedMasterySchemaException extends MasteryEngineException {
  final int supportedVersion;
  final int foundVersion;

  const UnsupportedMasterySchemaException({
    required super.message,
    required this.supportedVersion,
    required this.foundVersion,
    super.details = const {},
  });

  @override
  String toString() =>
      'UnsupportedMasterySchemaException: $message (supported: $supportedVersion, found: $foundVersion)';
}

/// Thrown when serialized mastery payload is malformed or fails integrity checks.
class MalformedMasteryDataException extends MasteryEngineException {
  const MalformedMasteryDataException({
    required super.message,
    super.details = const {},
  });
}
