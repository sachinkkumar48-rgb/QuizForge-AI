import 'package:meta/meta.dart';

/// Single telemetry entry representing a completed sync run.
@immutable
class SyncTelemetryRecord {
  final String syncId;
  final Duration duration;
  final int itemsProcessed;
  final int itemsFailed;
  final int conflictsCount;
  final int pendingOpsCount;
  final int retryCount;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncTelemetryRecord({
    required this.syncId,
    required this.duration,
    required this.itemsProcessed,
    required this.itemsFailed,
    required this.conflictsCount,
    required this.pendingOpsCount,
    required this.retryCount,
    required this.isSuccess,
    this.errorMessage,
    required this.timestamp,
  });
}

/// Consolidated telemetry metrics summary for cloud sync.
@immutable
class SyncTelemetrySummary {
  final int totalSyncRuns;
  final int successfulRuns;
  final int failedRuns;
  final double successRate;
  final double averageLatencyMs;
  final int totalConflictsResolved;
  final int totalItemsSynced;
  final int totalRetries;

  const SyncTelemetrySummary({
    required this.totalSyncRuns,
    required this.successfulRuns,
    required this.failedRuns,
    required this.successRate,
    required this.averageLatencyMs,
    required this.totalConflictsResolved,
    required this.totalItemsSynced,
    required this.totalRetries,
  });

  @override
  String toString() =>
      'SyncTelemetrySummary(runs: $totalSyncRuns, successRate: ${successRate.toStringAsFixed(1)}%, avgLatency: ${averageLatencyMs.toStringAsFixed(1)}ms, conflicts: $totalConflictsResolved)';
}

/// Pure Dart telemetry collector recording performance, latency, retries,
/// conflicts, and failure rates for Project TITAN cloud sync.
class SyncTelemetryCollector {
  final List<SyncTelemetryRecord> _records = [];
  final int maxHistory;

  SyncTelemetryCollector({this.maxHistory = 500});

  /// Records a sync execution telemetry event.
  void record(SyncTelemetryRecord record) {
    _records.add(record);
    if (_records.length > maxHistory) {
      _records.removeAt(0);
    }
  }

  /// Unmodifiable list of recorded telemetry events.
  List<SyncTelemetryRecord> get records => List.unmodifiable(_records);

  /// Computes aggregate summary metrics.
  SyncTelemetrySummary computeSummary() {
    if (_records.isEmpty) {
      return const SyncTelemetrySummary(
        totalSyncRuns: 0,
        successfulRuns: 0,
        failedRuns: 0,
        successRate: 0.0,
        averageLatencyMs: 0.0,
        totalConflictsResolved: 0,
        totalItemsSynced: 0,
        totalRetries: 0,
      );
    }

    int total = _records.length;
    int successCount = 0;
    int totalLatencyMs = 0;
    int totalConflicts = 0;
    int totalItems = 0;
    int totalRetries = 0;

    for (final r in _records) {
      if (r.isSuccess) successCount++;
      totalLatencyMs += r.duration.inMilliseconds;
      totalConflicts += r.conflictsCount;
      totalItems += r.itemsProcessed;
      totalRetries += r.retryCount;
    }

    int failedCount = total - successCount;
    double successRate = (successCount / total) * 100.0;
    double avgLatency = totalLatencyMs / total;

    return SyncTelemetrySummary(
      totalSyncRuns: total,
      successfulRuns: successCount,
      failedRuns: failedCount,
      successRate: successRate,
      averageLatencyMs: avgLatency,
      totalConflictsResolved: totalConflicts,
      totalItemsSynced: totalItems,
      totalRetries: totalRetries,
    );
  }

  /// Clears telemetry records.
  void clear() {
    _records.clear();
  }
}
