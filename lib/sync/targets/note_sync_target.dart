import '../../models/user_note.dart';
import '../../repositories/user_note_repository.dart';
import '../core/sync_entity.dart';
import '../core/sync_metadata.dart';
import '../core/sync_target.dart';

/// Sync target adapter for User Notes domain.
class NoteSyncTarget implements SyncTarget {
  final UserNoteRepository repository;
  final String deviceId;
  DateTime? _lastSyncTime;

  NoteSyncTarget({
    required this.repository,
    required this.deviceId,
  });

  @override
  SyncEntityType get targetType => SyncEntityType.note;

  @override
  Future<List<SyncEntity<Map<String, dynamic>>>> getPendingEntities(
      {DateTime? sinceTimestamp}) async {
    final notes = await repository.getAllNotes();
    final List<SyncEntity<Map<String, dynamic>>> entities = [];

    for (final note in notes) {
      if (sinceTimestamp != null && note.updatedAt.isBefore(sinceTimestamp)) {
        continue;
      }
      final jsonMap = note.toJson();
      final meta = SyncMetadata(
        entityId: note.noteId,
        entityType: SyncEntityType.note,
        version: 1,
        updatedAt: note.updatedAt.toUtc(),
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
      if (entity.metadata.isDeleted) {
        await repository.deleteNote(entity.metadata.entityId);
      } else {
        final note = UserNote.fromJson(entity.payload);
        await repository.saveNote(note);
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
