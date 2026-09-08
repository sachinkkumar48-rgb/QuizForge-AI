/// Sync Outbox Repository Contract (TITAN-KO-047.0 P47).
///
/// Encapsulates the contract for durable local queuing of pending synchronization
/// records to guarantee offline-first operation without losing learner progress.
library;

import '../domain/entities/sync_conflict.dart';
import '../domain/entities/sync_envelope.dart';

/// Abstract contract for local outbox storage of synchronizable envelopes.
abstract class SyncOutboxRepository {
  /// Durable enqueue of a sync envelope. Overwrites or updates if syncId exists.
  Future<void> enqueue(SyncEnvelope envelope);

  /// Returns pending or failed envelopes awaiting sync transmission, ordered FIFO.
  Future<List<SyncEnvelope>> peekPending({String? learnerId, String? examId});

  /// Marks a specific envelope as currently in-flight.
  Future<void> markSyncing(String syncId);

  /// Marks a specific envelope as acknowledged and synchronized with remote.
  Future<void> markSynced(
    String syncId, {
    required int remoteRevision,
    required DateTime syncedAt,
  });

  /// Marks a specific envelope as encountering a conflict requiring resolution.
  Future<void> markConflict(String syncId, SyncConflict conflict);

  /// Marks a specific envelope as failed with an error message and increments retryCount.
  Future<void> markFailed(String syncId, String errorMessage);

  /// Fetches an envelope by its unique sync identifier.
  Future<SyncEnvelope?> getBySyncId(String syncId);

  /// Returns all envelopes filtered optionally by learner and exam.
  Future<List<SyncEnvelope>> getAll({String? learnerId, String? examId});

  /// Removes all acknowledged (synced) envelopes from the outbox.
  Future<int> clearCompleted();

  /// Clears the entire outbox (for testing/reset).
  Future<void> clearAll();
}
