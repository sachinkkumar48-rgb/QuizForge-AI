/// Authoritative Learning-State Recovery Service (TITAN-KO-039.0 P39).
///
/// Production-grade recovery orchestrator implementing deterministic recovery,
/// integrity validation, corruption detection, and schema migration.
library;

import 'dart:convert';

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/authoritative_persistence_error.dart';
import '../domain/entities/authoritative_recovery_result.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';
import '../repository/authoritative_learning_state_repository.dart';
import '../repository/in_memory_authoritative_learning_state_repository.dart';
import 'authoritative_schema_migrator.dart';

/// Orchestrates application recovery of authoritative learner state.
class AuthoritativeLearningStateRecoveryService {
  final AuthoritativeLearningStateRepository _repository;
  final AuthoritativeSchemaMigrator _migrator;

  const AuthoritativeLearningStateRecoveryService({
    required AuthoritativeLearningStateRepository repository,
    AuthoritativeSchemaMigrator migrator =
        const DefaultAuthoritativeSchemaMigrator(),
  })  : _repository = repository,
        _migrator = migrator;

  /// Loads and deterministically recovers authoritative learner state for [learnerId] and [examId].
  Future<AuthoritativeRecoveryResult> recover({
    required String learnerId,
    required String examId,
    required DateTime requestedAt,
    bool persistInitialIfAbsent = false,
  }) async {
    final effectiveDate = requestedAt.toUtc();
    final normalizedLearnerId = learnerId.trim();
    final normalizedExamId = examId.trim().toLowerCase();

    if (normalizedLearnerId.isEmpty) {
      return AuthoritativeRecoveryResult.failed(
        learnerId: learnerId,
        examId: examId,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.missingRequiredField,
          message: 'learnerId cannot be empty for recovery',
        ),
        recoveredAt: effectiveDate,
      );
    }

    if (normalizedExamId.isEmpty) {
      return AuthoritativeRecoveryResult.failed(
        learnerId: learnerId,
        examId: examId,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.missingRequiredField,
          message: 'examId cannot be empty for recovery',
        ),
        recoveredAt: effectiveDate,
      );
    }

    try {
      final persisted = await _repository.load(
        learnerId: normalizedLearnerId,
        examId: normalizedExamId,
      );

      // CASE A: No persisted state found -> Initialize fresh state
      if (persisted == null) {
        final initial = AuthoritativeLearnerState.empty(
          learnerId: normalizedLearnerId,
          examId: normalizedExamId,
          createdAt: effectiveDate,
          revision: 1,
        );

        if (persistInitialIfAbsent) {
          final persistedInitial =
              PersistedAuthoritativeLearnerState.fromAuthoritativeState(
            initial,
            revision: 1,
          );
          await _repository.save(persistedInitial);
        }

        return AuthoritativeRecoveryResult.initialized(
          state: initial,
          recoveredAt: effectiveDate,
        );
      }

      // CASE B: Valid persisted state loaded and verified
      return AuthoritativeRecoveryResult.restored(
        persistedState: persisted,
        recoveredAt: effectiveDate,
      );
    } on AuthoritativePersistenceException catch (e) {
      // Check for schema migration (CASE E) vs unsupported schema (CASE D)
      if (e.code ==
          AuthoritativePersistenceErrorCode.unsupportedSchemaVersion) {
        final version = e.details['persistedSchemaVersion'] as int?;
        if (version != null &&
            _migrator.canMigrate(
              version,
              PersistedAuthoritativeLearnerState.currentSchemaVersion,
            )) {
          return _tryMigrateLegacy(
            learnerId: normalizedLearnerId,
            examId: normalizedExamId,
            sourceVersion: version,
            effectiveDate: effectiveDate,
          );
        }

        return AuthoritativeRecoveryResult.incompatibleSchema(
          learnerId: normalizedLearnerId,
          examId: normalizedExamId,
          error: e,
          schemaVersion: version,
          recoveredAt: effectiveDate,
        );
      }

      // CASE C: Corrupted persisted state (checksum mismatch, malformed payload, invalid enum/numeric, structural inconsistency)
      if (e.code == AuthoritativePersistenceErrorCode.corruptedChecksum ||
          e.code == AuthoritativePersistenceErrorCode.inconsistentState ||
          e.code == AuthoritativePersistenceErrorCode.invalidNumericValue ||
          e.code == AuthoritativePersistenceErrorCode.invalidEnumValue ||
          e.code == AuthoritativePersistenceErrorCode.malformedPayload) {
        return AuthoritativeRecoveryResult.corrupted(
          learnerId: normalizedLearnerId,
          examId: normalizedExamId,
          error: e,
          recoveredAt: effectiveDate,
        );
      }

      // Generic failure / IO error
      return AuthoritativeRecoveryResult.failed(
        learnerId: normalizedLearnerId,
        examId: normalizedExamId,
        error: e,
        recoveredAt: effectiveDate,
      );
    } catch (unexpected) {
      return AuthoritativeRecoveryResult.failed(
        learnerId: normalizedLearnerId,
        examId: normalizedExamId,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.ioFailure,
          message: 'Unexpected error during recovery: $unexpected',
        ),
        recoveredAt: effectiveDate,
      );
    }
  }

  /// Migrates an older supported schema state and persists the upgraded state.
  Future<AuthoritativeRecoveryResult> _tryMigrateLegacy({
    required String learnerId,
    required String examId,
    required int sourceVersion,
    required DateTime effectiveDate,
  }) async {
    try {
      String? rawJson;
      if (_repository is InMemoryAuthoritativeLearningStateRepository) {
        rawJson = (_repository as InMemoryAuthoritativeLearningStateRepository)
            .getRawRecord(learnerId, examId);
      }

      if (rawJson == null) {
        return AuthoritativeRecoveryResult.incompatibleSchema(
          learnerId: learnerId,
          examId: examId,
          error: AuthoritativePersistenceException(
            code: AuthoritativePersistenceErrorCode.unsupportedSchemaVersion,
            message: 'Cannot read raw payload for schema migration',
          ),
          schemaVersion: sourceVersion,
          recoveredAt: effectiveDate,
        );
      }

      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final migrated = _migrator.migrate(
        decoded,
        sourceVersion: sourceVersion,
        targetVersion: PersistedAuthoritativeLearnerState.currentSchemaVersion,
      );

      // Persist migrated state atomically
      await _repository.save(migrated);

      return AuthoritativeRecoveryResult.migrated(
        migratedState: migrated,
        recoveredAt: effectiveDate,
      );
    } on AuthoritativePersistenceException catch (e) {
      return AuthoritativeRecoveryResult.corrupted(
        learnerId: learnerId,
        examId: examId,
        error: e,
        recoveredAt: effectiveDate,
      );
    } catch (e) {
      return AuthoritativeRecoveryResult.failed(
        learnerId: learnerId,
        examId: examId,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.ioFailure,
          message: 'Failed to migrate legacy schema: $e',
        ),
        recoveredAt: effectiveDate,
      );
    }
  }
}
