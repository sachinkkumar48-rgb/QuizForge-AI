import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('Material 3 Sync Widgets Tests', () {
    final now = DateTime.now();

    testWidgets('SyncStatusCard renders status and triggers button callbacks',
        (tester) async {
      var syncClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusCard(
              status: SyncEngineStatus.idle,
              pendingCount: 3,
              lastSyncTime: now,
              onSyncPressed: () => syncClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Up to Date'), findsOneWidget);
      expect(find.text('3 pending'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);

      await tester.tap(find.text('Sync Now'));
      expect(syncClicked, isTrue);
    });

    testWidgets('SyncProgressIndicator shows linear progress when syncing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncProgressIndicator(
              status: SyncEngineStatus.syncing,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('PendingSyncBadge renders pending item count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PendingSyncBadge(count: 5),
          ),
        ),
      );

      expect(find.text('5 pending'), findsOneWidget);
    });

    testWidgets('LastSyncTile formats relative sync time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LastSyncTile(
              lastSyncTime: now.subtract(const Duration(minutes: 5)),
            ),
          ),
        ),
      );

      expect(find.text('Synced 5m ago'), findsOneWidget);
    });

    testWidgets(
        'ConflictResolutionDialog renders conflict details and action buttons',
        (tester) async {
      ConflictStrategy? selectedStrategy;
      final local = SyncItem(
        id: 'loc_w',
        entityId: 'ent_w',
        entityType: SyncEntityType.notes,
        action: SyncAction.update,
        payload: const {'text': 'Local Text'},
        timestamp: now,
      );
      final remote = SyncItem(
        id: 'rem_w',
        entityId: 'ent_w',
        entityType: SyncEntityType.notes,
        action: SyncAction.update,
        payload: const {'text': 'Remote Text'},
        timestamp: now,
      );
      final conflict = SyncConflict(
        conflictId: 'conf_w',
        localItem: local,
        remoteItem: remote,
        detectedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConflictResolutionDialog(
              conflict: conflict,
              onStrategySelected: (strat) => selectedStrategy = strat,
            ),
          ),
        ),
      );

      expect(find.text('Sync Conflict'), findsOneWidget);
      expect(find.text('Use Server Version'), findsOneWidget);
      expect(find.text('Use Local Version'), findsOneWidget);
      expect(find.text('Merge Changes'), findsOneWidget);

      await tester.tap(find.text('Merge Changes'));
      await tester.pumpAndSettle();

      expect(selectedStrategy, ConflictStrategy.merge);
    });
  });
}
