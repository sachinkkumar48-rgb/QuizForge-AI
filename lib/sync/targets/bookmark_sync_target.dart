import '../../repositories/bookmark_repository.dart';
import '../core/sync_entity.dart';
import '../core/sync_metadata.dart';
import '../core/sync_target.dart';

/// Sync target adapter for Bookmarks domain.
class BookmarkSyncTarget implements SyncTarget {
  final BookmarkRepository repository;
  final String deviceId;
  DateTime? _lastSyncTime;

  BookmarkSyncTarget({
    required this.repository,
    required this.deviceId,
  });

  @override
  SyncEntityType get targetType => SyncEntityType.bookmark;

  @override
  Future<List<SyncEntity<Map<String, dynamic>>>> getPendingEntities(
      {DateTime? sinceTimestamp}) async {
    final bookmarks = await repository.getBookmarks();
    final List<SyncEntity<Map<String, dynamic>>> entities = [];

    for (final b in bookmarks) {
      if (sinceTimestamp != null && b.createdAt.isBefore(sinceTimestamp)) {
        continue;
      }
      final jsonMap = b.toJson();
      final meta = SyncMetadata(
        entityId: b.bookmarkId,
        entityType: SyncEntityType.bookmark,
        version: 1,
        updatedAt: b.createdAt.toUtc(),
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
        await repository.removeBookmark(entity.metadata.entityId);
      } else {
        final qId =
            entity.payload['questionId'] as String? ?? entity.metadata.entityId;
        final cat = entity.payload['category'] as String? ?? 'General';
        final note = entity.payload['noteSnippet'] as String?;

        final isBookmarked = await repository.isBookmarked(qId);
        if (!isBookmarked) {
          await repository.toggleBookmark(qId,
              category: cat, noteSnippet: note);
        }
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
