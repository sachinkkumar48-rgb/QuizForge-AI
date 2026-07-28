import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('FieldLevelMerger Tests', () {
    late FieldLevelMerger merger;

    setUp(() {
      merger = const FieldLevelMerger();
    });

    test('merges payloads with Last Write Wins field level resolution', () {
      final t1 = DateTime(2026, 7, 26, 8, 0);
      final t2 = DateTime(2026, 7, 26, 8, 5);

      final localPayload = {'title': 'Local Note', 'category': 'Polity'};
      final remotePayload = {'title': 'Remote Note', 'author': 'Aspirant'};

      final merged = merger.mergePayloads(
        localPayload: localPayload,
        localTimestamp: t1,
        remotePayload: remotePayload,
        remoteTimestamp: t2,
      );

      expect(
          merged['title'], equals('Remote Note')); // Remote won due to t2 > t1
      expect(merged['category'],
          equals('Polity')); // Local preserved non-conflicting field
      expect(merged['author'],
          equals('Aspirant')); // Remote added non-conflicting field
    });

    test('resolves SyncConflict model into resolved SyncItem', () {
      final itemLocal = SyncItem(
        id: 's1',
        entityType: SyncEntityType.notes,
        entityId: 'n1',
        action: SyncAction.update,
        payload: const {'text': 'Local Text'},
        version: 1,
        status: SyncItemStatus.conflict,
        timestamp: DateTime(2026, 7, 26, 8, 0),
      );

      final itemRemote = SyncItem(
        id: 's1',
        entityType: SyncEntityType.notes,
        entityId: 'n1',
        action: SyncAction.update,
        payload: const {'text': 'Remote Text'},
        version: 2,
        status: SyncItemStatus.synced,
        timestamp: DateTime(2026, 7, 26, 8, 2),
      );

      final conflict = SyncConflict(
        conflictId: 'c1',
        localItem: itemLocal,
        remoteItem: itemRemote,
        detectedAt: DateTime.now(),
      );

      final resolved = merger.resolveFieldLevel(conflict);
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedItem?.payload['text'], equals('Remote Text'));
      expect(resolved.resolvedItem?.status, equals(SyncItemStatus.synced));
    });
  });
}
