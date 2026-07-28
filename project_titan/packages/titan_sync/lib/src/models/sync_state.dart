import 'package:meta/meta.dart';

/// Detailed status state of the synchronization pipeline.
enum SyncPhase {
  idle,
  queuing,
  syncing,
  resolvingConflicts,
  success,
  failed,
}

/// Immutable state snapshot model representing real-time sync progress and status.
@immutable
class SyncState {
  final SyncPhase phase;
  final double progress;
  final int pendingOperationsCount;
  final int activeConflictsCount;
  final DateTime? lastSyncTime;
  final String? lastError;

  const SyncState({
    required this.phase,
    this.progress = 0.0,
    this.pendingOperationsCount = 0,
    this.activeConflictsCount = 0,
    this.lastSyncTime,
    this.lastError,
  });

  const SyncState.idle({this.lastSyncTime})
      : phase = SyncPhase.idle,
        progress = 1.0,
        pendingOperationsCount = 0,
        activeConflictsCount = 0,
        lastError = null;

  bool get isSyncing =>
      phase == SyncPhase.syncing || phase == SyncPhase.queuing;
  bool get hasConflicts => activeConflictsCount > 0;
  bool get hasFailed => phase == SyncPhase.failed;

  SyncState copyWith({
    SyncPhase? phase,
    double? progress,
    int? pendingOperationsCount,
    int? activeConflictsCount,
    DateTime? lastSyncTime,
    String? lastError,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      pendingOperationsCount:
          pendingOperationsCount ?? this.pendingOperationsCount,
      activeConflictsCount: activeConflictsCount ?? this.activeConflictsCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  String toString() =>
      'SyncState(phase: $phase, progress: ${(progress * 100).toStringAsFixed(0)}%, pending: $pendingOperationsCount, conflicts: $activeConflictsCount)';
}
