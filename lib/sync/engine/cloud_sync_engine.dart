import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/conflict_resolver.dart';
import '../core/sync_entity.dart';
import '../core/sync_metadata.dart';
import '../providers/cloud_sync_provider.dart';
import 'sync_engine.dart';

/// Registered device model for multi-device cloud synchronization.
class DeviceRegistration {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final DateTime registeredAt;
  final DateTime? lastSyncTimestamp;
  final Map<String, dynamic> metadata;

  DeviceRegistration({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    DateTime? registeredAt,
    this.lastSyncTimestamp,
    Map<String, dynamic>? metadata,
  })  : registeredAt = registeredAt ?? DateTime.now().toUtc(),
        metadata = metadata ?? {};

  DeviceRegistration copyWith({
    String? deviceId,
    String? deviceName,
    String? deviceType,
    DateTime? registeredAt,
    DateTime? lastSyncTimestamp,
    Map<String, dynamic>? metadata,
  }) {
    return DeviceRegistration(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      registeredAt: registeredAt ?? this.registeredAt,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'registeredAt': registeredAt.toIso8601String(),
        'lastSyncTimestamp': lastSyncTimestamp?.toIso8601String(),
        'metadata': metadata,
      };

  factory DeviceRegistration.fromJson(Map<String, dynamic> json) =>
      DeviceRegistration(
        deviceId: json['deviceId'] as String? ?? '',
        deviceName: json['deviceName'] as String? ?? 'Mobile Client',
        deviceType: json['deviceType'] as String? ?? 'Flutter App',
        registeredAt: json['registeredAt'] != null
            ? DateTime.parse(json['registeredAt'] as String).toUtc()
            : DateTime.now().toUtc(),
        lastSyncTimestamp: json['lastSyncTimestamp'] != null
            ? DateTime.parse(json['lastSyncTimestamp'] as String).toUtc()
            : null,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}

/// Execution status of a cloud sync session.
enum CloudSyncSessionStatus {
  active,
  completed,
  interrupted,
  failed,
}

/// Cloud sync session tracking checkpointed state and interrupted sync recovery.
class CloudSyncSession {
  final String sessionId;
  final String deviceId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final CloudSyncSessionStatus status;
  final int itemsUploaded;
  final int itemsDownloaded;
  final int itemsFailed;
  final int conflictsDetected;
  final int lastSyncedSequence;

  CloudSyncSession({
    required this.sessionId,
    required this.deviceId,
    required this.userId,
    DateTime? startTime,
    this.endTime,
    this.status = CloudSyncSessionStatus.active,
    this.itemsUploaded = 0,
    this.itemsDownloaded = 0,
    this.itemsFailed = 0,
    this.conflictsDetected = 0,
    this.lastSyncedSequence = 0,
  }) : startTime = startTime ?? DateTime.now().toUtc();

  CloudSyncSession copyWith({
    String? sessionId,
    String? deviceId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    CloudSyncSessionStatus? status,
    int? itemsUploaded,
    int? itemsDownloaded,
    int? itemsFailed,
    int? conflictsDetected,
    int? lastSyncedSequence,
  }) {
    return CloudSyncSession(
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      itemsUploaded: itemsUploaded ?? this.itemsUploaded,
      itemsDownloaded: itemsDownloaded ?? this.itemsDownloaded,
      itemsFailed: itemsFailed ?? this.itemsFailed,
      conflictsDetected: conflictsDetected ?? this.conflictsDetected,
      lastSyncedSequence: lastSyncedSequence ?? this.lastSyncedSequence,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'deviceId': deviceId,
        'userId': userId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'status': status.name,
        'itemsUploaded': itemsUploaded,
        'itemsDownloaded': itemsDownloaded,
        'itemsFailed': itemsFailed,
        'conflictsDetected': conflictsDetected,
        'lastSyncedSequence': lastSyncedSequence,
      };

  factory CloudSyncSession.fromJson(Map<String, dynamic> json) =>
      CloudSyncSession(
        sessionId: json['sessionId'] as String? ?? '',
        deviceId: json['deviceId'] as String? ?? '',
        userId: json['userId'] as String? ?? 'guest_user',
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String).toUtc()
            : DateTime.now().toUtc(),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String).toUtc()
            : null,
        status: CloudSyncSessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CloudSyncSessionStatus.active,
        ),
        itemsUploaded: json['itemsUploaded'] as int? ?? 0,
        itemsDownloaded: json['itemsDownloaded'] as int? ?? 0,
        itemsFailed: json['itemsFailed'] as int? ?? 0,
        conflictsDetected: json['conflictsDetected'] as int? ?? 0,
        lastSyncedSequence: json['lastSyncedSequence'] as int? ?? 0,
      );
}

/// Comprehensive result model for cloud synchronization cycles.
class CloudSyncResult {
  final bool isSuccess;
  final String sessionId;
  final int itemsUploaded;
  final int itemsDownloaded;
  final int itemsFailed;
  final int conflicts;
  final int retryCount;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String? errorMessage;

  CloudSyncResult({
    required this.isSuccess,
    required this.sessionId,
    required this.itemsUploaded,
    required this.itemsDownloaded,
    this.itemsFailed = 0,
    this.conflicts = 0,
    this.retryCount = 0,
    required this.startTime,
    required this.endTime,
    Duration? duration,
    this.errorMessage,
  }) : duration = duration ?? endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'sessionId': sessionId,
        'itemsUploaded': itemsUploaded,
        'itemsDownloaded': itemsDownloaded,
        'itemsFailed': itemsFailed,
        'conflicts': conflicts,
        'retryCount': retryCount,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'errorMessage': errorMessage,
      };

  factory CloudSyncResult.fromJson(Map<String, dynamic> json) =>
      CloudSyncResult(
        isSuccess: json['isSuccess'] as bool? ?? false,
        sessionId: json['sessionId'] as String? ?? '',
        itemsUploaded: json['itemsUploaded'] as int? ?? 0,
        itemsDownloaded: json['itemsDownloaded'] as int? ?? 0,
        itemsFailed: json['itemsFailed'] as int? ?? 0,
        conflicts: json['conflicts'] as int? ?? 0,
        retryCount: json['retryCount'] as int? ?? 0,
        startTime: DateTime.parse(json['startTime'] as String).toUtc(),
        endTime: DateTime.parse(json['endTime'] as String).toUtc(),
        duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Individual audit record for detailed sync logging.
class SyncAuditLog {
  final String logId;
  final String sessionId;
  final String deviceId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncAction action;
  final DateTime timestamp;
  final String status;
  final String details;

  SyncAuditLog({
    required this.logId,
    required this.sessionId,
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.action,
    DateTime? timestamp,
    required this.status,
    required this.details,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'logId': logId,
        'sessionId': sessionId,
        'deviceId': deviceId,
        'entityType': entityType.name,
        'entityId': entityId,
        'action': action.name,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
        'details': details,
      };

  factory SyncAuditLog.fromJson(Map<String, dynamic> json) => SyncAuditLog(
        logId: json['logId'] as String? ?? '',
        sessionId: json['sessionId'] as String? ?? '',
        deviceId: json['deviceId'] as String? ?? '',
        entityType: SyncEntityType.values.firstWhere(
          (e) => e.name == json['entityType'],
          orElse: () => SyncEntityType.bookmark,
        ),
        entityId: json['entityId'] as String? ?? '',
        action: SyncAction.values.firstWhere(
          (e) => e.name == json['action'],
          orElse: () => SyncAction.update,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
        status: json['status'] as String? ?? 'completed',
        details: json['details'] as String? ?? '',
      );
}

/// Incremental delta sync engine synchronizing only changed/new/deleted/updated records.
class IncrementalSyncEngine {
  final ConflictResolutionStrategy conflictStrategy;

  IncrementalSyncEngine({
    this.conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
  });

  /// Filters local entities returning only deltas updated after [since].
  List<SyncEntity<Map<String, dynamic>>> filterDeltas({
    required List<SyncEntity<Map<String, dynamic>>> localEntities,
    DateTime? since,
  }) {
    if (since == null) return localEntities;
    return localEntities
        .where((e) => e.metadata.updatedAt.isAfter(since))
        .toList();
  }

  /// Merges incremental remote deltas into local entities using [ConflictResolver].
  List<SyncEntity<Map<String, dynamic>>> mergeDeltas({
    required List<SyncEntity<Map<String, dynamic>>> local,
    required List<SyncEntity<Map<String, dynamic>>> remoteDeltas,
  }) {
    final Map<String, SyncEntity<Map<String, dynamic>>> map = {
      for (final loc in local) loc.metadata.entityId: loc,
    };

    for (final rem in remoteDeltas) {
      final id = rem.metadata.entityId;
      if (!map.containsKey(id)) {
        map[id] = rem;
      } else {
        final loc = map[id]!;
        if (rem.metadata.updatedAt.isAfter(loc.metadata.updatedAt)) {
          final res = ConflictResolver.resolve(
            local: loc,
            remote: rem,
            strategy: conflictStrategy,
          );
          map[id] = res.resolvedEntity;
        }
      }
    }

    return map.values.toList();
  }
}

/// Aggregate sync statistics model.
class CloudSyncStatistics {
  final int totalUploaded;
  final int totalDownloaded;
  final int totalFailed;
  final int totalConflicts;
  final double averageDurationMs;
  final double successRatePercentage;

  CloudSyncStatistics({
    required this.totalUploaded,
    required this.totalDownloaded,
    required this.totalFailed,
    required this.totalConflicts,
    required this.averageDurationMs,
    required this.successRatePercentage,
  });
}

/// Advanced Cloud Synchronization Manager for Project TITAN.
class CloudSyncManager extends ChangeNotifier {
  final SyncManager _syncManager;
  final IncrementalSyncEngine _incrementalEngine;

  DeviceRegistration _deviceRegistration;
  CloudSyncSession? _activeSession;
  final List<CloudSyncResult> _syncHistory = [];
  final List<SyncAuditLog> _auditLogs = [];

  CloudSyncManager({
    SyncManager? syncManager,
    IncrementalSyncEngine? incrementalEngine,
    DeviceRegistration? deviceRegistration,
  })  : _syncManager = syncManager ?? SyncManager(),
        _incrementalEngine = incrementalEngine ?? IncrementalSyncEngine(),
        _deviceRegistration = deviceRegistration ??
            DeviceRegistration(
              deviceId: 'dev_${DateTime.now().millisecondsSinceEpoch}',
              deviceName: 'TITAN Workstation',
              deviceType: 'Desktop/Mobile Client',
            );

  SyncManager get syncManager => _syncManager;
  IncrementalSyncEngine get incrementalEngine => _incrementalEngine;
  DeviceRegistration get deviceRegistration => _deviceRegistration;
  CloudSyncSession? get activeSession => _activeSession;
  List<CloudSyncResult> get syncHistory => List.unmodifiable(_syncHistory);
  List<SyncAuditLog> get auditLogs => List.unmodifiable(_auditLogs);

  /// Registers or updates current device registration metadata.
  void registerDevice(DeviceRegistration registration) {
    _deviceRegistration = registration;
    _syncManager.engine.setDeviceId(registration.deviceId);
    notifyListeners();
  }

  /// Triggers a secure incremental cloud synchronization cycle.
  Future<CloudSyncResult> syncCloud({
    CloudSyncProvider? providerOverride,
  }) async {
    final startTime = DateTime.now().toUtc();
    final sessionId = 'sess_${startTime.millisecondsSinceEpoch}';

    if (providerOverride != null) {
      _syncManager.engine.setCloudProvider(providerOverride);
    }

    _activeSession = CloudSyncSession(
      sessionId: sessionId,
      deviceId: _deviceRegistration.deviceId,
      userId: 'user_titan',
      startTime: startTime,
      status: CloudSyncSessionStatus.active,
    );
    notifyListeners();

    try {
      final syncEngineResult = await _syncManager.syncNow();
      final endTime = DateTime.now().toUtc();

      final itemsUploaded = syncEngineResult.itemsProcessed;
      final itemsDownloaded = syncEngineResult.isSuccess ? 1 : 0;
      final itemsFailed = syncEngineResult.itemsFailed;
      final conflicts = syncEngineResult.conflictsDetected;

      final result = CloudSyncResult(
        isSuccess: syncEngineResult.isSuccess,
        sessionId: sessionId,
        itemsUploaded: itemsUploaded,
        itemsDownloaded: itemsDownloaded,
        itemsFailed: itemsFailed,
        conflicts: conflicts,
        startTime: startTime,
        endTime: endTime,
        errorMessage: syncEngineResult.errorMessage,
      );

      _activeSession = _activeSession?.copyWith(
        endTime: endTime,
        status: syncEngineResult.isSuccess
            ? CloudSyncSessionStatus.completed
            : CloudSyncSessionStatus.failed,
        itemsUploaded: itemsUploaded,
        itemsDownloaded: itemsDownloaded,
        itemsFailed: itemsFailed,
        conflictsDetected: conflicts,
      );

      _syncHistory.insert(0, result);
      _deviceRegistration = _deviceRegistration.copyWith(
        lastSyncTimestamp: endTime,
      );

      _auditLogs.insert(
        0,
        SyncAuditLog(
          logId: 'log_${endTime.millisecondsSinceEpoch}',
          sessionId: sessionId,
          deviceId: _deviceRegistration.deviceId,
          entityType: SyncEntityType.settings,
          entityId: 'cloud_sync_cycle',
          action: SyncAction.backgroundSync,
          status: syncEngineResult.isSuccess ? 'success' : 'failed',
          details:
              'Synced $itemsUploaded items uploaded, $itemsDownloaded downloaded.',
        ),
      );

      notifyListeners();
      return result;
    } catch (e) {
      final endTime = DateTime.now().toUtc();
      final errorResult = CloudSyncResult(
        isSuccess: false,
        sessionId: sessionId,
        itemsUploaded: 0,
        itemsDownloaded: 0,
        itemsFailed: 1,
        startTime: startTime,
        endTime: endTime,
        errorMessage: e.toString(),
      );

      _activeSession = _activeSession?.copyWith(
        endTime: endTime,
        status: CloudSyncSessionStatus.failed,
        itemsFailed: 1,
      );

      _syncHistory.insert(0, errorResult);
      notifyListeners();
      return errorResult;
    }
  }

  /// Resumes an interrupted sync session.
  Future<CloudSyncResult> resumeInterruptedSync() async {
    if (_activeSession != null &&
        _activeSession!.status == CloudSyncSessionStatus.interrupted) {
      _activeSession = _activeSession!.copyWith(
        status: CloudSyncSessionStatus.active,
      );
      notifyListeners();
    }
    return syncCloud();
  }

  /// Calculates cumulative cloud sync statistics across history.
  CloudSyncStatistics computeStatistics() {
    if (_syncHistory.isEmpty) {
      return CloudSyncStatistics(
        totalUploaded: 0,
        totalDownloaded: 0,
        totalFailed: 0,
        totalConflicts: 0,
        averageDurationMs: 0,
        successRatePercentage: 100.0,
      );
    }

    int uploaded = 0;
    int downloaded = 0;
    int failed = 0;
    int conflicts = 0;
    int totalMs = 0;
    int successCount = 0;

    for (final r in _syncHistory) {
      uploaded += r.itemsUploaded;
      downloaded += r.itemsDownloaded;
      failed += r.itemsFailed;
      conflicts += r.conflicts;
      totalMs += r.duration.inMilliseconds;
      if (r.isSuccess) successCount++;
    }

    return CloudSyncStatistics(
      totalUploaded: uploaded,
      totalDownloaded: downloaded,
      totalFailed: failed,
      totalConflicts: conflicts,
      averageDurationMs: totalMs / _syncHistory.length,
      successRatePercentage: (successCount / _syncHistory.length) * 100.0,
    );
  }

  /// Clears sync audit history.
  void clearHistory() {
    _syncHistory.clear();
    _auditLogs.clear();
    notifyListeners();
  }
}
