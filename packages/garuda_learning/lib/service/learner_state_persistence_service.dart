/// Learner State Persistence Service (TITAN-KO-039.0 P39).
///
/// Production persistence orchestration service responsible for validating,
/// serializing, persisting, loading, and recovering authoritative learner state
/// without hosting adaptive-learning or pedagogical decision logic.
library;

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/authoritative_persistence_error.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';
import '../repository/authoritative_learning_state_repository.dart';

/// Type alias aligning interface nomenclature with milestone specifications.
typedef LearnerStateRepository = AuthoritativeLearningStateRepository;

/// Production orchestration service for authoritative learner state persistence and recovery.
class LearnerStatePersistenceService {
  final AuthoritativeLearningStateRepository _repository;

  const LearnerStatePersistenceService({
    required AuthoritativeLearningStateRepository repository,
  }) : _repository = repository;

  /// Underlying repository handle.
  AuthoritativeLearningStateRepository get repository => _repository;

  /// Validates, serializes, and persists an [AuthoritativeLearnerState] with revision safety.
  ///
  /// If [expectedRevision] is provided and does not match [state.revision], throws
  /// an [AuthoritativePersistenceException] with [AuthoritativePersistenceErrorCode.staleWrite].
  Future<void> save(
    AuthoritativeLearnerState state, {
    int? expectedRevision,
  }) async {
    // 1. Invariant Validation
    final cleanLearner = state.learnerId.trim();
    if (cleanLearner.isEmpty) {
      throw ArgumentError('state.learnerId cannot be empty');
    }

    final cleanExam = state.examId.trim().toLowerCase();
    if (cleanExam.isEmpty) {
      throw ArgumentError('state.examId cannot be empty');
    }

    if (state.stateFingerprint.trim().isEmpty) {
      throw ArgumentError('state.stateFingerprint cannot be empty');
    }

    if (state.revision < 1) {
      throw ArgumentError('state.revision must be >= 1');
    }

    // 2. Concurrency / Stale-Write Protection
    if (expectedRevision != null && expectedRevision != state.revision) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.staleWrite,
        message:
            'Concurrency conflict: expected revision $expectedRevision does not match state revision ${state.revision}',
        details: {
          'expectedRevision': expectedRevision,
          'actualRevision': state.revision,
          'learnerId': cleanLearner,
          'examId': cleanExam,
        },
      );
    }

    // 3. Serialize to canonical persisted DTO with cryptographic checksum
    final persisted = PersistedAuthoritativeLearnerState.fromAuthoritativeState(
      state,
      revision: state.revision,
    );

    // 4. Atomically persist via repository
    await _repository.save(persisted);
  }

  /// Loads, deserializes, and verifies the persisted authoritative state for a learner and exam.
  ///
  /// Returns `null` if no persisted state exists for the learner context.
  /// Throws [AuthoritativePersistenceException] if the persisted state is corrupted,
  /// carries an unsupported schema version, or encounters an IO failure.
  Future<AuthoritativeLearnerState?> load({
    required String learnerId,
    required String examId,
  }) async {
    final cleanLearner = learnerId.trim();
    if (cleanLearner.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }

    final cleanExam = examId.trim().toLowerCase();
    if (cleanExam.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }

    final persisted = await _repository.load(
      learnerId: cleanLearner,
      examId: cleanExam,
    );

    if (persisted == null) {
      return null;
    }

    // Convert and verify domain state
    return persisted.toAuthoritativeState();
  }

  /// Recovers existing persisted state or creates a clean initial authoritative state.
  ///
  /// If no persisted state exists:
  /// - Returns a fresh [AuthoritativeLearnerState.empty] with `revision: 1`.
  /// - If [persistIfCreated] is `true`, atomically saves the initial state.
  ///
  /// Throws [AuthoritativePersistenceException] if existing state is present but corrupted.
  Future<AuthoritativeLearnerState> recoverOrCreate({
    required String learnerId,
    required String examId,
    DateTime? timestamp,
    bool persistIfCreated = false,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();
    final effectiveTimestamp = (timestamp ?? DateTime.now()).toUtc();

    final existing = await load(
      learnerId: cleanLearner,
      examId: cleanExam,
    );

    if (existing != null) {
      return existing;
    }

    final freshState = AuthoritativeLearnerState.empty(
      learnerId: cleanLearner,
      examId: cleanExam,
      createdAt: effectiveTimestamp,
      revision: 1,
    );

    if (persistIfCreated) {
      await save(freshState);
    }

    return freshState;
  }

  /// Deletes persisted state for a specific learner and exam context.
  Future<void> delete({
    required String learnerId,
    required String examId,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();

    await _repository.delete(
      learnerId: cleanLearner,
      examId: cleanExam,
    );
  }

  /// Checks if persisted state exists for a given learner and exam context.
  Future<bool> exists({
    required String learnerId,
    required String examId,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();

    return _repository.exists(
      learnerId: cleanLearner,
      examId: cleanExam,
    );
  }
}
