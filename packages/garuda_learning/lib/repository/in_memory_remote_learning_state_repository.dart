/// In-Memory Remote Learning State Repository (TITAN-KO-047.0 P47).
///
/// Deterministic reference implementation of RemoteLearningStateRepository
/// enforcing monotonic optimistic revision control, integrity checks, and tenant isolation.
library;

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';
import '../domain/entities/session_checkpoint.dart';
import '../domain/entities/sync_conflict.dart';
import '../domain/entities/sync_envelope.dart';
import 'learning_activity_completion_repository.dart';
import 'remote_learning_state_repository.dart';

/// In-memory reference implementation of [RemoteLearningStateRepository].
class InMemoryRemoteLearningStateRepository
    implements RemoteLearningStateRepository {
  final Map<String, AuthoritativeLearnerState> _remoteStates = {};
  final Map<String, SessionCheckpoint> _checkpoints = {};
  final Map<String, LearningActivityCompletionRecord> _activities = {};

  bool _isOnline = true;
  String? _failNextRequestMessage;

  /// Sets connectivity status for testing offline scenarios.
  void setOnline(bool online) {
    _isOnline = online;
  }

  /// Injects a one-time failure for the next request.
  void failNextRequestWith(String message) {
    _failNextRequestMessage = message;
  }

  String _stateKey(String learnerId, String examId) =>
      '${learnerId.trim()}_${examId.trim().toLowerCase()}';

  String _checkpointKey(String learnerId, String examId, String sessionId) =>
      '${learnerId.trim()}_${examId.trim().toLowerCase()}_${sessionId.trim()}';

  @override
  Future<bool> isReachable() async => _isOnline;

  @override
  Future<RemoteSyncResult> pushState(SyncEnvelope envelope) async {
    if (!_isOnline) {
      return RemoteSyncResult.failure('Remote server unreachable (offline)');
    }
    if (_failNextRequestMessage != null) {
      final msg = _failNextRequestMessage!;
      _failNextRequestMessage = null;
      return RemoteSyncResult.failure(msg);
    }

    // 1. Verify payload checksum integrity
    if (!envelope.verifyChecksum()) {
      return RemoteSyncResult.failure(
        'Payload checksum mismatch: corruption or tampering detected',
      );
    }

    // 2. Deserialize payload
    AuthoritativeLearnerState candidate;
    try {
      final persisted =
          PersistedAuthoritativeLearnerState.fromJson(envelope.payload);
      candidate = persisted.toAuthoritativeState();
    } catch (e) {
      return RemoteSyncResult.failure('Malformed remote state payload: $e');
    }

    // 3. Multi-tenant assertion
    if (candidate.learnerId != envelope.learnerId ||
        candidate.examId != envelope.examId) {
      return RemoteSyncResult.failure(
          'Tenant mismatch between envelope and payload');
    }

    final key = _stateKey(envelope.learnerId, envelope.examId);
    final existing = _remoteStates[key];

    // 4. Optimistic concurrency check
    if (existing != null) {
      if (candidate.revision <= existing.revision) {
        // Stale revision or concurrent edit conflict
        final conflict = SyncConflict(
          conflictId: 'conflict_${envelope.syncId}',
          learnerId: envelope.learnerId,
          examId: envelope.examId,
          localRevision: candidate.revision,
          remoteRevision: existing.revision,
          localFingerprint: candidate.stateFingerprint,
          remoteFingerprint: existing.stateFingerprint,
          localState: candidate,
          remoteState: existing,
          reason: SyncConflictReason.staleRevision,
          detectedAt: DateTime.now().toUtc(),
        );
        return RemoteSyncResult.conflict(conflict);
      }
    }

    // 5. Candidate update accepted
    _remoteStates[key] = candidate;
    final now = DateTime.now().toUtc();
    return RemoteSyncResult.success(
      remoteRevision: candidate.revision,
      syncedAt: now,
    );
  }

  @override
  Future<RemoteFetchResult> fetchState({
    required String learnerId,
    required String examId,
  }) async {
    if (!_isOnline) {
      return RemoteFetchResult.failure('Remote server unreachable (offline)');
    }
    if (_failNextRequestMessage != null) {
      final msg = _failNextRequestMessage!;
      _failNextRequestMessage = null;
      return RemoteFetchResult.failure(msg);
    }

    final key = _stateKey(learnerId, examId);
    final state = _remoteStates[key];
    if (state == null) {
      return RemoteFetchResult.empty();
    }
    return RemoteFetchResult.found(state);
  }

  @override
  Future<RemoteCheckpointResult> pushCheckpoint(
    SessionCheckpoint checkpoint, {
    required String deviceId,
  }) async {
    if (!_isOnline) {
      return const RemoteCheckpointResult(
        success: false,
        errorMessage: 'Remote server unreachable (offline)',
      );
    }

    final key = _checkpointKey(
      checkpoint.learnerId,
      checkpoint.examId,
      checkpoint.sessionId,
    );
    final existing = _checkpoints[key];

    // Stale checkpoint rejection: newer checkpoint protected
    if (existing != null &&
        existing.checkpointRevision >= checkpoint.checkpointRevision) {
      return RemoteCheckpointResult(
        success: true, // Idempotent ack of already advanced checkpoint
        remoteRevision: existing.checkpointRevision,
      );
    }

    _checkpoints[key] = checkpoint;
    return RemoteCheckpointResult(
      success: true,
      remoteRevision: checkpoint.checkpointRevision,
    );
  }

  @override
  Future<SessionCheckpoint?> fetchCheckpoint({
    required String sessionId,
    required String learnerId,
    required String examId,
  }) async {
    if (!_isOnline) return null;
    final key = _checkpointKey(learnerId, examId, sessionId);
    return _checkpoints[key];
  }

  @override
  Future<void> pushActivities(
    List<LearningActivityCompletionRecord> activities,
  ) async {
    if (!_isOnline) return;
    for (final act in activities) {
      // Idempotent deduplication by idempotencyKey
      _activities.putIfAbsent(act.idempotencyKey, () => act);
    }
  }

  @override
  Future<List<LearningActivityCompletionRecord>> fetchActivities({
    required String learnerId,
    required String examId,
  }) async {
    if (!_isOnline) return const [];
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();

    return _activities.values
        .where((a) => a.learnerId == cleanLearner && a.examId == cleanExam)
        .toList();
  }

  /// Directly stores remote state (for test seeding).
  void seedRemoteState(AuthoritativeLearnerState state) {
    final key = _stateKey(state.learnerId, state.examId);
    _remoteStates[key] = state;
  }

  /// Clears all remote records (for test tear down).
  void clearAll() {
    _remoteStates.clear();
    _checkpoints.clear();
    _activities.clear();
    _isOnline = true;
    _failNextRequestMessage = null;
  }
}
