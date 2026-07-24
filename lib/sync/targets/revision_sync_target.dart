import '../../models/revision_schedule.dart';
import '../../repositories/revision_repository.dart';
import '../core/sync_entity.dart';
import '../core/sync_metadata.dart';
import '../core/sync_target.dart';

/// Sync target adapter for Spaced Repetition Schedules domain.
class RevisionSyncTarget implements SyncTarget {
  final RevisionRepository repository;
  final String deviceId;
  DateTime? _lastSyncTime;

  RevisionSyncTarget({
    required this.repository,
    required this.deviceId,
  });

  @override
  SyncEntityType get targetType => SyncEntityType.revisionSchedule;

  @override
  Future<List<SyncEntity<Map<String, dynamic>>>> getPendingEntities(
      {DateTime? sinceTimestamp}) async {
    final scheduleMap = await repository.getAllSchedules();
    final List<SyncEntity<Map<String, dynamic>>> entities = [];

    for (final schedule in scheduleMap.values) {
      if (sinceTimestamp != null &&
          schedule.lastReviewed.isBefore(sinceTimestamp)) {
        continue;
      }
      final jsonMap = schedule.toJson();
      final meta = SyncMetadata(
        entityId: schedule.questionId,
        entityType: SyncEntityType.revisionSchedule,
        version: 1,
        updatedAt: schedule.lastReviewed.toUtc(),
        clientDeviceId: deviceId,
        checksum: SyncMetadata.computeChecksum(jsonMap),
      );
      entities.add(SyncEntity(metadata: meta, payload: jsonMap));
    }
    return entities;
  }

  @override
  Future<int> applyRemoteEntities(
      List<SyncEntity<Map<String, dynamic>>> entities) async {
    int appliedCount = 0;
    for (final entity in entities) {
      if (!entity.metadata.isDeleted) {
        final schedule = RevisionSchedule.fromJson(entity.payload);
        await repository.updateSchedule(schedule);
      }
      appliedCount++;
    }
    return appliedCount;
  }

  @override
  Future<List<SyncEntity<Map<String, dynamic>>>> exportLocalEntities() async {
    return getPendingEntities();
  }

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSyncTime;

  @override
  Future<void> updateLastSyncTime(DateTime timestamp) async {
    _lastSyncTime = timestamp;
  }
}
