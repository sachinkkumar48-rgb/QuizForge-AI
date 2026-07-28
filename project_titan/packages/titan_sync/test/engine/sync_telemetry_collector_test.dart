import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('SyncTelemetryCollector Tests', () {
    late SyncTelemetryCollector collector;

    setUp(() {
      collector = SyncTelemetryCollector();
    });

    test('records telemetry entries and computes aggregate summary', () {
      collector.record(SyncTelemetryRecord(
        syncId: 's1',
        duration: const Duration(milliseconds: 100),
        itemsProcessed: 5,
        itemsFailed: 0,
        conflictsCount: 1,
        pendingOpsCount: 0,
        retryCount: 0,
        isSuccess: true,
        timestamp: DateTime.now(),
      ));

      collector.record(SyncTelemetryRecord(
        syncId: 's2',
        duration: const Duration(milliseconds: 300),
        itemsProcessed: 0,
        itemsFailed: 2,
        conflictsCount: 0,
        pendingOpsCount: 2,
        retryCount: 1,
        isSuccess: false,
        errorMessage: 'Network timeout',
        timestamp: DateTime.now(),
      ));

      final summary = collector.computeSummary();
      expect(summary.totalSyncRuns, equals(2));
      expect(summary.successfulRuns, equals(1));
      expect(summary.failedRuns, equals(1));
      expect(summary.successRate, equals(50.0));
      expect(summary.averageLatencyMs, equals(200.0));
      expect(summary.totalConflictsResolved, equals(1));
      expect(summary.totalItemsSynced, equals(5));
      expect(summary.totalRetries, equals(1));
    });

    test('clears telemetry history', () {
      collector.record(SyncTelemetryRecord(
        syncId: 's1',
        duration: const Duration(milliseconds: 50),
        itemsProcessed: 1,
        itemsFailed: 0,
        conflictsCount: 0,
        pendingOpsCount: 0,
        retryCount: 0,
        isSuccess: true,
        timestamp: DateTime.now(),
      ));

      collector.clear();
      expect(collector.records.isEmpty, isTrue);
      expect(collector.computeSummary().totalSyncRuns, equals(0));
    });
  });
}
