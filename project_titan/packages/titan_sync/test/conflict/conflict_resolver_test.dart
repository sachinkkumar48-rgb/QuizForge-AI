import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('ConflictResolver Strategy Tests', () {
    final now = DateTime(2026, 7, 24, 16, 0);
    final localTime = now;
    final remoteTime = now.add(const Duration(minutes: 10));

    final localItem = SyncItem(
      id: 'item_local',
      entityId: 'note_55',
      entityType: SyncEntityType.notes,
      action: SyncAction.update,
      payload: const {
        'title': 'Local Note',
        'tags': ['upsc']
      },
      timestamp: localTime,
      version: 1,
    );

    final remoteItem = SyncItem(
      id: 'item_remote',
      entityId: 'note_55',
      entityType: SyncEntityType.notes,
      action: SyncAction.update,
      payload: const {'title': 'Remote Note', 'author': 'Teacher'},
      timestamp: remoteTime,
      version: 2,
    );

    final conflict = SyncConflict(
      conflictId: 'conf_test',
      localItem: localItem,
      remoteItem: remoteItem,
      detectedAt: now,
    );

    const resolver = ConflictResolver();

    test('Last Write Wins strategy resolves to newest item', () {
      final resolved =
          resolver.resolve(conflict, strategy: ConflictStrategy.lastWriteWins);
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedItem?.id, remoteItem.id);
    });

    test('Server Wins strategy resolves to remote item', () {
      final resolved =
          resolver.resolve(conflict, strategy: ConflictStrategy.serverWins);
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedItem?.id, remoteItem.id);
    });

    test('Local Wins strategy resolves to local item', () {
      final resolved =
          resolver.resolve(conflict, strategy: ConflictStrategy.localWins);
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedItem?.id, localItem.id);
    });

    test('Manual strategy keeps conflict unresolved', () {
      final resolved =
          resolver.resolve(conflict, strategy: ConflictStrategy.manual);
      expect(resolved.isResolved, isFalse);
      expect(resolved.resolvedItem, isNull);
    });

    test('Merge strategy merges local and remote payload fields', () {
      final resolved =
          resolver.resolve(conflict, strategy: ConflictStrategy.merge);
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedItem?.payload['title'], 'Local Note');
      expect(resolved.resolvedItem?.payload['author'], 'Teacher');
      expect(resolved.resolvedItem?.version, 3);
    });
  });
}
