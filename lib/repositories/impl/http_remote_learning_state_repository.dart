import 'package:garuda_learning/garuda_learning.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';

/// HTTP implementation of [RemoteLearningStateRepository] (TITAN-KO-047.0 P47 / P56 Foundation).
/// Communicates with FastAPI /api/v1/sync endpoints.
class HttpRemoteLearningStateRepository implements RemoteLearningStateRepository {
  final ApiClient _apiClient;

  HttpRemoteLearningStateRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<bool> isReachable() async {
    try {
      final response = await _apiClient.get('/health');
      return response['status'] == 'healthy';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<RemoteSyncResult> pushState(SyncEnvelope envelope) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/sync/state',
        body: envelope.toJson(),
      );

      final success = response['success'] as bool? ?? false;
      if (success) {
        final rev = (response['remoteRevision'] as num?)?.toInt() ??
            (envelope.payload['revision'] as num?)?.toInt() ??
            0;
        final syncedAtStr = response['syncedAt'] as String?;
        final syncedAt = syncedAtStr != null
            ? DateTime.parse(syncedAtStr)
            : DateTime.now().toUtc();
        return RemoteSyncResult.success(remoteRevision: rev, syncedAt: syncedAt);
      } else {
        final conflictJson = response['conflict'] as Map<String, dynamic>?;
        if (conflictJson != null) {
          final state = PersistedAuthoritativeLearnerState.fromJson(
            envelope.payload,
          ).toAuthoritativeState();
          final conflict = SyncConflict(
            conflictId: conflictJson['conflictId'] as String? ??
                'conflict_${envelope.syncId}',
            learnerId: envelope.learnerId,
            examId: envelope.examId,
            localRevision:
                (conflictJson['localRevision'] as num?)?.toInt() ?? 0,
            remoteRevision:
                (conflictJson['remoteRevision'] as num?)?.toInt() ?? 0,
            localFingerprint: envelope.checksum,
            remoteFingerprint: '',
            localState: state,
            remoteState: state,
            reason: SyncConflictReason.staleRevision,
            detectedAt: DateTime.now().toUtc(),
          );
          return RemoteSyncResult.conflict(conflict);
        }
        return RemoteSyncResult.failure(
          response['errorMessage'] as String? ?? 'Push failed',
        );
      }
    } catch (e) {
      return RemoteSyncResult.failure('Remote push failed: $e');
    }
  }

  @override
  Future<RemoteFetchResult> fetchState({
    required String learnerId,
    required String examId,
  }) async {
    try {
      final query =
          'learnerId=${Uri.encodeComponent(learnerId)}&examId=${Uri.encodeComponent(examId)}';
      final response = await _apiClient.get('/api/v1/sync/state?$query');
      final exists = response['exists'] as bool? ?? false;
      if (!exists) {
        return RemoteFetchResult.empty();
      }

      final stateJson = response['state'] as Map<String, dynamic>?;
      if (stateJson != null) {
        final state = PersistedAuthoritativeLearnerState.fromJson(
          stateJson,
        ).toAuthoritativeState();
        return RemoteFetchResult.found(state);
      }
      return RemoteFetchResult.empty();
    } catch (e) {
      return RemoteFetchResult.failure('Fetch failed: $e');
    }
  }

  @override
  Future<RemoteCheckpointResult> pushCheckpoint(
    SessionCheckpoint checkpoint, {
    required String deviceId,
  }) async {
    try {
      final payload = checkpoint.toJson()..['deviceId'] = deviceId;
      final response = await _apiClient.post(
        '/api/v1/sync/checkpoint',
        body: payload,
      );
      final success = response['success'] as bool? ?? false;
      final rev = (response['remoteRevision'] as num?)?.toInt();
      return RemoteCheckpointResult(
        success: success,
        remoteRevision: rev,
        errorMessage: response['errorMessage'] as String?,
      );
    } catch (e) {
      return RemoteCheckpointResult(success: false, errorMessage: '$e');
    }
  }

  @override
  Future<SessionCheckpoint?> fetchCheckpoint({
    required String sessionId,
    required String learnerId,
    required String examId,
  }) async {
    try {
      final query =
          'sessionId=${Uri.encodeComponent(sessionId)}&learnerId=${Uri.encodeComponent(learnerId)}&examId=${Uri.encodeComponent(examId)}';
      final response = await _apiClient.get('/api/v1/sync/checkpoint?$query');
      if (response.isEmpty) return null;
      return SessionCheckpoint.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> pushActivities(
    List<LearningActivityCompletionRecord> activities,
  ) async {
    try {
      final payload = {
        'activities': activities.map((a) => a.toJson()).toList(),
      };
      await _apiClient.post('/api/v1/sync/activities', body: payload);
    } catch (e) {
      AppLogger.error(
        'Failed to push activities to remote sync: $e',
        tag: 'HttpRemoteRepo',
      );
    }
  }

  @override
  Future<List<LearningActivityCompletionRecord>> fetchActivities({
    required String learnerId,
    required String examId,
  }) async {
    try {
      final query =
          'learnerId=${Uri.encodeComponent(learnerId)}&examId=${Uri.encodeComponent(examId)}';
      final response = await _apiClient.get('/api/v1/sync/activities?$query');
      final data = response['data'];
      if (data is List) {
        return data
            .map(
              (item) => LearningActivityCompletionRecord.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
